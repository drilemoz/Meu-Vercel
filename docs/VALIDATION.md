# Correção do workflow #8 — 1.5.2+9 (14/10/2026)

## Evidência dos logs enviados
- O `flutter analyze` do workflow #8 **passou**: `No issues found! (ran in 13.3s)`.
- `flutter test --coverage` executou 56 testes e terminou com **54 aprovados e 2 falhas** (`test/widget_test.dart`).
- Primeiro teste: `confirmação de produção exibe Publicar, não Excluir`, após cancelar o diálogo; exceção primária `A TextEditingController was used after being disposed` em `RawGestureDetector` / `_AnimatedState.didUpdateWidget`, seguida por `_dependents.isEmpty`.
- Segundo teste: `deploy acompanhado alcança READY, oferece copiar e abrir`, com `_dependents.isEmpty`; a falha pode ser consequência do estado de teste anterior, ainda não comprovado.
- A execução **não chegou** ao build Android nem à publicação da Release.

## Mudanças
- Diálogo de confirmação passou a ser um StatefulWidget que detém seu `TextEditingController` e o descarta no `State.dispose`, após a remoção do diálogo.
- O diálogo de formulário segue o mesmo padrão de propriedade e limpeza, evitando o descarte imediato após `Navigator.pop` enquanto ainda existe uma rota em saída.
- Dois testes widget adicionais verificam publicação confirmada e formulário concluído após `pumpAndSettle`; teste existente verifica ausência de exceções após cancelamento.
- VersionName **1.5.2**, versionCode **9**, metadados e notas sincronizados; sem alterar permissões, identidade Android ou material de assinatura.

## Validação desta entrega
- `python3 scripts/check_version.py`: **aprovado** (`1.5.2+9`, identidade `app.meuvercel.android`, nome do APK coerente).
- `python3 scripts/check_structure.py`: **aprovado** (35 arquivos Dart com delimitadores balanceados e arquivos JSON/XML/workflow válidos estruturalmente; não executa Dart).
- `python3 scripts/test_tooling.py`: **5/5 aprovados** (mecanismos de assinatura e empacotamento).
- `bash -n android/gradlew`: **aprovado**.
- Regressões widget incluídas em `test/widget_test.dart`, **não executadas localmente**.
- `flutter analyze`, `flutter test --coverage`, `flutter build apk --release`: **não executados localmente**, Flutter/Android SDK indisponíveis.
- Reexecutar o workflow e verificar aprovação dos testes, geração e assinatura de `Meu Vercel-v1.5.2.apk`.

---

# Correção do workflow #7 — 1.5.1+8 (14/10/2026)

## Evidência do log recebido
- O workflow instalou dependências com sucesso e chegou a `flutter analyze`.
- `flutter analyze` reportou **dois** problemas `info • unnecessary_import`, nas linhas 1 e 2 de `lib/core/android_site_folder.dart` e `test/android_site_folder_test.dart`, respectivamente.
- A etapa terminou com `2 issues found` e **exit code 1**, interrompendo o job.
- `flutter test`, `flutter build apk --release`, assinatura, APK e publicação da Release **não ocorreram nessa execução**.

## Ajuste implementado
- Remoção dos dois imports de `dart:typed_data`; ambos os arquivos continuam importando `package:flutter/services.dart`, que já fornece `Uint8List`.
- Funcionalidades de SAF, deploy, login e gerenciamento de projetos preservadas.
- Versionamento 1.5.1+8; versionCode sequencial, metadados Android/Flutter, release e novidades sincronizados.

## Verificações da correção

- `python3 scripts/check_version.py`: **aprovado** (1.5.1+8, `app.meuvercel.android`, nome de APK sincronizado).
- `python3 scripts/check_structure.py`: **aprovado** (35 arquivos Dart com delimitadores balanceados, JSON/XML/workflow legíveis; não substitui `flutter analyze`).
- `python3 scripts/test_tooling.py`: **5/5 testes Python aprovados** (assinatura/empacotamento).
- `bash -n android/gradlew`: **aprovado**.
- Verificação dirigida: duas importações redundantes removidas; `Uint8List` permanece referenciado e disponível pelo import de `flutter/services.dart`.
- Flutter/Dart SDK **não disponíveis neste ambiente**: não foi possível executar análise, testes Flutter ou build local.

## Pendente
- Reexecutar `flutter analyze`, `flutter test --coverage` e `flutter build apk --release` no GitHub Actions.
- Confirmar assinatura e publicação de `Meu Vercel-v1.5.1.apk` no GitHub Releases; testes de funcionamento no Android.

---

# Validação da versão 1.5.0+7 (14/10/2026)

