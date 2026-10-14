# Versionamento

Estado inicial: **1.0.1+1**, Android versionName **1.0.1**, versionCode **1**.
Pacote permanente: `app.meuvercel.android`. APK: `Meu Vercel.-v1.0.1.apk`.

Cada versão entregue/publicada depois desta aumenta o versionCode para o próximo
inteiro não usado. Exemplo: correção 1.0.2+2, função compatível 1.1.0+3. SemVer:
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
7. Conferir APK `Meu Vercel.-v<versionName>.apk`, SHA-256 e certificado.
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
