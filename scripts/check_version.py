import json
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
meta = json.loads((root / 'version.json').read_text())
name, code, app_id = meta['versionName'], meta['versionCode'], meta['applicationId']
assert re.fullmatch(r'\d+\.\d+\.\d+', name), 'versionName deve seguir SemVer'
assert isinstance(code, int) and not isinstance(code, bool) and code > 0, 'versionCode inválido'
assert app_id == 'app.meuvercel.android', 'Não altere o applicationId'
assert f'version: {name}+{code}' in (root / 'pubspec.yaml').read_text(), 'pubspec fora de sincronia'
props = dict(line.split('=', 1) for line in (root / 'android/version.properties').read_text().splitlines() if '=' in line)
assert props['versionName'] == name and props['versionCode'] == str(code), 'Metadados Android fora de sincronia'
dart = (root / 'lib/core/version.dart').read_text()
assert f"appVersion = '{name}'" in dart and f'appVersionCode = {code};' in dart, 'Versão Dart fora de sincronia'
assert app_id in dart and app_id in (root / 'android/app/build.gradle.kts').read_text(), 'Pacote Android inconsistente'
for file in ['README.md', 'CHANGELOG.md', 'RELEASE_NOTES.md', 'docs/VERSIONING.md']:
    assert name in (root / file).read_text(), f'{file} desatualizado'
assert 'RELEASE_NOTES.md' in (root / '.github/workflows/build-apk.yml').read_text()
history = json.loads((root / 'docs/version-history.json').read_text())
assert len({item['versionCode'] for item in history}) == len(history), 'versionCode reutilizado'
assert len({item['versionName'] for item in history}) == len(history), 'versionName duplicado'
assert [item['versionCode'] for item in history] == list(range(1, code + 1)), 'Histórico deve ser sequencial'
assert history[-1] == {'versionName': name, 'versionCode': code}, 'Histórico desatualizado'
print(f'Versões sincronizadas: {name}+{code} · {app_id} · Meu Vercel.-v{name}.apk')
