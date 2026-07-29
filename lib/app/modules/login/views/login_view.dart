import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Masuk ke akunmu',
      subtitle: 'Lanjutkan perjalanan kariermu bersama KarirConnect.',
      form: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: controller.emailController,
              validator: controller.validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            Obx(
              () => AuthField(
                label: 'Kata sandi',
                hint: 'Masukkan kata sandi',
                controller: controller.passwordController,
                validator: controller.validatePassword,
                obscureText: controller.obscurePassword.value,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => controller.submit(),
                suffix: IconButton(
                  onPressed: controller.toggleObscure,
                  icon: Icon(
                    controller.obscurePassword.value
                        ? Iconsax.eye_slash
                        : Iconsax.eye,
                    size: 18.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Obx(
              () => ElevatedButton(
                onPressed:
                    controller.isSubmitting.value ? null : controller.submit,
                child: controller.isSubmitting.value
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Masuk'),
              ),
            ),
          ],
        ),
      ),
      footer: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Belum punya akun?',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
              TextButton(
                onPressed: controller.goToRegister,
                child: const Text('Daftar sekarang'),
              ),
            ],
          ),
          TextButton(
            onPressed: Get.back<void>,
            child: Text(
              'Jelajahi tanpa akun',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
