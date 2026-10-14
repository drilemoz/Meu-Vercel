import 'errors.dart';

/// GitHub path/URL only; no GitHub token or arbitrary remote URL is accepted.
String githubRepositoryPath(String input) {
  var raw = input.trim();
  if (raw.startsWith('https://github.com/')) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || uri.host != 'github.com' ||
        uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment || uri.port != 443) {
      throw const ApiFailure(FailureKind.invalid, 'Use um endereço HTTPS válido do GitHub.');
    }
    raw = uri.pathSegments.where((part) => part.isNotEmpty).join('/');
  }
  if (raw.endsWith('.git')) raw = raw.substring(0, raw.length - 4);
  final parts = raw.split('/');
  final owner = RegExp(r'^[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,37}[a-zA-Z0-9])?$');
  final repo = RegExp(r'^[a-zA-Z0-9_.-]{1,100}$');
  if (parts.length != 2 || !owner.hasMatch(parts[0]) || !repo.hasMatch(parts[1]) ||
      parts[1] == '.' || parts[1] == '..' || parts[1].startsWith('.')) {
    throw const ApiFailure(FailureKind.invalid, 'Informe proprietário/repositório do GitHub.');
  }
  return '${parts[0]}/${parts[1]}';
}
