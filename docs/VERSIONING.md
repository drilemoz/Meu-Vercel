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

# Versionamento

Estado atual: **1.4.0+6**, Android versionName **1.4.0**, versionCode **6**.
Primeira entrega: 1.0.1+1. A 1.0.2 corrige a instalação SDK no workflow.
Pacote permanente: `app.meuvercel.android`. APK: `Meu Vercel-v1.4.0.apk`.

Cada versão entregue/publicada depois desta aumenta o versionCode para o próximo
inteiro não usado. Exemplo seguinte: correção 1.0.3+3, função compatível 1.1.0+4. SemVer:
patch para correções, minor para recursos compatíveis, major para incompatibilidades.
Alterações ainda dentro de uma versão inicial não distribuída não criam versões
artificiais. Depois da entrega, correções seguem a regra de incremento.

Checklist obrigatório de nova versão:

1. Analisar código real, preservar funções existentes, dados e assinatura Android.
2. Atualizar `version.json`, `pubspec.yaml`, `android/version.properties` e
   `lib/core/version.dart`. Gradle lê version.properties. A interface usa version.dart.
3. Atualizar README, CHANGELOG, RELEASE_NOTES, esta documentação e releaseHighlights.
4. Acrescentar o registro a `docs/version-history.json`, sem duplicar código ou versão.
5. Rodar `python3 scripts/check_version.py`, `flutter analyze`, `flutter test` e
   `flutter build apk --release` com assinatura persistente.
6. Atualizar docs/VALIDATION.md com evidências reais, revisar migrações e gerar ZIP.
7. Conferir APK `Meu Vercel-v<versionName>.apk`, SHA-256 e certificado.
8. Publicar tag `v<versionName>` somente com validações e chave estável aprovadas.

Não reutilize versionCode, não mude applicationId e não gere nova chave de produção.
O script de versão confere o histórico local; também compare com o maior código já
publicado em todas as distribuições, porque ele não consulta lojas/repositórios externos.
O backup possui versão própria (v1), independente da versão do aplicativo.

Preferências/cache usam namespaces v1. Nenhuma atualização apaga dados
automaticamente. Formato de cache inválido é ignorado, preservando seu arquivo até
substituição por sincronização válida; backups futuros desconhecidos são recusados.
Migrações futuras devem ser incrementais, testadas e manter preferências/favoritos;
o token seguro permanece separado.
