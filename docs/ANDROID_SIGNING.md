# Assinatura permanente Android

Mantenha o applicationId `app.meuvercel.android` e o mesmo certificado em todas as
versões de produção. Uma chave debug ou diferente não permite atualizar a instalação
anterior normalmente. Desinstalar remove dados: evite isso mantendo a identidade.

## Criar e guardar a sua chave

Em máquina segura, execute fora do repositório:

```sh
keytool -genkeypair -v -keystore /caminho/seguro/meu-vercel-release.jks \
  -alias meu-vercel -keyalg RSA -keysize 3072 -validity 10000
```

Informe suas próprias senhas no prompt; não cole senhas em histórico de comandos.
Guarde uma cópia privada criptografada da chave, senhas e alias. Não envie o arquivo
ou valores privados no ZIP, Drive do projeto, Git, issues ou diagnósticos.

Para build local, crie `android/key.properties` (ignorado no Git):

```properties
storeFile=/caminho/seguro/meu-vercel-release.jks
storePassword=<SUA_SENHA_DO_KEYSTORE>
keyAlias=<SEU_ALIAS>
keyPassword=<SUA_SENHA_DA_CHAVE>
```

Gradle usa Java Properties: escape barras invertidas, espaços e caracteres especiais
se necessário. `storeFile` relativo é resolvido a partir de `android/`.

## GitHub Secrets

Configure no repositório, Settings → Secrets and variables → Actions:

- KEYSTORE_BASE64: bytes da **mesma** chave persistente em Base64 de uma linha.
- KEYSTORE_PASSWORD: senha do keystore.
- KEY_ALIAS: alias existente.
- KEY_PASSWORD: senha da chave.

Para gerar o Base64 em arquivo privado, sem imprimi-lo no terminal:

```sh
base64 -w 0 /caminho/seguro/meu-vercel-release.jks > /caminho/seguro/keystore.base64.txt
```

No macOS, use `base64 -i ... | tr -d '\n' > ...`. Importe os valores somente nos
Secrets oficiais. Os modelos `secrets/github-manager.txt`, `.env.example` e `.json`
contêm placeholders, nunca chaves geradas ou senhas inventadas. Suportam os formatos
usuais KEY=VALUE e objeto JSON nome→valor; a versão específica do módulo Secrets do
GitHub Manager não foi disponibilizada para testar seu importador.

O workflow decodifica o keystore apenas no runner, com permissões restritas, usa
key.properties temporário, verifica o APK via apksigner, registra o certificado
público e remove o material privado mesmo em falhas. Artifacts não incluem a chave.
`configure_signing.py` não confere se um keystore é criptograficamente válido:
a assinatura e o apksigner detectam chaves/senhas incompatíveis na etapa de build.

Sem os quatro Secrets, o workflow habilita explicitamente a chave debug para build
de teste. APK mantém o nome solicitado, mas Artifact termina em `-teste`,
SIGNING.txt e resumo identificam assinatura temporária. Releases são recusadas.
Secrets parciais geram erro em vez de fallback silencioso. Build local release sem
chave falha, salvo `MEU_VERCEL_TEST_SIGNING=true` explícito.

O script de Gradle baixa a distribuição oficial 8.13 e verifica SHA-256 em Linux;
nenhuma chave ou wrapper binário desnecessário está no projeto entregue.
