# Validação real — Meu Vercel 1.0.1+1

Data da entrega: 2026-10-14 (UTC). Nenhum token real ou chave de assinatura foi usado.
Este relatório separa verificações de ferramentas, análise/compilação Flutter e
validação com a API real. **Não há evidência de build Android aprovado.**

## Aprovado por execução

| Verificação | Resultado real |
| --- | --- |
| `python3 scripts/test_tooling.py` | 5 testes aprovados: ausência de Secrets identifica teste; Secrets parciais falham; Base64 inválido não vaza conteúdo; escape Java Properties/permissões; checksum e identificação de APK de teste |
| `python3 scripts/check_version.py` | 1.0.1+1 sincronizado em Flutter, Android, metadados, documentação e histórico; pacote permanente conferido |
| `python3 scripts/check_structure.py` | Delimitadores balanceados em 26 arquivos Dart; JSON/XML/workflow legíveis, gatilhos/Artifacts e regras Android conferidos |
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
| Execução GitHub Actions e GitHub Releases | Nenhum repositório de destino foi informado/publicado; workflow entregue em código |
| Testes reais da API Vercel | Sem token real, e consulta online/SDK bloqueados pelo proxy |
| Smoke test em aparelho Android | Sem aparelho/emulador disponível |
| Importação no módulo específico do GitHub Manager | App/schema do importador não disponibilizado |
| Bootstrap PowerShell do Gradle | PowerShell/Windows não disponível |

Tentativas de rede: clone do Flutter em github.com e consulta a storage.googleapis.com
falharam com `Failed to connect to proxy port 8080 ... Could not connect to server`.
O endpoint de documentação openapi.vercel.sh também não foi alcançado. Não foi
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
ou suporte a Custom Environments. Nenhum recurso existente de uma versão anterior
foi removido: esta é a primeira entrega de código.
