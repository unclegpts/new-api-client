import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  late final Dio dio;
  late final PersistCookieJar _cookieJar;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _baseUrl;

  static final ApiClient _instance = ApiClient._();
  factory ApiClient() => _instance;

  ApiClient._() {
    _cookieJar = PersistCookieJar(
      storage: FileStorage('/tmp/new-api-cookies'),
      ignoreExpires: false,
    );
    dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Cache-Control': 'no-store'},
    ));
    dio.interceptors.addAll([
      CookieManager(_cookieJar),
      _AuthInterceptor(this),
      LogInterceptor(requestBody: false, responseBody: false),
    ]);
  }

  Future<void> configure({required String baseUrl}) async {
    _baseUrl = baseUrl;
    dio.options.baseUrl = baseUrl;
  }

  String? get baseUrl => _baseUrl;

  Future<String?> get token => _secureStorage.read(key: 'auth_token');
  Future<String?> get userId => _secureStorage.read(key: 'user_id');

  Future<void> setAuth({required String token, required String userId}) async {
    await _secureStorage.write(key: 'auth_token', value: token);
    await _secureStorage.write(key: 'user_id', value: userId);
  }

  Future<void> clearAuth() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_id');
  }

  Future<String?> getServerUrl() async {
    return _secureStorage.read(key: 'server_url');
  }

  Future<void> setServerUrl(String url) async {
    await _secureStorage.write(key: 'server_url', value: url);
  }

  /// 清除 session cookies（登出用）
  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }
}

class _AuthInterceptor extends Interceptor {
  final ApiClient client;
  _AuthInterceptor(this.client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Session cookie 由 CookieManager 自动处理。
    // 如果保存了 access token，也加到请求头（供 API relay 等场景用）。
    final token = await client.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      client.clearAuth();
    }
    handler.next(err);
  }
}
