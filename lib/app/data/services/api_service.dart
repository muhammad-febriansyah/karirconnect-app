import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import 'storage_service.dart';

/// Single Dio instance for the whole app. Registered permanently in
/// `main.dart` so any controller can reach it with `Get.find<ApiService>()`.
class ApiService extends GetxService {
  ApiService(this._storage);

  /// Marks a request that has already been retried after a refresh, so a second
  /// 401 gives up instead of looping.
  static const String _retriedFlag = 'karirconnect_retried';

  final StorageService _storage;

  late final Dio dio;

  /// Called when the refresh token is gone or rejected, i.e. the session is
  /// truly over. `main.dart` wires this to `AuthService`.
  void Function()? onSessionExpired;

  /// In-flight refresh, shared by every request that 401s at the same time —
  /// otherwise a screen firing three parallel calls would burn three refresh
  /// tokens and two of them would fail, because the server rotates on use.
  Future<bool>? _refreshing;

  static int _envInt(String key, int fallback) =>
      int.tryParse(dotenv.env[key] ?? '') ?? fallback;

  String get _baseUrl => dotenv.env['BASE_URL'] ?? '';

  @override
  void onInit() {
    super.onInit();

    dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout:
            Duration(milliseconds: _envInt('CONNECT_TIMEOUT_MS', 15000)),
        receiveTimeout:
            Duration(milliseconds: _envInt('RECEIVE_TIMEOUT_MS', 15000)),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        // Let the app decide how to handle non-2xx instead of throwing.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Read per request rather than caching: login, logout and refresh all
          // rewrite the stored token, and a cached copy would go stale.
          final token = _storage.accessToken;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },

        // `validateStatus` accepts anything under 500, so a 401 arrives here as
        // an ordinary response rather than through onError.
        onResponse: (response, handler) async {
          if (!_shouldRefresh(response)) return handler.next(response);

          final refreshed = await _refreshSession();
          if (!refreshed) return handler.next(response);

          final retryOptions = response.requestOptions
            ..extra[_retriedFlag] = true
            ..headers['Authorization'] = 'Bearer ${_storage.accessToken}';

          try {
            handler.next(await dio.fetch(retryOptions));
          } on DioException catch (error) {
            handler.next(error.response ?? response);
          }
        },
      ),
    );
  }

  bool _shouldRefresh(Response<dynamic> response) {
    if (response.statusCode != 401) return false;

    final options = response.requestOptions;

    // Already retried once — a second 401 means the fresh token is not the
    // problem.
    if (options.extra[_retriedFlag] == true) return false;

    // The auth endpoints own the token lifecycle; refreshing in response to
    // their own 401 would recurse. A failed login must stay a failed login.
    if (options.path.startsWith('/auth/')) return false;

    return (_storage.refreshToken ?? '').isNotEmpty;
  }

  /// Exchanges the stored refresh token for a new pair.
  ///
  /// Uses a bare Dio rather than [dio] so the call cannot re-enter this
  /// interceptor, and so it is unaffected by the Authorization header the
  /// request interceptor would otherwise attach.
  Future<bool> _refreshSession() {
    return _refreshing ??= _performRefresh().whenComplete(() {
      _refreshing = null;
    });
  }

  Future<bool> _performRefresh() async {
    final refreshToken = _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      ).post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        await _endSession();
        return false;
      }

      final data =
          (response.data?['data'] as Map?)?.cast<String, dynamic>() ?? const {};
      final tokens =
          (data['tokens'] as Map?)?.cast<String, dynamic>() ?? const {};

      final access = tokens['access_token'] as String? ?? '';
      // The server rotates on use: the old refresh token is dead, so the new
      // one has to be stored or the next refresh fails.
      final refreshed = tokens['refresh_token'] as String? ?? '';

      if (access.isEmpty || refreshed.isEmpty) {
        await _endSession();
        return false;
      }

      await _storage.saveSession(
        accessToken: access,
        refreshToken: refreshed,
        user: (data['user'] as Map?)?.cast<String, dynamic>(),
      );

      return true;
    } on DioException catch (_) {
      // A transport failure is not proof the session is over, so the tokens are
      // left alone and the original 401 is surfaced instead.
      return false;
    }
  }

  Future<void> _endSession() async {
    await _storage.clearSession();
    onSessionExpired?.call();
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? query,
  }) =>
      dio.get<T>(path, queryParameters: query);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      dio.post<T>(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      dio.put<T>(path, data: data);

  Future<Response<T>> delete<T>(String path, {Object? data}) =>
      dio.delete<T>(path, data: data);
}