## Implementação
- Acompanhamento de deploy após aceite da Vercel: até 12 GETs /v13/deployments/{id}, intervalo de 5 s enquanto a tela permanece aberta; resultado termina em READY, ERROR ou CANCELED.
- Indicador de status, atualização e pausa manuais, copiar/abrir URL HTTPS segura. URL de deploy não é confundida com verificação de domínio customizado.
- Texto de confirmação de Produção corrigido: botão agora diz 'Publicar em produção', com exigência de nome exato intacta.
- Adicionados testes Flutter para as regras de status, URL e confirmação de publicação, além de teste widget da abertura automática de status READY.

## Verificações locais concluídas
- `python3 scripts/check_version.py`: aprovado, versão **1.5.0+7**, pacote **app.meuvercel.android**, APK nomeado **Meu Vercel-v1.5.0.apk**.
- `python3 scripts/check_structure.py`: aprovado, 35 arquivos Dart com delimitadores balanceados, JSON/XML/workflow legíveis. Não avalia tipos nem compila Dart.
- `python3 scripts/test_tooling.py`: 5 testes Python aprovados (assinatura de teste/estável e checksum).
- `bash -n android/gradlew`: sintaxe do bootstrap shell aprovada.
- Os testes Dart novos foram escritos mas **não executados**; não se pode inferir sua aprovação apenas pela verificação estrutural.

## Pendente antes de distribuir
- `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release`, assinatura real e testes Android físicos (Flutter/Android SDK não instalados neste ambiente).
- Deploy de teste autenticado Preview/Produção e confirmação de URL/domínio no serviço Vercel. Nenhum token/segredo real foi utilizado.

---

# Validação 1.4.0+6 (14/10/2026)

**Novo escopo:** pasta Android via Storage Access Framework, múltiplos arquivos na raiz, ZIP anterior mantido, opção de Preview/Produção com confirmação reforçada, sem GitHub obrigatório.

## Executado

- `python3 scripts/check_version.py`: aprovado, versão 1.4.0+6 sincronizada com applicationId preservado.
- `python3 scripts/check_structure.py`: aprovado, 32 arquivos Dart com delimitadores balanceados, metadados/workflow/manifest legíveis. **Não é compilação ou análise de tipos.**
- `python3 scripts/test_tooling.py`: 5 testes Python aprovados.
- Testes Dart adicionados para SAF, caminhos, arquivos sensíveis, checksum, ambiente Preview/Production e requisições autenticadas; sua execução está pendente.
- O ZIP e checksum SHA-256 serão verificados após geração.

## Não executado / exigido antes de distribuição

- Flutter/Dart `flutter pub get`, `flutter analyze`, `flutter test` e `flutter build apk --release` não podem ser executados neste ambiente, onde os SDKs não estão instalados.
- Teste em aparelho do picker SAF (Android 6 a 16), serviços de nuvem, árvore com subpastas, arquivo sem tamanho informado e cancelamento: pendente.
- Deploy Preview e deploy Production reais para um projeto descartável autorizado na Vercel: pendentes. **Nenhum upload real foi realizado.**
- Kotlin nativo não foi compilado com o Flutter embedding/Android SDK; validação sintática isolada não prova integração Android.

## Segurança e restrições

- Seleção de pasta sem leitura global e sem permissão persistente; URI local não é enviado à Vercel.
- Checagens conservadoras de extensões sensíveis não substituem inspeção de conteúdo do site.
- Por padrão Preview; Produção requer seleção explícita e confirmação digitando nome do projeto antes de efetuar upload.
- Em caso de timeout após submissão, conferir os deploys antes de repetir para não criar duplicações.

---

# Validação da v1.3.0+5 (14/10/2026)

## Passou neste ambiente
- `python3 scripts/check_version.py`: versões 1.3.0+5 sincronizadas, `app.meuvercel.android` preservado.
- `python3 scripts/check_structure.py`: delimitadores de 30 arquivos Dart equilibrados, JSON/XML e workflow analisados estruturalmente. **Não equivale à análise de tipos ou compilação Dart**.
- `python3 scripts/test_tooling.py`: 5 testes Python aprovados (checksum, assinatura persistente/de teste e parâmetros de signing).
- Geração do ZIP com `scripts/create_source_zip.py`, verificação CRC e SHA-256 efetuadas ao empacotar.

## Não executado / pendente
- `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release`: Flutter e Android SDK indisponíveis no ambiente local; dependências novas (`archive: 4.0.9`) precisam ser resolvidas em CI.
- `test/github_deploy_test.dart`: testes de importação GitHub, validação ZIP e fluxo SHA-1 + Preview adicionados, mas **ainda não executados**.
- Testes em Android físico, autorização real Vercel-GitHub e deploy remoto em conta de teste **pendentes**. Não houve envio de arquivos nem mutações em contas de produção nesta entrega.

