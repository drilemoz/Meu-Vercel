# Backup e restauração

Em Ajustes, Exportar backup usa o seletor de arquivo Android/Storage Access Framework
por file_picker. Importar backup aceita JSON de até 1 MB, valida integridade e tipos,
mostra o nome do arquivo e exige confirmação antes de substituir dados locais.
Nenhuma permissão ampla de armazenamento é necessária.

Envelope: `{ "payload": {...}, "sha256": "..." }`. Payload:
`format=meu-vercel-backup`, `version=1`, createdAt UTC e preferences. O digest é SHA-256
sobre UTF-8 de JSON canônico com chaves ordenadas recursivamente. Ordem de listas é
preservada. Apenas tema, autoSync, notifyFailure, notifySuccess e favoritos por
usuário/equipe são aceitos. Campos extras/privados são recusados mesmo com hash válido.

Sem tokens, valores de variáveis, logs, cache de projetos, e-mail, chave Android ou
credenciais GitHub. Restauração não altera a conta autenticada ou recursos remotos.
Alertas importados ainda exigem permissão Android. Favoritos de outra conta permanecem
em seu escopo e só aparecem quando aquela conta/equipe estiver ativa.

O hash detecta corrupção, não autentica autoria. Backups não são Secrets e não
precisam conter senhas. Preferências são salvas em um único registro JSON; erro de
validação/cancelamento deixa os dados existentes intactos. v1 aceita preferências
opcionais ausentes. Novas versões de formato devem oferecer migrações documentadas;
formatos futuros desconhecidos são recusados para evitar importação parcial silenciosa.
