"""CI-only signing material. Never print secret contents."""
import base64
import os
from pathlib import Path

names = ['KEYSTORE_BASE64', 'KEYSTORE_PASSWORD', 'KEY_ALIAS', 'KEY_PASSWORD']
values = {name: os.environ.get(name, '') for name in names}
present = sum(bool(value) for value in values.values())
if present not in (0, len(names)):
    raise SystemExit('Assinatura incompleta: configure todos os quatro Secrets ou remova todos para build de teste.')
mode = 'estavel' if present else 'teste'
if present:
    try:
        keystore = base64.b64decode(values['KEYSTORE_BASE64'], validate=True)
        if len(keystore) < 100:
            raise ValueError()
    except ValueError:
        raise SystemExit('KEYSTORE_BASE64 inválido; conteúdo privado não foi registrado.') from None
    path = Path('android/release-keystore.jks')
    path.write_bytes(keystore)
    path.chmod(0o600)
    def escape(value):
        escaped = []
        for char in value:
            if char in '\\ =:#!':
                escaped.append('\\' + char)
            elif ord(char) < 32 or ord(char) > 126:
                units = char.encode('utf-16-be')
                escaped.extend('\\u' + units[i:i+2].hex() for i in range(0, len(units), 2))
            else:
                escaped.append(char)
        return ''.join(escaped)
    content = '\n'.join([
        'storeFile=release-keystore.jks',
        'storePassword=' + escape(values['KEYSTORE_PASSWORD']),
        'keyAlias=' + escape(values['KEY_ALIAS']),
        'keyPassword=' + escape(values['KEY_PASSWORD']),
    ]) + '\n'
    Path('android/key.properties').write_text(content, encoding='utf-8')
    Path('android/key.properties').chmod(0o600)
output = os.environ.get('GITHUB_OUTPUT')
if output:
    with open(output, 'a') as stream:
        stream.write(f'mode={mode}\n')
summary = os.environ.get('GITHUB_STEP_SUMMARY')
if summary:
    with open(summary, 'a') as stream:
        stream.write('Assinatura persistente configurada.\n' if present else
                     '**APK DE TESTE**: assinado com chave debug do runner, sem identidade estável de produção; não garante atualização entre builds.\n')
print('Assinatura persistente configurada.' if present else 'Build de teste: assinatura debug, sem identidade estável de produção.')
