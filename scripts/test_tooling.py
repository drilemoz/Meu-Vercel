"""Testes executáveis sem Flutter para a configuração de distribuição."""
import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent

class ToolingTests(unittest.TestCase):
    def run_script(self, script, directory, extra=None):
        env = {k: v for k, v in os.environ.items() if k not in (
            'KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD', 'GITHUB_OUTPUT', 'GITHUB_STEP_SUMMARY')}
        env.update(extra or {})
        return subprocess.run(['python3', str(ROOT / 'scripts' / script)], cwd=directory,
                              env=env, capture_output=True, text=True)

    def test_missing_secrets_identifies_test_signing(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.run_script('configure_signing.py', temp)
            self.assertEqual(result.returncode, 0)
            self.assertIn('Build de teste', result.stdout)
            self.assertFalse((Path(temp) / 'android/key.properties').exists())

    def test_partial_signing_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.run_script('configure_signing.py', temp, {'KEY_ALIAS': '<TEST_PLACEHOLDER>'})
            self.assertNotEqual(result.returncode, 0)
            self.assertIn('incompleta', result.stderr)
            self.assertNotIn('<TEST_PLACEHOLDER>', result.stderr)

    def test_invalid_base64_does_not_leak_private_content(self):
        with tempfile.TemporaryDirectory() as temp:
            result = self.run_script('configure_signing.py', temp, {
                'KEYSTORE_BASE64': '<INVALID_FIXTURE>', 'KEYSTORE_PASSWORD': '<PLACEHOLDER>',
                'KEY_ALIAS': '<PLACEHOLDER>', 'KEY_PASSWORD': '<PLACEHOLDER>'})
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn('<INVALID_FIXTURE>', result.stderr)

    def test_java_properties_escape_preserves_fixture(self):
        with tempfile.TemporaryDirectory() as temp:
            (Path(temp) / 'android').mkdir()
            result = self.run_script('configure_signing.py', temp, {
                'KEYSTORE_BASE64': base64.b64encode(b'NOT_A_REAL_KEYSTORE_FIXTURE' * 10).decode(),
                'KEYSTORE_PASSWORD': '<TEST_FIXTURE=a b>', 'KEY_ALIAS': '<TEST_ALIAS>', 'KEY_PASSWORD': '<TEST_PASSWORD_á>'})
            self.assertEqual(result.returncode, 0)
            self.assertNotIn('<TEST_PASSWORD>', result.stdout)
            contents = (Path(temp) / 'android/key.properties').read_text()
            self.assertIn(r'\=a\ b', contents)
            self.assertIn(r'\u00e1', contents)
            self.assertEqual((Path(temp) / 'android/key.properties').stat().st_mode & 0o777, 0o600)

    def test_checksum_and_explicit_test_provenance(self):
        with tempfile.TemporaryDirectory() as temp:
            path = Path(temp)
            (path / 'version.json').write_text(json.dumps({'versionName': '1.0.1'}))
            (path / 'artifacts').mkdir()
            (path / 'artifacts/Meu Vercel.-v1.0.1.apk').write_bytes(b'APK_FIXTURE_NOT_INSTALLABLE')
            result = self.run_script('package_apk.py', temp, {'SIGNING_MODE': 'teste'})
            self.assertEqual(result.returncode, 0)
            checksum = (path / 'artifacts/Meu Vercel.-v1.0.1.apk.sha256').read_text()
            self.assertEqual(len(checksum.split()[0]), 64)
            self.assertIn('APK DE TESTE', (path / 'artifacts/SIGNING.txt').read_text())

if __name__ == '__main__':
    unittest.main(verbosity=2)
