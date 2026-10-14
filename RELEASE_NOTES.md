# Meu Vercel 1.0.1

Versão inicial com interface em português para consultar e administrar projetos e
deploys pela API oficial da Vercel. Token protegido no Android, conta pessoal/equipes,
favoritos, cache offline, domínios, variáveis, backup sem credenciais e temas claro,
AMOLED e sistema. Alertas opcionais quando o aplicativo sincroniza.

Pacote: `app.meuvercel.android`. versionCode: `1`.
APK esperado no CI: `Meu Vercel.-v1.0.1.apk` e checksum SHA-256.

Produção e exclusões exigem confirmação. Ações dependem do plano, escopo do token e
permissões Vercel. O GitHub tem somente contrato de integração futura.

**Situação da entrega do código:** Flutter analyze, testes Flutter e build Android
não executados por falta de SDK e proxy inacessível. A publicação deve aguardar
CI e validação em aparelho aprovados; não há APK previamente aprovado.

Somente APK com chave persistente é elegível para Releases. Builds sem Secrets são
identificados como teste nos Artifacts e não garantem atualização entre builds.
