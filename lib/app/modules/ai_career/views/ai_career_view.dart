import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../controllers/ai_career_controller.dart';

/// The floating middle tab: a hub for the AI features the onboarding artwork
/// promises. Each row routes to login when signed out.
class AiCareerView extends GetView<AiCareerController> {
  const AiCareerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _Header()),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 24.h),
            sliver: SliverList.separated(
              itemCount: AiCareerController.features.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final feature = AiCareerController.features[index];

                return _FeatureTile(
                  feature: feature,
                  onTap: () => controller.open(feature),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends GetView<AiCareerController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.magicpen,
                      size: 13.sp,
                      color: AppColors.brandCyan,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'AI Karier',
                      style: GoogleFonts.poppins(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              Obx(() {
                final name = controller.greetingName;

                return Text(
                  name.isEmpty
                      ? 'Tingkatkan peluangmu\nditerima kerja'
                      : 'Halo, $name.\nSiapkan langkah berikutnya.',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                );
              }),
              SizedBox(height: 6.h),
              Text(
                'Persiapkan CV dan latihan interview dengan bantuan AI.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              Obx(() {
                if (controller.isLoggedIn) return const SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(top: 16.h),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: controller.goToLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.brandNavy,
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 11.h,
                          ),
                        ),
                        child: const Text('Masuk'),
                      ),
                      SizedBox(width: 10.w),
                      // This one sits on the blue hero, so it cannot take the
                      // theme's light `accent` fill — that would put white
                      // text on #E0F1FE. A translucent white keeps the label
                      // at ~5:1 and matches the other on-gradient surfaces.
                      OutlinedButton(
                        onPressed: controller.goToRegister,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.16),
                          padding: EdgeInsets.symmetric(
                            horizontal: 18.w,
                            vertical: 11.h,
                          ),
                        ),
                        child: const Text('Daftar'),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature, required this.onTap});

  final AiFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(
                  feature.icon,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      feature.description,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        height: 1.35,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(
                Iconsax.arrow_right_3,
                size: 16.sp,
                color: AppColors.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
