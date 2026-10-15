## Novidade 1.6.0: controle de produção

Na tela de um deploy com status READY confirmado online, o app oferece:
- **Promover Preview para Production:** solicitar um novo deploy Production usando um Preview como origem. A Vercel cria um novo build; configurações e variáveis podem ser herdadas do deploy de origem, exigindo revisão cuidadosa antes do envio. Acompanhe o resultado até READY.
- **Promover build Production:** tentar atribuir os domínios públicos a um build Production pronto (sem recompilar).
- **Rollback:** apontar produção para um deploy Production anterior elegível, com as restrições do plano da Vercel (no Hobby, só o anterior imediato).

Ações em produção exigem confirmação digitando o nome do projeto, IDs de projeto validados na API e status READY. O app não efetua rollback automático, não garante êxito só pelo HTTP 201/202 e não lê credenciais de volta da API.

API verificada: `POST /v13/deployments` (novo deploy a partir do ID), `POST /v10/projects/{projectId}/promote/{deploymentId}`, `POST /v1/projects/{projectId}/rollback/{deploymentId}`. O endpoint `/promote` **não recompila**, e é reservado na interface para builds Production. A compatibilidade do redeploy Preview para Production ainda exige teste em uma conta Vercel real.

## Ajuste 1.6.0+11: digitação e sugestões do teclado (14/10/2026)

- Autocorreção e sugestões reativadas para nomes de projetos e busca; formulários de texto comum também permitem sugestões do teclado (SwiftKey, Gboard etc.).
- Identificadores técnicos (domínios, comandos, repositórios e nomes de variáveis) mostram sugestões sem troca automática; credenciais e valores secretos não recebem sugestões nem autocorreção.
- Confirmação destrutiva mantém comparação literal do nome para proteger Production. A barra de sugestões depende também das configurações do teclado Android.
- Roadmap priorizado em `docs/ROADMAP.md`. Testes de widgets adicionados, mas execução Flutter/Android ainda pendente no CI.

## Novidades 1.4.0+6: publicar sem GitHub

Abra **Projetos → seu projeto estático** e escolha uma das entradas: **Selecionar pasta do site**, **Selecionar arquivos** (todos da raiz) ou **Selecionar ZIP**. Selecione **Preview** (padrão) ou **Produção**; a produção só prossegue depois de digitar o nome exato do projeto na confirmação adicional.

A pasta deve conter `index.html` diretamente na raiz. O seletor Android usa o Storage Access Framework e não pede acesso amplo ao armazenamento. Projetos com repositório Git ou framework não usam este modo; para React/Next/etc., gere os arquivos estáticos antes. O botão de produção solicita o deploy, mas o status **READY** e a publicação em domínio precisam ser verificados em Deploys. Confira as permissões e cotas do plano.

## Novidades 1.3.0+5

A seção **Projetos** possui **Importar GitHub**. Informe `dono/repo` de um repositório que a Vercel já tenha permissão para acessar. A API da Vercel cria o projeto e configura a integração Git. Verifique o primeiro deploy na Vercel.

Nos detalhes de um projeto **estático sem Git e sem framework**, toque em **Publicar ZIP estático**. Selecione um ZIP com `index.html`, confira o resumo e confirme. A criação inicial ocorre em **Preview**; depois acompanhe o estado em Deploys. Projetos com Next.js, Flutter, integrações Git, ZIPs enormes, arquivos sensíveis, monorepos e publicação Production estão fora do escopo desta funcionalidade inicial. O ZIP deve conter arquivos do site prontos para servir, não o código que precisa de build.

## Versão 1.2.0+4 (14/10/2026)
- Login: substituído **Copiar** por **Colar**, usando o texto da área de transferência sem registrar o token; continua oculto por padrão, com botão de visualização.
- Botões **Validar e entrar** e **Painel Vercel** agora estão lado a lado e levam, respectivamente, à validação do token e ao painel HTTPS oficial.
- Projetos: mantidas criação e exclusão; adicionada ação **Renomear projeto** com validação de nome, confirmação de impacto em Production e PATCH por ID estável na API oficial.
- Nenhuma ação de projeto é executada sem confirmação. O nome novo não deve conter `---`.
- Verificações estruturais e de versão locais. Flutter Analyze/Test e APK Android ainda dependem de execução no CI.

## Versão 1.1.0+3 (14/10/2026)
- Tela de login: acesso HTTPS ao painel da Vercel no navegador, botão copiar token e alternância entre texto oculto/visível.
- Atenção: copiar um token sensível para a área de transferência permite acesso por outros aplicativos; use apenas quando necessário.
- Testes Flutter e build Android pendentes de execução no GitHub Actions.

# Meu Vercel

Gerenciador Android em Flutter/Dart com interface pt-BR e chamadas HTTPS à API oficial
`https://api.vercel.com`. Versão atual **1.5.3**, versionCode **10**, pacote permanente
**app.meuvercel.android**. Projeto independente, sem vínculo oficial com a Vercel.

**Estado desta entrega:** código-fonte implementado, workflow e testes incluídos.
Flutter/Dart e Android SDK não estão instalados no ambiente de entrega; a rede do
proxy impediu baixá-los. Não há APK compilado ou teste Flutter aprovado nesta entrega.
Veja os resultados efetivamente executados e os bloqueios em [VALIDATION](docs/VALIDATION.md).
A versão só deve ser distribuída após o CI e a validação em aparelho passarem.

