# Roadmap do Meu Vercel (propostas, não implementadas)

Atualizado em 14/10/2026. Partida: 1.6.0+11. Prioridades podem mudar após testes em Android e validação dos contratos da API Vercel.

## P0 — Qualidade e segurança (próxima etapa)
- Verificar no GitHub Actions Flutter analyze, todos os testes e compilação APK release, antes de lançar novas funções.
- Testar Preview, Production, importação, pastas Android SAF, ZIP, renomeação e exclusão usando um projeto descartável.
- Melhorar erros da API (permissão do token, rate limit, conexão) sem expor credenciais ou corpos sensíveis.
- Melhorar feedback de validação dos nomes para quem usa autocorreção no teclado.

## P1 — Publicação de sites
- Implementado na 1.6.0: solicitar novo deploy Production a partir de Preview READY (rebuild a validar na API real).
- Implementado na 1.6.0: solicitar rollback Production de deploy anterior com aviso sobre limites do plano Hobby.
- Histórico comparável de deploys com status, commits, datas, URL e ações seguras.
- Exibir URLs oficiais de Preview e Production, copiar/abrir e testar certificados HTTPS.

## P2 — Diagnóstico
- Logs de build filtráveis e exportação higienizada, sem tokens nem valores secretos.
- Painel simples de saúde de projetos, domínios e status de deploys; atualização manual para poupar dados e bateria.
- Verificações condicionais de falha em intervalo moderado, observando limites do Android em segundo plano.

## P3 — Gestão avançada
- Assistente de domínios e DNS, mostrando verificações oficiais e avisos antes de alterar produção.
- Editor de variáveis de ambiente por Preview/Production/Development, com confirmação para sobrescrita.
- Seleção e associação de repositório via integração Vercel-GitHub previamente autorizada; não coletar senhas GitHub.
- Exportação de configuração **sem secrets** e backup local de preferências/favoritos.

## Fora do escopo inicial
- Hospedagem de serviços 24/7, editor completo de código e gerenciador universal de DNS.
- Alterar limites de plano da Vercel, trabalhar com projetos remotos totalmente offline ou executar deploys em Production sem confirmação.