## Riscos observáveis
- A conexão de projeto Git depende de instalação GitHub autorizada na Vercel e permissões no repositório.
- O ZIP de site estático requer artefatos já compilados e vai somente para Preview.
- O indicador da interface mostra arquivos enviados à API, não bytes nem status READY.
- Os limites de tamanho são conservadores; confira sempre na tela os nomes antes de publicar.

## Validação desta entrega — 1.2.0+4 (14/10/2026)

**Executado localmente (código atual):**
- `python3 scripts/check_version.py`: aprovado, versão 1.2.0+4 e pacote Android sincronizados.
- `python3 scripts/check_structure.py`: aprovado, 27 arquivos Dart com delimitadores balanceados, JSON/XML/YAML e configuração do workflow para GitHub Releases sem Artifacts.
- `python3 scripts/test_tooling.py`: 5 testes Python aprovados.
- Acrescentados testes Flutter para colar/mostrar token, validação de nomes e PATCH de renomeação (testes presentes no projeto, mas execução pendente).

**Não executado:** `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build apk --release`, teste autenticado real com Vercel e teste em aparelho. Motivo: Flutter e Android SDK indisponíveis neste ambiente. A verificação de delimitadores não substitui compilação Dart.

**Critério pendente de aprovação:** GitHub Actions precisa compilar, executar os testes e publicar o APK; a ação de renomear deve ser verificada usando um projeto de teste com permissões adequadas.

---

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

# Validação real — Meu Vercel 1.0.2+2

Data da entrega: 2026-10-14 (UTC). Nenhum token real ou chave de assinatura foi usado.
Este relatório separa verificações de ferramentas, análise/compilação Flutter e
validação com a API real. **Não há evidência de build Android aprovado.**

## Falha identificada nos logs enviados

Execução da versão 1.0.1 no repositório `drilemoz/Meu-Vercel`, commit
`06d0d0233b2f9efc887a654fc331e2b27ed1c288`, em 2026-10-14. A etapa
“Configurar Android SDK” executou `sdkmanager tools`, encontrou
`Warning: Failed to find package 'tools'` e terminou com exit code 1.
Flutter, análise, testes e compilação não chegaram a executar nesse run.

