/// Limited foreground-only status checks after a new deployment is requested.
/// A deployment ID by itself never proves a successful publication.
class DeploymentTracking {
  static const maxChecks = 12;
  static const interval = Duration(seconds: 5);

  static bool isTerminal(String status) =>
    const {'READY', 'ERROR', 'CANCELED', 'CANCELLED'}.contains(status.toUpperCase());

  static bool shouldContinue(String status, int checks) =>
    checks < maxChecks && !isTerminal(status);

  static String summary(String status) {
    switch (status.toUpperCase()) {
      case 'READY':
        return 'A Vercel confirmou READY. Abra a URL do deploy para conferir o site. '
          'O domínio personalizado pode ter configuração própria.';
      case 'ERROR':
        return 'Deploy falhou. Consulte Eventos e erros de build para investigar.';
      case 'CANCELED':
      case 'CANCELLED':
        return 'Deploy cancelado na Vercel.';
      default:
        return 'O deploy ainda está em processamento. Aguarde ou atualize manualmente.';
    }
  }
}
