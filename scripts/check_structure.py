"""Sanity checks only. This is not a Dart analyzer or an Android compilation."""
import json
from pathlib import Path
import xml.etree.ElementTree as ET
import yaml

ROOT = Path(__file__).resolve().parent.parent
PAIRS = {'(': ')', '[': ']', '{': '}'}

def check_dart(path):
    source = path.read_text()
    def skip_comment(i):
        if source.startswith('//', i):
            end = source.find('\n', i)
            return len(source) if end < 0 else end
        if source.startswith('/*', i):
            depth = 1
            i += 2
            while i < len(source) and depth:
                if source.startswith('/*', i): depth += 1; i += 2
                elif source.startswith('*/', i): depth -= 1; i += 2
                else: i += 1
            assert not depth, f'{path}: comentário não encerrado'
            return i
        return None
    def string(i):
        quote = source[i]
        raw = i > 0 and source[i - 1] in 'rR' and (i == 1 or not source[i - 2].isalnum())
        delimiter = quote * 3 if source.startswith(quote * 3, i) else quote
        i += len(delimiter)
        while i < len(source):
            if source.startswith(delimiter, i): return i + len(delimiter)
            if not raw and source[i] == '\\': i += 2; continue
            if not raw and source.startswith('${', i): i = scan(i + 2, ['}']); continue
            i += 1
        raise AssertionError(f'{path}: string não encerrada')
    def scan(i=0, stack=None):
        stack = [] if stack is None else stack
        interpolation = bool(stack)
        while i < len(source):
            comment_end = skip_comment(i)
            if comment_end is not None: i = comment_end; continue
            char = source[i]
            if char in "'\"": i = string(i); continue
            if char in PAIRS: stack.append(PAIRS[char])
            elif char in PAIRS.values():
                line = source.count('\n', 0, i) + 1
                assert stack and char == stack[-1], f'{path}:{line}: delimitador inesperado {char}, esperado {stack[-1:]}'
                stack.pop()
                if interpolation and not stack: return i + 1
            i += 1
        assert not stack, f'{path}: delimitadores pendentes {stack}'
        return i
    scan()

files = list((ROOT / 'lib').rglob('*.dart')) + list((ROOT / 'test').rglob('*.dart'))
for file in files: check_dart(file)
for file in ROOT.rglob('*.json'): json.loads(file.read_text())
for file in (ROOT / 'android').rglob('*.xml'): ET.parse(file)
workflow = yaml.load((ROOT / '.github/workflows/build-apk.yml').read_text(), Loader=yaml.BaseLoader)
assert workflow['on']['push']['branches'] == ['main']
assert 'workflow_dispatch' in workflow['on']
assert workflow['jobs']['release']['needs'] == 'build'
build = workflow['jobs']['build']['steps']
sdk_setup = next(s for s in build if s.get('uses', '').startswith('android-actions/setup-android@'))
packages = sdk_setup.get('with', {}).get('packages', '').split()
assert packages, 'Defina os pacotes SDK explicitamente para evitar defaults descontinuados'
assert 'tools' not in packages, 'O pacote legado tools não deve ser instalado'
assert 'platform-tools' in packages, 'platform-tools necessário no runner Android'
assert any(s.get('run') == 'flutter analyze' for s in build)
assert any(s.get('run') == 'flutter test --coverage' for s in build)
assert any(s.get('uses') == 'actions/upload-artifact@v4' and s.get('with', {}).get('path') == 'artifacts/' for s in build)
assert workflow['jobs']['release']['permissions']['contents'] == 'write'
manifest = ET.parse(ROOT / 'android/app/src/main/AndroidManifest.xml').getroot()
app = manifest.find('application')
namespace = '{http://schemas.android.com/apk/res/android}'
assert app.get(namespace + 'usesCleartextTraffic') == 'false'
assert app.get(namespace + 'allowBackup') == 'false'
assert not manifest.findall('.//service')
print(f'Estrutura: {len(files)} arquivos Dart com delimitadores balanceados; JSON/XML e workflow legíveis. Isto NÃO compila nem analisa Dart.')
