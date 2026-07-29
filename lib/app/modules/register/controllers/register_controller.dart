import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class RegisterController extends GetxController {
  /// `Password::default()` on the server. Mirrored here so the user sees the
  /// rule before a round trip, not after a 422.
  static const int minPasswordLength = 8;

  final AuthService _auth = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmationController = TextEditingController();

  final isSubmitting = false.obs;
  final obscurePassword = true.obs;
  final obscureConfirmation = true.obs;

  void toggleObscure() => obscurePassword.toggle();
  void toggleObscureConfirmation() => obscureConfirmation.toggle();

  String? validateName(String? value) {
    final name = (value ?? '').trim();
    if (name.isEmpty) return 'Nama wajib diisi.';
    if (name.length > 255) return 'Nama maksimal 255 karakter.';
    return null;
  }

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!GetUtils.isEmail(email)) return 'Format email tidak valid.';
    return null;
  }

  String? validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isNotEmpty && phone.length > 32) {
      return 'Nomor telepon maksimal 32 karakter.';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Kata sandi wajib diisi.';
    if (password.length < minPasswordLength) {
      return 'Kata sandi minimal $minPasswordLength karakter.';
    }
    return null;
  }

  String? validatePasswordConfirmation(String? value) {
    if ((value ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi.';
    if (value != passwordController.text) return 'Konfirmasi tidak cocok.';
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSubmitting.value) return;

    isSubmitting.value = true;

    try {
      // Register signs the user in as well — the API returns tokens on 201, so
      // there is no second login round trip.
      final phone = phoneController.text.trim();

      final user = await _auth.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        passwordConfirmation: passwordConfirmationController.text,
        phone: phone.isEmpty ? null : phone,
      );

      AppToast.success('Akun dibuat. Selamat datang, ${user.name}.');
      Get.offAllNamed(Routes.DASHBOARD);
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSubmitting.value = false;
    }
  }

  void goToLogin() => Get.offNamed(Routes.LOGIN);

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    passwordConfirmationController.dispose();
    super.onClose();
  }
}
