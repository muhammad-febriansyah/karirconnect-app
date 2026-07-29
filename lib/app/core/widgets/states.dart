import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';
import '../values/app_colors.dart';

class SectionLoader extends StatelessWidget {
  const SectionLoader({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height ?? 48.h),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon = Iconsax.briefcase,
    this.action,
  });

  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28.sp, color: AppColors.mutedForeground),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          if (action != null) ...[SizedBox(height: 14.h), action!],
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Icon(Iconsax.warning_2, size: 28.sp, color: AppColors.destructive),
          SizedBox(height: 10.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.foreground,
            ),
          ),
          SizedBox(height: 14.h),
          OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}

/// Shown on the tabs that sit behind `auth:api` + `role:employee` when there is
/// no session, instead of firing a request that would only 401.
class AuthRequiredState extends StatelessWidget {
  const AuthRequiredState({
    super.key,
    required this.title,
    required this.message,
    required this.onLogin,
    required this.onRegister,
    this.icon = Iconsax.lock_1,
  });

  final String title;
  final String message;
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26.sp, color: AppColors.primary),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandNavy,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                color: AppColors.mutedForeground,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onRegister,
                    child: const Text('Daftar'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onLogin,
                    child: const Text('Masuk'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
