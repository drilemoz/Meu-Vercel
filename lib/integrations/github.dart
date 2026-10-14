/// Optional extension point. GitHub credentials must have a separate secure store
/// and client. No dependency on another Android app or the Vercel token.
abstract interface class GitHubIntegration {
  Future<GitHubRepository?> findRepository(String owner, String name);
  Future<void> disconnect();
}
class GitHubRepository {
  const GitHubRepository(this.owner, this.name, this.url);
  final String owner;
  final String name;
  final Uri url;
}
