import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

/// Local key-value storage. Wraps GetStorage so key names live in one place
/// and callers never touch string literals.
class StorageService extends GetxService {
  static const String _kOnboardingSeen = 'onboarding_seen';
  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';
  static const String _kUser = 'user';

  final GetStorage _box = GetStorage();

  bool get onboardingSeen => _box.read<bool>(_kOnboardingSeen) ?? false;

  Future<void> markOnboardingSeen() => _box.write(_kOnboardingSeen, true);

  String? get accessToken => _box.read<String>(_kAccessToken);

  String? get refreshToken => _box.read<String>(_kRefreshToken);

  Map<String, dynamic>? get user {
    final raw = _box.read(_kUser);
    return raw is Map ? Map<String, dynamic>.from(raw) : null;
  }

  bool get isLoggedIn => (accessToken ?? '').isNotEmpty;

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? user,
  }) async {
    await _box.write(_kAccessToken, accessToken);
    await _box.write(_kRefreshToken, refreshToken);
    if (user != null) {
      await _box.write(_kUser, user);
    }
  }

  Future<void> clearSession() async {
    await _box.remove(_kAccessToken);
    await _box.remove(_kRefreshToken);
    await _box.remove(_kUser);
  }
}