## Correção 1.0.2

Os logs da execução anterior mostram `sdkmanager tools` seguido de
`Failed to find package 'tools'`. O workflow agora configura explicitamente
`packages: platform-tools` em android-actions/setup-android@v3, evitando o default
legado `tools platform-tools`. Plataforma 36, Build Tools 36.0.0 e NDK permanecem
na etapa seguinte. Identidade Android, assinatura e funcionalidades são preservadas.
A correção precisa ser executada novamente no GitHub Actions para confirmar o build.

## Recursos no código

- Token pessoal validado em `/v2/user`, protegido por armazenamento seguro Android;
  conta pessoal, equipes paginadas, substituição, sessão expirada e logout.
- Painel com conta, projetos carregados, favoritos, deploys recentes, falhas e última
  sincronização. Quando existem mais páginas, a quantidade mostra `+`; não é um total inventado.
- Projetos com busca nos itens carregados, filtro por framework/favoritos, ordenação,
  detalhes Git, comandos/diretórios configuráveis, criação, renomeação com confirmação e exclusão com nome digitado.
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
- Publicação seguida de tela de acompanhamento: consulta temporária em primeiro plano (12 vezes, a cada 5 s, com interrupção em status terminal), botões Copiar URL e Abrir site, atualização manual; não garante que domínio customizado já esteja pronto.
- Importação GitHub: cria projeto Vercel usando repositório já autorizado na integração GitHub da Vercel; não inclui gerenciador de repositórios GitHub.
- Publicação de **pasta completa**, **arquivos individuais** ou **ZIP** direto do Android para projetos estáticos sem Git/framework; escolha entre Preview e Produção, esta com confirmação digitando o nome exato do projeto. Preserva subpastas ao escolher pasta ou ZIP. Limites: 20 MiB de conteúdo, 120 arquivos, `index.html` na raiz e ZIP de até 12 MiB. Não necessita GitHub.

## Correção 1.5.2+9 (14/10/2026)

- Corrige erro de controller destruído antes da saída da janela de confirmação de publicação, que interrompeu os testes widget do workflow #8.
- O mesmo padrão foi aplicado aos formulários de dados, sem alterar regras de segurança nem opções de publicação.
- Regressões adicionais incluídas em `test/widget_test.dart`; exige nova execução de Flutter analyze/test e build no GitHub Actions.

## Correção 1.5.1+8 (14/10/2026)

O workflow **Validar e gerar APK #7** falhou na etapa `flutter analyze` com
`unnecessary_import` em `lib/core/android_site_folder.dart:1` e
`test/android_site_folder_test.dart:2`. Os dois imports `dart:typed_data` foram
removidos: `package:flutter/services.dart` já disponibiliza `Uint8List`.
A lógica do seletor SAF, as regras de segurança e os testes seguem intactos.
O job não chegou a `flutter test` nem `flutter build apk`; a confirmação da
correção depende da próxima execução do GitHub Actions.

## Novidades 1.5.0+7

Após confirmar **Preview** ou **Produção** e receber o ID da Vercel, o aplicativo mostra automaticamente o status daquele deploy. **READY** significa que a API confirmou a conclusão do deploy, enquanto **ERROR** indica falha; a URL só é apresentada quando a API a fornece. O acompanhamento usa até 12 consultas, com 5 segundos entre elas, somente com a tela aberta e aplicativo ativo; pode ser pausado e reiniciado manualmente. Ele não continua em segundo plano nem garante que o domínio personalizado já esteja configurado. Você pode copiar o endereço HTTPS ou abrir no navegador, inclusive para conferir um Preview.

O botão final de confirmação para produção foi corrigido para **Publicar em produção**; ainda é obrigatório digitar o nome exato do projeto antes do envio. Isso não modifica ou exclui um projeto por engano.

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
O workflow não publica ZIP de Artifacts; mantenha pubspec.lock versionado quando for gerado por Flutter.

## APK e GitHub Actions

O workflow [.github/workflows/build-apk.yml](.github/workflows/build-apk.yml) roda em
push para `main`, tags `v*` e execução manual. Instala Flutter/SDK Android, valida
código e testes, aplica assinatura e gera `Meu Vercel-v1.6.0.apk`. A publicação ocorre
diretamente em **GitHub Releases → Assets**, contendo **somente o APK**, sem ZIP de
Artifacts. É um APK compilado pelo GitHub Actions, não por este arquivo ZIP de código.

Secrets necessários para assinatura estável: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`,
`KEY_ALIAS` e `KEY_PASSWORD`. Todos configurados: build assinado com chave persistente.
Ausência total: assinatura de teste, identificada como pré-lançamento. Configuração
parcial: falha explícita. Não inclua chaves ou `.env` reais no repositório nem no ZIP.

**Limitação do fluxo:** um push repetido da mesma versão pode encontrar uma Release
existente e o comando `gh release create` rejeitar a duplicação. Crie uma versão nova
após cada alteração distribuída, de acordo com `AGENTS.md`.

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
