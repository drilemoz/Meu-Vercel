# Meu Vercel

Gerenciador Android em Flutter/Dart com interface pt-BR e chamadas HTTPS à API oficial
`https://api.vercel.com`. Versão inicial **1.0.1**, versionCode **1**, pacote permanente
**app.meuvercel.android**. Projeto independente, sem vínculo oficial com a Vercel.

**Estado desta entrega:** código-fonte implementado, workflow e testes incluídos.
Flutter/Dart e Android SDK não estão instalados no ambiente de entrega; a rede do
proxy impediu baixá-los. Não há APK compilado ou teste Flutter aprovado nesta entrega.
Veja os resultados efetivamente executados e os bloqueios em [VALIDATION](docs/VALIDATION.md).
A versão só deve ser distribuída após o CI e a validação em aparelho passarem.

## Recursos no código

- Token pessoal validado em `/v2/user`, protegido por armazenamento seguro Android;
  conta pessoal, equipes paginadas, substituição, sessão expirada e logout.
- Painel com conta, projetos carregados, favoritos, deploys recentes, falhas e última
  sincronização. Quando existem mais páginas, a quantidade mostra `+`; não é um total inventado.
- Projetos com busca nos itens carregados, filtro por framework/favoritos, ordenação,
  detalhes Git, comandos/diretórios configuráveis, criação e exclusão com nome digitado.
- Deploys paginados, status, horário, commit, Preview/Production, URL HTTPS, até 200
  eventos recentes, cancelamento e novo deploy por redeploy oficial. Production exige confirmação.
- Domínios: consulta paginada, verificação, dados DNS disponíveis, associação e remoção
  com confirmação. Sem compra de domínios ou editor de zona DNS.
- Variáveis: metadados, ambientes, criação, substituição com novo valor e remoção;
  nenhum valor existente é descriptografado, persistido ou incluído no backup.
- Temas claro (padrão branco), AMOLED preto real e sistema. Navegação inferior compacta.
- Cache isolado por conta/equipe para painel/projetos/deploys e histórico visitado de
  projeto; datas e indicação de dados antigos. Sem armazenamento de logs ou variáveis.
- Atualização manual, automática ao abrir/retomar quando habilitada, deduplicação de
  GETs em andamento, timeout, cancelamento e espera após HTTP 429. Sem polling permanente.
- Alertas locais opcionais para transições de status observadas ao sincronizar.
- Backup JSON v1 pelo seletor de arquivos Android, checksum SHA-256, validação de
  campos e confirmação antes da restauração; preferências e favoritos, sem tokens.
- Interface de extensão para GitHub, ainda sem autenticação ou ações GitHub.

## Executar e configurar

1. Instale Flutter **3.35.7**, Java **17** e Android SDK compatível (plataforma 36,
   Build Tools 36.0.0 e NDK 27.0.12077973). SDK Flutter mínimo 3.35 / Dart 3.9.
2. Na raiz, rode `flutter pub get`, `python3 scripts/check_version.py`,
   `flutter analyze` e `flutter test`.
3. Rode `flutter run` em Android 6.0+ (API 23). Adicione seu token apenas na tela
   de login. Não passe tokens em código, flags de compilação ou arquivos do projeto.
4. Configure a chave persistente conforme [ANDROID_SIGNING](docs/ANDROID_SIGNING.md).
   Então rode `flutter build apk --release`.
5. Para um APK local de teste, use explicitamente
   `MEU_VERCEL_TEST_SIGNING=true flutter build apk --release`.
   A chave debug **não** é a assinatura estável de produção.

O script `android/gradlew` é um bootstrap de distribuição Gradle 8.13 em código-fonte:
usa HTTPS, verifica o SHA-256 oficial e mantém a distribuição no cache local. Requer
`curl`, `unzip` e `sha256sum` em Linux/macOS (no macOS instale coreutils ou substitua
pelo wrapper Gradle padrão). Windows dispõe de `gradlew.bat`/PowerShell. Não há JAR de
wrapper binário no ZIP. O CI Ubuntu possui as ferramentas necessárias.

As dependências diretas estão fixadas; `pubspec.lock` não foi fabricado. Gere e
versione o lock após o primeiro `flutter pub get` aprovado, antes de distribuir.
O CI preserva o lock resolvido como Artifact para auditoria.

## APK e GitHub Actions

O workflow [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml) roda em
push para `main`, tags `v*` e execução manual. Configura SDKs, instala dependências,
executa análise/testes, prepara assinatura e compila. O arquivo esperado é
**Meu Vercel.-v1.0.1.apk**, acompanhado de `.sha256`, `SIGNATURE.txt` e `SIGNING.txt`.

Secrets suportados: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
Todos presentes: assinatura persistente. Todos ausentes: build de teste identificado.
Configuração parcial: falha explícita na etapa de assinatura. O Artifact de APK é
publicado **antes** do job de Releases, preservando o download se esse job falhar.
Releases exigem chave estável e tag correspondente à versão; também podem ser
solicitados manualmente com `publish_release`. Tags/Releases existentes não são
sobrescritos automaticamente. Retenção de Artifacts: 30 dias.

Modelos sem credenciais em [secrets](secrets/). Use o mapa JSON ou TXT/ENV de pares
nome/valor no GitHub Manager que aceite esses formatos. A compatibilidade com um
módulo/versão específico do GitHub Manager precisa ser confirmada naquele app;
nenhum schema proprietário foi presumido ou validado.

## Restrições e segurança

A API pode recusar ações por escopo do token, função na equipe, plano, restrições
Git e recurso removido. Essas falhas são exibidas com mensagens sanitizadas. Detalhes
em [API](docs/API.md), [AUTHENTICATION](docs/AUTHENTICATION.md) e
[SECURITY](docs/SECURITY.md). Requisições mutáveis não são repetidas automaticamente:
se uma resposta se perder, atualize e verifique o recurso antes de tentar de novo.
Domínios, variáveis e eventos exigem rede; a consulta offline cobre os dados
explicitamente armazenados. Logs remotos podem conter Secrets do projeto e ficam
somente na memória da tela de detalhes, com redação do token ativo.

Nenhum monitoramento contínuo em segundo plano é prometido. Novos deploys não
observados anteriormente não geram alerta na primeira sincronização. GitHub é
opcional e não depende de GitHub Manager instalado no aparelho.

## Estrutura e manutenção

`lib/core/`: API, modelos, repositório, estado, armazenamento, backup e alertas.
`lib/features/`: autenticação, painel, projetos, deploys, domínios, variáveis e ajustes.
`lib/integrations/`: contrato GitHub separado. `test/`: mocks e testes Flutter/Dart.
`scripts/`: validação de versão, assinatura e empacotamento.

[AGENTS.md](AGENTS.md) e [VERSIONING](docs/VERSIONING.md) definem os incrementos
obrigatórios e a preservação de dados/assinatura. Novidades, changelog e notas devem
acompanhar toda versão futura. Não use a mesma versãoCode em duas versões publicadas.
