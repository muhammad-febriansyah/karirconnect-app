import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/values/app_assets.dart';
import '../../../core/values/app_colors.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, AppColors.background],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _AnimatedLogo(animation: controller.animation),
                SizedBox(height: 20.h),
                _FadeIn(
                  animation: controller.animation,
                  delay: 0.45,
                  child: Text(
                    'Temukan peluang karier yang tepat',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const Spacer(flex: 3),
                _FadeIn(
                  animation: controller.animation,
                  delay: 0.6,
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ),
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Logo mark scales up while the wordmark fades in just behind it.
class _AnimatedLogo extends StatelessWidget {
  const _AnimatedLogo({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.7, curve: Curves.easeOutBack),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleTransition(
          scale: scale,
          child: FadeTransition(
            opacity: scale,
            child: Image.asset(
              AppAssets.logoMark,
              width: 96.w,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        SizedBox(height: 22.h),
        _FadeIn(
          animation: animation,
          delay: 0.35,
          child: Text(
            'KarirConnect',
            style: GoogleFonts.poppins(
              fontSize: 26.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: -0.4,
            ),
          ),
        ),
      ],
    );
  }
}

/// Fade + short rise, starting at [delay] through the parent animation.
class _FadeIn extends StatelessWidget {
  const _FadeIn({
    required this.animation,
    required this.child,
    this.delay = 0,
  });

  final Animation<double> animation;
  final Widget child;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Interval(delay, 1, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
