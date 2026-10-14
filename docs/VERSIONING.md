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

Estado atual: **1.2.0+4**, Android versionName **1.2.0**, versionCode **4**.
Primeira entrega: 1.0.1+1. A 1.0.2 corrige a instalação SDK no workflow.
Pacote permanente: `app.meuvercel.android`. APK: `Meu Vercel-v1.2.0.apk`.

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