O workflow real daquele commit foi conferido via conector GitHub e corresponde
ao código local. Também foi lido o [action.yml de setup-android@v3](https://github.com/android-actions/setup-android/blob/v3/action.yml):
o default de packages é `tools platform-tools`. A 1.0.2 substitui esse default
por `packages: platform-tools`, mantendo a instalação explícita dos outros SDKs.
A checagem de estrutura exige pacotes explícitos e rejeita `tools`.

## Aprovado por execução

| Verificação | Resultado real |
| --- | --- |
| `python3 scripts/test_tooling.py` | 5 testes aprovados: ausência de Secrets identifica teste; Secrets parciais falham; Base64 inválido não vaza conteúdo; escape Java Properties/permissões; checksum e identificação de APK de teste |
| `python3 scripts/check_version.py` | 1.0.2+2 sincronizado em Flutter, Android, metadados, documentação e histórico; pacote permanente conferido |
| `python3 scripts/check_structure.py` | Delimitadores balanceados em 26 arquivos Dart; JSON/XML/workflow legíveis, gatilhos/Artifacts e regras Android conferidos |
| Regressão SDK em duas cópias temporárias | Default sem packages e configuração com tools foram rejeitados pela checagem; saída em validation-sdk-regression.log |
| `bash -n android/gradlew` | Sintaxe shell aceita |

A checagem de estrutura **não é** flutter analyze, compilação, prova de contratos
HTTP nem teste de widgets. O teste de empacotamento usa bytes fictícios claramente
identificados, não gera um APK instalável. Os testes de assinatura usam fixtures,
sem material privado. O Java presente no ambiente é OpenJDK 21; o CI configura 17.

Saídas efetivamente capturadas: `docs/validation-tooling.log`,
`docs/validation-version.log`, `docs/validation-structure.log` e
`docs/validation-environment.log`. O ZIP também é verificado externamente na entrega
com teste de leitura e checksum, sem incluir o ZIP dentro de si mesmo.

## Não executado

| Verificação | Motivo |
| --- | --- |
| `flutter pub get` e geração de pubspec.lock | Flutter/Dart ausentes; download bloqueado por proxy inacessível |
| `flutter analyze` | Sem SDK Flutter; não substituído por uma declaração de sucesso |
| `flutter test --coverage` | Sem SDK; testes Flutter/Dart foram escritos, mas não executados |
| `flutter build apk --release` | Sem Flutter/Android SDK e sem chave privada configurada |
| Assinatura e `apksigner verify` em APK real | Nenhum APK foi compilado |
| Nova execução GitHub Actions / Releases da 1.0.2 | Não disparada/publicada. Os logs recebidos comprovam falha da 1.0.1 antes de Flutter; o novo workflow aguarda execução |
| Testes reais da API Vercel | Sem token real, e consulta online/SDK bloqueados pelo proxy |
| Smoke test em aparelho Android | Sem aparelho/emulador disponível |
| Importação no módulo específico do GitHub Manager | App/schema do importador não disponibilizado |
| Bootstrap PowerShell do Gradle | PowerShell/Windows não disponível |

Tentativas de rede: clone do Flutter em github.com e consulta a storage.googleapis.com
falharam com `Failed to connect to proxy port 8080 ... Could not connect to server`.
O endpoint de documentação openapi.vercel.sh também não foi alcançado na entrega inicial.
Nesta correção, arquivos GitHub puderam ser lidos via conector; o proxy shell continua
inacessível e os SDKs continuam ausentes. Não foi
contornado o proxy nem solicitada credencial privada para fabricar resultados.
A retomada do ambiente não resolveu essa falha. Google Drive usa o conector conectado,
independente da rede shell, e a confirmação de upload é registrada na resposta final.

## Testes Flutter/Dart incluídos para execução posterior

- Autenticação válida/inválida, ausência de persistência de token inválido e 401.
- Conversão de dados/commit/datas/ambientes, resposta malformada e validação de cursor.
- Listagem/paginação por equipe, agregação sem duplicação, Preview/Production.
- HTTP 400, 401, 403, 404, 429 e 500; offline; GETs concorrentes deduplicados.
- Cache isolado por escopo e sem respostas brutas, Secrets ou comandos de build.
- Preferências preservadas, logout, autoSync desativado e indicação de dados antigos.
- Backup com checksum, corrupção, campos proibidos, versão futura, defaults v1 e tamanho.
- Metadados de versionamento e documentação.
- Login oculto, navegação essencial, tema AMOLED e cancelamento de confirmação Production.

## Pendências técnicas e critério antes de distribuir

1. Disponibilizar Flutter 3.35.7, Android SDK e rede pelo proxy. Executar pub get,
   resolver/commit do pubspec.lock, analyze, tests e build. Corrigir qualquer falha
   encontrada antes de declarar o aplicativo compilável. Dependências diretas estão
   fixadas, mas as transitivas ainda não têm lock resolvido.
2. Validar versões/esquemas dos endpoints com a documentação atual e uma conta Vercel
   de teste. Dados do app são provenientes da API, mas os contratos não foram conferidos
   por chamada autenticada nesta entrega. Não há simulação no aplicativo de produção.
3. Em aparelho API 23 e 33+, conferir token seguro, expiração, permissões de alertas,
   FilePicker/SAF, retomada, tema, falha de rede, isolamento conta/equipe e migrações.
4. Testar domínios/DNS, variáveis, cancelamento e redeploy em projeto de teste. Validar
   confirmações Production sem alterar produção de uma conta real inadvertidamente.
5. Configurar sua chave persistente, executar workflow no repositório de destino,
   verificar certificado, APK e checksum; testar atualização com a mesma chave.
6. Confirmar formato aceito pelo GitHub Manager utilizado. Integração GitHub ativa
   permanece futura, com contrato separado, e não foi apresentada como implementada.

Limites intencionais da 1.0.1: busca/filtros globais sobre itens carregados; contador
com `+` enquanto houver páginas; logs limitados a 200 eventos recentes; cache somente
nos módulos documentados; sem monitoramento permanente, editor DNS, upload de fontes
ou suporte a Custom Environments. Nenhum recurso da 1.0.1 foi removido; a 1.0.2 altera somente o workflow, a
verificação estrutural, os metadados, novidades e documentação.

## Correção de análise do workflow #2 (14/10/2026)
- Corrigido o identificador da regra de lint `curly_braces_in_flow_control_structures` em `analysis_options.yaml`. A configuração mantém desativada a exigência estilística de chaves em condicionais, sem modificar a lógica do aplicativo.
- Evidência anterior: 14 ocorrências no `flutter analyze` (1 regra desconhecida e 13 ocorrências da regra de chaves).
- Pendente: executar `flutter analyze`, `flutter test` e build Android no GitHub Actions após esta correção. Ferramentas Flutter/Dart não disponíveis neste ambiente.

- Workflow atualizado para publicar somente APK em GitHub Releases; compilação em CI pendente. Sem assinatura persistente, publicação marcada como pré-lançamento de teste.
