import hashlib
import json
import os
from pathlib import Path

version = json.loads(Path('version.json').read_text())['versionName']
name = f'Meu Vercel.-v{version}.apk'
file = Path('artifacts') / name
if not file.is_file():
    raise SystemExit('APK compilado não encontrado na etapa de empacotamento.')
digest = hashlib.sha256(file.read_bytes()).hexdigest()
(file.parent / (name + '.sha256')).write_text(f'{digest}  {name}\n', encoding='utf-8')
mode = os.environ.get('SIGNING_MODE')
if mode not in ('estavel', 'teste'):
    raise SystemExit('Modo de assinatura ausente ou inválido.')
(file.parent / 'SIGNING.txt').write_text(
    'Assinatura persistente configurada nos Secrets. Preserve esta chave nas próximas versões.\n' if mode == 'estavel' else
    'APK DE TESTE — chave debug temporária do runner. Não é assinatura estável de produção.\n'
    'Não publique como versão de produção; builds posteriores podem não atualizar este APK.\n', encoding='utf-8')
print('APK e SHA-256 preparados; modo de assinatura:', mode)
