import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isSubmitting = false.obs;
  final obscurePassword = true.obs;

  void toggleObscure() => obscurePassword.toggle();

  String? validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Email wajib diisi.';
    if (!GetUtils.isEmail(email)) return 'Format email tidak valid.';
    return null;
  }

  String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Kata sandi wajib diisi.';
    return null;
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (isSubmitting.value) return;

    isSubmitting.value = true;

    try {
      final user = await _auth.login(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // The API also serves employers and admins. Their surfaces do not exist
      // in this client, so signing them in here would strand the user on
      // screens whose endpoints answer 403.
      if (!user.isEmployee) {
        await _auth.logout(navigateHome: false);
        AppToast.error(
          'Akun ini bukan akun pencari kerja. Gunakan aplikasi web.',
        );
        return;
      }

      AppToast.success('Selamat datang, ${user.name}.');
      Get.offAllNamed(Routes.DASHBOARD);
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSubmitting.value = false;
    }
  }

  void goToRegister() => Get.offNamed(Routes.REGISTER);

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
