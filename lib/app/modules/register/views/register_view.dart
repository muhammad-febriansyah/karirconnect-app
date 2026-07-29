import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/values/app_colors.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Buat akun baru',
      subtitle: 'Gratis untuk kandidat. Mulai melamar dalam hitungan menit.',
      form: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
              label: 'Nama lengkap',
              hint: 'Nama sesuai identitas',
              controller: controller.nameController,
              validator: controller.validateName,
              textInputAction: TextInputAction.next,
            ),
            AuthField(
              label: 'Email',
              hint: 'nama@email.com',
              controller: controller.emailController,
              validator: controller.validateEmail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            AuthField(
              label: 'Nomor telepon (opsional)',
              hint: '08xxxxxxxxxx',
              controller: controller.phoneController,
              validator: controller.validatePhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
            ),
            Obx(
              () => AuthField(
                label: 'Kata sandi',
                hint: 'Minimal ${RegisterController.minPasswordLength} karakter',
                controller: controller.passwordController,
                validator: controller.validatePassword,
                obscureText: controller.obscurePassword.value,
                textInputAction: TextInputAction.next,
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
            Obx(
              () => AuthField(
                label: 'Ulangi kata sandi',
                hint: 'Ketik ulang kata sandi',
                controller: controller.passwordConfirmationController,
                validator: controller.validatePasswordConfirmation,
                obscureText: controller.obscureConfirmation.value,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => controller.submit(),
                suffix: IconButton(
                  onPressed: controller.toggleObscureConfirmation,
                  icon: Icon(
                    controller.obscureConfirmation.value
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
                    : const Text('Daftar'),
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Sudah punya akun?',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          TextButton(
            onPressed: controller.goToLogin,
            child: const Text('Masuk'),
          ),
        ],
      ),
    );
  }
}
