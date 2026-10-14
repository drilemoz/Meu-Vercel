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
