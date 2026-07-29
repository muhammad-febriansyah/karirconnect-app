import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response, FormData, MultipartFile;

import '../models/user_model.dart';
import '../providers/api_request.dart';
import '../services/api_service.dart';

/// `api/v1/auth/*`.
///
/// The backend pairs a short-lived JWT access token with a rotating refresh
/// token. Register and login are throttled to 10 requests per minute per IP,
/// refresh to 30.
class AuthRepository with ApiRequestMixin {
  AuthRepository({ApiService? api}) : _api = api ?? Get.find<ApiService>();

  final ApiService _api;

  /// The `platform` value the API's `DevicePlatform` enum expects.
  ///
  /// Uses `defaultTargetPlatform` rather than `dart:io`'s `Platform`: on web
  /// the latter compiles but throws `UnsupportedError` the moment it is read,
  /// which would break login in a browser build.
  static String get _platform {
    if (kIsWeb) return 'web';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'web';
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'device_name': ?deviceName,
          'platform': _platform,
        },
      ),
    );

    return _session(response);
  }

  /// Registers and signs in with one call — the API returns tokens on 201.
  ///
  /// `password_confirmation` is required: the shared `CreateNewUser` action
  /// validates the password with `Password::default()` plus `confirmed`.
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
    String? deviceName,
  }) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'phone': ?phone,
          // This client is the jobseeker app; `employer` would also provision a
          // pending Company and land the user in a flow it cannot render.
          'role': 'employee',
          'locale': 'id',
          'device_name': ?deviceName,
          'platform': _platform,
        },
      ),
    );

    return _session(response);
  }

  Future<UserModel> me() async {
    final response =
        await send(() => _api.get<Map<String, dynamic>>('/auth/me'));

    return UserModel.fromJson(
      (response['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  /// Ends this session only. Passing the refresh token revokes it server-side;
  /// without it the token stays valid until it expires.
  Future<void> logout({String? refreshToken}) async {
    await send(
      () => _api.post<Map<String, dynamic>>(
        '/auth/logout',
        data: {'refresh_token': ?refreshToken},
      ),
    );
  }

  /// Exchanges a refresh token for a fresh access token *and* a fresh refresh
  /// token — the old one is burned, so the new pair must be persisted.
  Future<AuthSession> refresh(String refreshToken) async {
    final response = await send(
      () => _api.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      ),
    );

    return _session(response);
  }

  AuthSession _session(Map<String, dynamic> response) {
    final data = (response['data'] as Map?)?.cast<String, dynamic>() ?? const {};

    return AuthSession(
      user: UserModel.fromJson(
        (data['user'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      tokens: AuthTokens.fromJson(
        (data['tokens'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
