# Segurança, dados e limitações

- Credencial Vercel separada de dados comuns e de qualquer futura credencial GitHub.
- Token pessoal apenas no Android Keystore/EncryptedSharedPreferences, sem valores
  reais no código ou em arquivos de compilação. Em aparelho comprometido não há
  garantia absoluta: conceda o menor escopo e revogue o token quando necessário.
- Android sem cleartext e backup automático. Backup manual exporta somente tema,
  sincronização, alertas e favoritos (IDs isolados por usuário/equipe).
- Dados API projetados por modelos antes do cache; respostas brutas não são salvas.
  Variáveis e eventos não têm cache. Comandos de build/instalação não são persistidos,
  pois poderiam conter segredos definidos pelo usuário. Metadados Git são públicos
  no sentido operacional do projeto, mas podem identificar repositórios privados:
  não compartilhe acesso ao aparelho sem considerar isso.
- Logs consultados só na memória da tela, sem exportação/diagnóstico. Token ativo é
  redigido; Secrets arbitrários escritos pelo próprio build não podem ser inferidos
  integralmente, então a tela exige consulta explícita e informa o risco.
- UI não pede nem revela valores existentes de variáveis; edição substitui por novo
  valor digitado no campo oculto, descartado após a operação/cancelamento.
- Remoções exigem digitar o nome do recurso. Produção e configurações/domínios que
  possam afetá-la exigem aviso e confirmação. Nenhuma operação de produção é automática.
- Sem serviço permanente, monitoramento contínuo ou agendamento de jobs Android.
- Cache antigo é indicado com horário local e última sincronização, sem afirmar que
  os dados ainda representam o estado da plataforma. Atualizações são explícitas ou
  habilitadas pela preferência de sincronização ao abrir/retomar.

SHA-256 do backup detecta corrupção acidental, não autentica a origem do arquivo:
um usuário pode recalcular o hash. O backup não contém credenciais e o importador
valida limite, formato, campos e tipos antes de confirmar e substituir preferências.
Compatibilidade v1 aceita preferências opcionais ausentes; versões futuras desconhecidas
são recusadas. Persistência de preferências utiliza um único registro JSON.

Não inclua backups privados de chave de assinatura na cópia Drive do projeto.
A chave persistente deve ser preservada privadamente para instalar atualizações
sem desinstalar ou perder dados. Migrações futuras devem ter testes próprios.
