"""Cria entrega de fontes, excluindo credenciais, caches e binários de build."""
import hashlib
import json
from pathlib import Path
import sys
import zipfile

root = Path(__file__).resolve().parent.parent
output = Path(sys.argv[1]) if len(sys.argv) > 1 else root.parent / 'deliverables'
output.mkdir(parents=True, exist_ok=True)
version = json.loads((root / 'version.json').read_text())['versionName']
target = output / f'Meu-Vercel-v{version}-source.zip'
excluded_dirs = {'.git', '.dart_tool', '.gradle', '.idea', '.vscode', 'build', 'coverage', '__pycache__', 'artifacts', 'deliverables'}
excluded_names = {'key.properties', 'local.properties', '.env', '.flutter-plugins', '.flutter-plugins-dependencies'}
excluded_suffixes = {'.jks', '.keystore', '.p12', '.apk', '.aab', '.zip', '.pyc'}
with zipfile.ZipFile(target, 'w', compression=zipfile.ZIP_DEFLATED) as archive:
    for file in sorted(root.rglob('*')):
        relative = file.relative_to(root)
        if not file.is_file() or file.is_symlink() or excluded_dirs.intersection(relative.parts): continue
        if file.name in excluded_names or file.suffix in excluded_suffixes: continue
        if file.name.startswith('.env.') and not file.name.endswith('.example'): continue
        if file.resolve().is_relative_to(output.resolve()): continue
        archive.write(file, Path('meu_vercel') / relative)
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None, 'ZIP corrompido'
    names = archive.namelist()
    assert 'meu_vercel/.github/workflows/build-apk.yml' in names
    assert 'meu_vercel/lib/main.dart' in names
    assert 'meu_vercel/docs/VALIDATION.md' in names
    assert not any(Path(name).name in excluded_names for name in names)
checksum = hashlib.sha256(target.read_bytes()).hexdigest()
Path(str(target) + '.sha256').write_text(f'{checksum}  {target.name}\n')
print(f'ZIP verificado: {target}\n{len(names)} arquivos · {target.stat().st_size} bytes\nSHA-256: {checksum}')
