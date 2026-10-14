import 'package:flutter_test/flutter_test.dart';
import 'package:meu_vercel/core/deployment_links.dart';
import 'package:meu_vercel/core/deployment_tracking.dart';

void main() {
  test('polling foreground tem teto e para em status terminal', () {
    expect(DeploymentTracking.shouldContinue('QUEUED', 0), true);
    expect(DeploymentTracking.shouldContinue('BUILDING', 11), true);
    expect(DeploymentTracking.shouldContinue('INITIALIZING', 12), false);
    for (final value in ['READY', 'ERROR', 'CANCELED', 'CANCELLED']) {
      expect(DeploymentTracking.isTerminal(value), true, reason: value);
      expect(DeploymentTracking.shouldContinue(value, 1), false);
    }
    expect(DeploymentTracking.shouldContinue('BUILDING', 2), true);
    expect(DeploymentTracking.summary('READY'), contains('READY'));
    expect(DeploymentTracking.summary('ERROR'), contains('falhou'));
  });

  test('URL do deploy só permite HTTPS sem credenciais', () {
    expect(deploymentHttpsUrl('my-project.vercel.app').toString(),
      'https://my-project.vercel.app');
    expect(deploymentHttpsUrl('https://site.exemplo.com/path')!.scheme, 'https');
    for (final value in [
      'http://foo.vercel.app', 'ftp://foo.vercel.app',
      'https://login:pass@foo.vercel.app', 'javascript:alert(1)',
      'https://localhost', 'https://site.localhost',
      'https://foo.vercel.app:8888', 'https://foo.vercel.app/#secret',
      'https://', '  foo.vercel.app ', 'https://user@foo.vercel.app',
    ]) {
      expect(deploymentHttpsUrl(value), isNull, reason: value);
    }
    expect(deploymentHttpsUrl(null), isNull);
  });
}
