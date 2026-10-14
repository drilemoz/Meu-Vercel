import 'package:dio/dio.dart';
import 'errors.dart';
import 'models.dart';

/// Only this client receives the Vercel credential. No logging interceptor.
class VercelApi {
  VercelApi(String token, {Dio? dio, DateTime Function()? clock})
      : _token = token, _dio = dio ?? Dio(), _clock = clock ?? DateTime.now {
    _dio.options = BaseOptions(baseUrl: 'https://api.vercel.com',
      connectTimeout: const Duration(seconds: 12), receiveTimeout: const Duration(seconds: 25),
      sendTimeout: const Duration(seconds: 20), followRedirects: false,
      headers: {'Accept': 'application/json'});
  }
  final String _token;
  final Dio _dio;
  final DateTime Function() _clock;
  CancelToken _cancel = CancelToken();
  final Map<String, Future<Object?>> _reads = {};
  DateTime? _retryAt;
  String redact(String text) => text.replaceAll(_token, '[token oculto]');
  void cancel() {
    _cancel.cancel('cancelled');
    _cancel = CancelToken();
    _reads.clear();
  }
  void close() { cancel(); _dio.close(force: true); }
  static String segment(String value) => Uri.encodeComponent(value);
  Future<Object?> _request(String method, String path, {String? team, Json? query, Object? body}) async {
    if (!path.startsWith('/') || path.startsWith('//') || path.contains('://')) {
      throw const ApiFailure(FailureKind.invalid, 'Endereço de API não permitido.');
    }
    if (_retryAt != null && _clock().isBefore(_retryAt!)) {
      throw ApiFailure(FailureKind.rateLimit, 'Limite da API atingido. Aguarde para atualizar.', retryAt: _retryAt);
    }
    try {
      final response = await _dio.request<Object?>(path,
        queryParameters: {...?query, if (team != null) 'teamId': team}, data: body,
        options: Options(method: method, headers: {'Authorization': 'Bearer $_token'}), cancelToken: _cancel);
      return response.data;
    } on DioException catch (e) {
      // Never return server bodies, request headers or the original exception.
      if (e.type == DioExceptionType.cancel) {
        throw const ApiFailure(FailureKind.cancelled, 'Solicitação cancelada.');
      }
      final status = e.response?.statusCode;
      if (status == 401) throw const ApiFailure(FailureKind.authentication, 'Token expirado ou inválido. Substitua o token.');
      if (status == 403) throw const ApiFailure(FailureKind.forbidden, 'A conta ou o token não tem permissão para esta ação.');
      if (status == 404) throw const ApiFailure(FailureKind.missing, 'Recurso não encontrado ou indisponível para esta conta.');
      if (status == 429) {
        final raw = e.response?.headers.value('retry-after');
        final seconds = int.tryParse(raw ?? '');
        final reset = int.tryParse(e.response?.headers.value('x-ratelimit-reset') ?? '');
        _retryAt = seconds != null
          ? _clock().add(Duration(seconds: seconds.clamp(1, 86400).toInt()))
          : reset != null ? DateTime.fromMillisecondsSinceEpoch(reset * 1000)
          : _clock().add(const Duration(minutes: 1));
        if (!_retryAt!.isAfter(_clock())) _retryAt = _clock().add(const Duration(minutes: 1));
        throw ApiFailure(FailureKind.rateLimit, 'Limite da API atingido. Tente após ${_retryAt!.toLocal()}.', retryAt: _retryAt);
      }
      if (status == null) throw const ApiFailure(FailureKind.offline, 'Sem conexão com a Vercel. Verifique a internet.');
      if (status >= 500) throw const ApiFailure(FailureKind.server, 'A Vercel está indisponível. Tente novamente mais tarde.');
      throw const ApiFailure(FailureKind.invalid, 'A Vercel recusou os dados. Confira os campos e as permissões.');
    } on FormatException {
      throw const ApiFailure(FailureKind.invalid, 'Resposta inesperada da API.');
    }
  }
  Future<Object?> read(String path, {String? team, Json? query}) async {
    final key = '$path|$team|$query';
    final existing = _reads[key];
    if (existing != null) return existing;
    final future = _request('GET', path, team: team, query: query);
    _reads[key] = future;
    try { return await future; } finally { if (identical(_reads[key], future)) _reads.remove(key); }
  }
  Future<Json> get(String path, {String? team, Json? query}) async => object(await read(path, team: team, query: query));
  Future<Object?> write(String method, String path, {String? team, Object? body}) => _request(method, path, team: team, body: body);
}
