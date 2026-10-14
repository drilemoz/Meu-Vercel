## Versão 1.5.2+9 (14/10/2026)
- Corrigido erro de ciclo de vida do Flutter identificado no workflow #8: `TextEditingController was used after being disposed` em diálogo de confirmação de produção. Agora o controller pertence ao `State` da própria janela e só é descartado quando a rota termina sua animação de saída.
- Aplicado o mesmo cuidado ao formulário reutilizável para criar/editar recursos, inclusive limpeza dos campos sensíveis após fechamento; confirmações e rótulos permanecem inalterados.
- Dois testes widget adicionados para confirmar publicação e formulário após a animação de saída; teste existente reforçado com verificação de exceções. O segundo erro `_dependents.isEmpty` pode ter sido efeito em cascata do primeiro, e exige reexecução Flutter no CI.
- Preservados applicationId, assinatura, backups, API Vercel, seleção de pasta/ZIP, publicação Preview/Production e geração de somente `Meu Vercel-v1.5.2.apk` em GitHub Releases.
- CI do workflow #8: `flutter analyze` aprovado; 54 de 56 testes aprovados; 2 testes widget com falha. Correção local ainda requer `flutter test` e build Android no GitHub Actions.

## Versão 1.5.1+8 (14/10/2026)
- Corrigido o `flutter analyze` do workflow #7 (`unnecessary_import`): retirada a importação redundante de `dart:typed_data` no seletor SAF e no respectivo teste. O tipo `Uint8List` permanece disponível via `package:flutter/services.dart`.
- Nenhuma alteração no fluxo de publicação, permissões, seleção de pastas, versão do SDK, API Vercel ou identidade/assinatura Android.
- Análise, testes Dart e geração do APK ainda precisam ser executados no GitHub Actions; o job #7 terminou antes dessas duas últimas etapas.
- APK esperado: `Meu Vercel-v1.5.1.apk` em GitHub Releases, sem ZIP de Artifacts.

## Versão 1.5.0+7 (14/10/2026)
- Após publicar pasta, arquivos avulsos ou ZIP, o aplicativo abre imediatamente a tela do deploy recebido pela Vercel, sem confundir ID aceito com site pronto.
- Acompanhamento somente durante a visualização da tela: até 12 consultas GET a cada 5 segundos; encerra em READY, ERROR ou CANCELED e pausa ao sair do aplicativo. Sem serviço em segundo plano.
- Status e orientação contextual, atualização manual, botão para copiar URL HTTPS e botão para abrir o endereço no navegador; URL não segura é rejeitada.
- Corrigido o texto do botão de confirmação de produção, que mostrava 'Excluir' embora a ação fosse publicar. Continua exigindo digitar o nome exato do projeto.
- Testes Flutter adicionados para regras de acompanhamento, links e confirmação. Sem novas permissões, sem alteração de chaves, tokens, caches ou dependências.
- Validações locais estruturais aprovadas; flutter analyze/test, build Android e testes reais da Vercel ainda dependem do CI/aparelho.

## Versão 1.4.0+6 (14/10/2026)
- Publicação de site estático pelo Android sem GitHub: escolher pasta inteira (SAF com subpastas), múltiplos arquivos da raiz ou ZIP.
- Preview segue como padrão; opção Produção disponível explicitamente, exigindo digitar o nome exato do projeto antes do primeiro upload.
- Unificação da validação de caminhos, arquivos sensíveis, checksum, 20 MiB / 120 arquivos e `index.html` na raiz. ZIP mantém limite compactado de 12 MiB.
- Seletor de pastas nativo acessa somente a árvore autorizada nesta sessão, sem permissão ampla de armazenamento.
- Publicação via API oficial `/v2/files` e `/v13/deployments` com `target: production` apenas quando escolhido; retorno de ID não comprova status READY.
- Identidade Android, assinatura, GitHub, gerenciamento de projetos, backups e geração de somente APK em Releases preservados.
- Testes unitários adicionados; build Flutter/Android e deploy em conta de teste pendentes.

## Versão 1.3.0+5 (14/10/2026)
- Novo botão **Importar GitHub**: projeto Vercel com `gitRepository` (GitHub), aceitando `dono/repositório` ou URL HTTPS após validação estrita. Requer que a integração GitHub já esteja autorizada na conta Vercel. Não lê repositórios privados por fora da Vercel nem armazena token GitHub.
- Publicação pelo celular de **ZIP estático** em projeto sem Git/framework, via `/v2/files` com SHA-1 e `/v13/deployments` com referências de arquivos. Apenas Preview; Production não é solicitado. Requer `index.html` na raiz (ou numa única pasta envoltória).
- Limites defensivos: ZIP até 12 MiB, arquivos descompactados até 20 MiB, no máximo 120 arquivos, validação de caminhos, duplicações e extensões sensíveis; não grava extrações no armazenamento.
- Confirmação anterior ao envio, indicação de progresso por arquivo e redirecionamento para o histórico de deploys. O sucesso da requisição não confirma deploy READY.
- `archive: 4.0.9` adicionada; Android applicationId, backup, sessão, assinatura e workflow de APK direto preservados.
- Testes unitários com dublês adicionados; testes Flutter/Gradle dependem do ambiente GitHub Actions e de conta de teste para verificação real da API.

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

# Changelog

## 1.0.2 — versionCode 2 — 2026-10-14

- Corrigido o workflow que falhava ao instalar o pacote Android legado `tools`.
- `setup-android@v3` agora recebe explicitamente `packages: platform-tools`.
- Verificação estrutural impede regressão para o default com pacote descontinuado.
- Versão/metadados/novidades/documentação sincronizados; pacote, assinatura e
  funcionalidades anteriores preservados. APK esperado: `Meu Vercel.-v1.0.2.apk`.
- Cinco testes de ferramentas e verificações de versão/estrutura aprovados localmente.
  Build e testes Flutter continuam não executados neste ambiente; novo CI pendente.

## 1.0.1 — versionCode 1 — 2026-10-14

- Primeira implementação Flutter Android do Meu Vercel, com API oficial real.
- Autenticação segura, contas/equipes, painel, favoritos e cache por escopo.
- Projetos, deploys, domínios e variáveis com confirmações e proteção de produção.
- Tema branco, AMOLED/sistema, backup JSON com integridade e alertas ao sincronizar.
- Workflow de APK, assinatura persistente opcional e identificação de builds de teste.
- Testes automatizados com mocks e documentação de configuração/versionamento.

Validação Flutter, build Android e teste autenticado Vercel pendentes nesta entrega
por ausência de SDK e falha no proxy. Não há APK aprovado. Resultados em docs/VALIDATION.md.
