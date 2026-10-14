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
