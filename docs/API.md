# API oficial e escopo

Base exclusiva: `https://api.vercel.com`. Authorization Bearer só é anexado a esse
cliente. Sem redirects, interceptores de log, hooks externos ou HTTP sem TLS.
Versões de endpoints são específicas por operação (a Vercel não possui uma versão
única global). Os contratos utilizados precisam ser verificados pelo CI e por uma
conta de teste, pois a documentação online estava inacessível nesta entrega.

| Módulo | Endpoint |
| --- | --- |
| Conta | GET /v2/user |
| Equipes | GET /v2/teams |
| Projetos | GET /v9/projects; GET/PATCH/DELETE /v9/projects/{id} |
| Criar projeto | POST /v11/projects |
| Deploys | GET /v6/deployments; GET /v13/deployments/{id} |
| Novo deploy | POST /v13/deployments com deploymentId de origem |
| Cancelamento | PATCH /v12/deployments/{id}/cancel |
| Eventos de build | GET /v3/deployments/{id}/events, últimos 200, sem follow |
| Domínios | GET /v9/projects/{id}/domains; POST /v10/projects/{id}/domains |
| Remover/verificar domínio | DELETE /v9/projects/{id}/domains/{domain}; POST no sufixo /verify |
| Configuração DNS | GET /v6/domains/{domain}/config |
| Variáveis | GET /v9/projects/{id}/env, decrypt=false |
| Criar variável | POST /v10/projects/{id}/env |
| Editar/remover variável | PATCH/DELETE /v9/projects/{id}/env/{envId} |

IDs e nomes de recursos são codificados como segmentos de URL; equipe é query teamId.
Listagens usam `limit` e `until` a partir de `pagination.next`. Equipes são paginadas
automaticamente; projetos/deploys/domínios são carregados em páginas sob demanda.
A resposta de variáveis é uma lista completa por projeto no contrato utilizado.
Não há total de projetos inventado: o painel mostra carregados e sinal `+` se há próxima página.

Busca e filtros globais operam sobre itens já carregados. Histórico de projeto usa
filtros remotos de status e target. Production é target=production; Preview usa o
mecanismo padrão da API sem target de produção ao redeploy. Nenhum upload arbitrário
ou deploy hook está incluído. Redeploy pode depender de retenção do deploy de origem,
integração Git, plano ou permissões. Os eventos são somente o recorte recente de
até 200, não uma promessa de histórico de logs completo.

Configurações de projeto editáveis: buildCommand, installCommand, rootDirectory e
outputDirectory. Campos vazios enviam null para restaurar defaults. Configurações
não suportadas pelo formulário devem ser feitas no painel Vercel.
Variáveis são gravadas como encrypted; valores existentes nunca são revelados.
Branches específicas de variável exigem apenas Preview. Custom Environments,
Edge Config, compra de domínios, editor DNS, promoção/rollback e integração GitHub
ativa não fazem parte desta versão.

Timeout de conexão: 12s; envio: 20s; recebimento: 25s. CancelToken cancela requisições
em mudanças de escopo/logout. GETs concorrentes iguais são deduplicados. HTTP 429
respeita Retry-After numérico, x-ratelimit-reset ou espera mínima de 1 minuto.
Não há retry automático de operações mutáveis, evitando efeitos duplicados após
timeout. Se a resposta se perder, atualize e confirme o estado antes de tentar outra vez.

401 pede novo token; 403 informa autorização; 404 informa recurso indisponível;
400/422 informam campos/permissões; 5xx informa indisponibilidade. Corpos de erro,
URLs com parâmetros, headers privados e exceções Dio não aparecem em diagnósticos.
