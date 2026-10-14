/// Resolves a public deployment URL without allowing non-HTTPS schemes,
/// embedded credentials, fragments or untrusted local addresses.
Uri? deploymentHttpsUrl(String? raw) {
  if (raw == null || raw.trim().isEmpty || raw.trim() != raw) return null;
  final candidate = raw.contains('://') ? raw : 'https://$raw';
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty ||
      uri.userInfo.isNotEmpty || uri.hasFragment || uri.hasPort ||
      uri.host == 'localhost' || !uri.host.contains('.') ||
      uri.host.endsWith('.localhost')) return null;
  return uri;
}
