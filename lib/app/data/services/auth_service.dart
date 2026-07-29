import 'package:get/get.dart';

import '../../core/utils/app_toast.dart';
import '../../routes/app_pages.dart';
import '../models/user_model.dart';
import '../providers/api_exception.dart';
import '../repositories/auth_repository.dart';
import 'storage_service.dart';

/// App-wide session state. Registered permanently in `main.dart`, so any
/// controller can ask `Get.find<AuthService>().isLoggedIn`.
class AuthService extends GetxService {
  AuthService(this._storage, {AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final StorageService _storage;
  final AuthRepository _repository;

  final Rxn<UserModel> user = Rxn<UserModel>();

  bool get isLoggedIn => user.value != null && _storage.isLoggedIn;

  @override
  void onInit() {
    super.onInit();

    // Rehydrate from disk so a returning user is signed in before the first
    // frame. The token is not validated here; the first 401 handles expiry.
    final cached = _storage.user;
    if (cached != null && _storage.isLoggedIn) {
      user.value = UserModel.fromJson(cached);
    }
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final session = await _repository.login(email: email, password: password);
    await _persist(session);
    return session.user;
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final session = await _repository.register(
      name: name,
      email: email,
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone,
    );
    await _persist(session);
    return session.user;
  }

  /// Clears the session locally no matter what the server says — a failed
  /// revoke must not strand the user in a signed-in shell they cannot leave.
  Future<void> logout({bool navigateHome = true}) async {
    try {
      await _repository.logout(refreshToken: _storage.refreshToken);
    } on ApiException catch (_) {
      // Best effort.
    }

    await _storage.clearSession();
    user.value = null;

    if (navigateHome) {
      Get.offAllNamed(Routes.DASHBOARD);
    }
  }

  /// Called by `ApiService` when a refresh fails, i.e. the session is over.
  /// The tokens are already cleared there; this drops the cached user so the
  /// auth-gated screens flip back to their login prompt.
  void handleSessionExpired() {
    if (user.value == null) return;

    user.value = null;
    AppToast.info('Sesi berakhir. Silakan masuk lagi.');
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.saveSession(
      accessToken: session.tokens.accessToken,
      refreshToken: session.tokens.refreshToken,
      user: session.user.toJson(),
    );

    user.value = session.user;
  }
}
