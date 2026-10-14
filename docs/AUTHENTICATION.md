# Autenticação Vercel

Crie um Personal Access Token em https://vercel.com/account/tokens com apenas o
escopo necessário. Configure expiração apropriada. Cole no campo oculto do app:
a validação é GET https://api.vercel.com/v2/user; o token só é salvo depois de
validar a conta e consultar as equipes disponíveis.

O token usa flutter_secure_storage e EncryptedSharedPreferences no Android; a
chave é gerenciada pelos mecanismos Android. Nenhum token é salvo em preferências
comuns, cache, backup, código, CI ou logs. A transferência/backup automático Android
é desabilitado para proteger as credenciais ligadas ao aparelho.

`/v2/teams` pagina equipes; conta pessoal omite teamId, equipe envia teamId em todas
as chamadas de recursos. Favoritos/cache são isolados por ID de usuário e equipe.
Os dados da conta e das equipes vêm da API; não são dados simulados.

HTTP 401 invalida a sessão, remove o token salvo e pede novo token. Sem internet,
o cache pode ser consultado sem declarar o token validado novamente. HTTP 403
informa falta de permissão e não encerra a sessão. HTTP 429 exige espera.
Se a listagem de equipes for recusada, o login informa essa restrição: dependendo
do token, é necessário substituí-lo por um escopo que permita a consulta de conta/equipes.

Substituir token valida um novo candidato antes de trocar a sessão. Nenhum dado de
uma conta anterior é apresentado como pertencente à nova. Logout apaga token,
metadados de sessão e caches; preferências/favoritos permanecem por escopo.
Atenção: expiração remota não é inferida por um relógio local; é reconhecida pelo 401.
O projeto não requer login GitHub e não reutiliza o token Vercel para GitHub.
