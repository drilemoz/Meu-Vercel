enum FailureKind { offline, authentication, forbidden, missing, rateLimit, invalid, server, cancelled }

class ApiFailure implements Exception {
  const ApiFailure(this.kind, this.message, {this.retryAt});
  final FailureKind kind;
  final String message;
  final DateTime? retryAt;
  @override
  String toString() => message;
}
