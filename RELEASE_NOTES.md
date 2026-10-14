## Versão 1.1.0+3 (14/10/2026)
- Tela de login: acesso HTTPS ao painel da Vercel no navegador, botão copiar token e alternância entre texto oculto/visível.
- Atenção: copiar um token sensível para a área de transferência permite acesso por outros aplicativos; use apenas quando necessário.
- Testes Flutter e build Android pendentes de execução no GitHub Actions.

# Meu Vercel 1.0.2

Corrige a etapa “Configurar Android SDK” do GitHub Actions, que tentava instalar o
pacote descontinuado `tools` e encerrava com `Failed to find package 'tools'`.
A action agora recebe `packages: platform-tools` explicitamente; plataforma,
Build Tools e NDK continuam na etapa seguinte.

Pacote preservado: `app.meuvercel.android`. versionCode: `2`.
APK esperado: `Meu Vercel.-v1.0.2.apk`, acompanhado de checksum SHA-256.
A identidade de assinatura e todos os recursos da 1.0.1 foram preservados.

Verificações locais: cinco testes dos scripts aprovados, metadados de versão e
estrutura de workflow/JSON/XML conferidos. Flutter analyze, testes Flutter e build
Android não executados: SDKs ausentes e proxy shell inacessível. A nova execução no
GitHub Actions é necessária para confirmar o resultado; não há APK aprovado.

Releases continuam exigindo assinatura persistente. Sem os quatro Secrets,
o workflow gera somente APK identificado como teste nos Artifacts.
