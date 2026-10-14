# Meu Vercel — regras obrigatórias

Analise o código real antes de corrigir. Preserve recursos, dados e identidade Android
`app.meuvercel.android`. Nunca registre tokens, variáveis secretas ou corpos de erro.
Todas as URLs da aplicação devem usar HTTPS. Nunca execute alterações de produção
sem confirmação explícita no aplicativo. Confirme exclusões com o nome do recurso.

Cada entrega de uma nova versão incrementa o versionCode exatamente uma vez, nunca
reutiliza códigos publicados e segue SemVer para versionName (patch para correções,
minor para funções compatíveis, major para incompatibilidades). Durante a construção
da mesma versão ainda não publicada, correções não criam versões artificiais.

Sincronize pubspec.yaml, android/version.properties, version.json,
lib/core/version.dart, README.md, CHANGELOG.md, RELEASE_NOTES.md,
docs/VERSIONING.md e as novidades no aplicativo. O workflow deriva o nome do APK
de version.json: `Meu Vercel.-v<versionName>.apk`. Execute scripts/check_version.py.

Use a mesma chave persistente em todas as versões de produção. Chaves, key.properties,
tokens e credenciais reais ficam fora do Git e dos ZIPs. Nunca substitua a chave
estável por uma chave de teste como se fossem equivalentes.

Execute flutter analyze e flutter test antes de anunciar validação; compile o APK
quando houver SDK. Registre verificações aprovadas, não executadas, falhas e pendências
separadamente em docs/VALIDATION.md. Não declare sucesso sem saída real da execução.
Atualize documentação, entregue código e ZIP em toda nova versão.
