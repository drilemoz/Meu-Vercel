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
`https://api.vercel.com`. Versão atual **1.3.0**, versionCode **5**, pacote permanente
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
- Importação GitHub: cria projeto Vercel usando repositório já autorizado na integração GitHub da Vercel; não inclui gerenciador de repositórios GitHub.
- Publicação de ZIP estático pelo Android em Preview para projetos sem integração Git/framework. Limits: 12 MiB ZIP, 20 MiB conteúdo, 120 arquivos, `index.html` obrigatório; não publica em Production.

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
push para `main`, tags `v*` e execução manual. Instala Flutter/SDK Android, valida
código e testes, aplica assinatura e gera `Meu Vercel-v1.2.0.apk`. A publicação ocorre
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
