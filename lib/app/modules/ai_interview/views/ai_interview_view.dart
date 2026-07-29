import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/ai_interview_model.dart';
import '../controllers/ai_interview_controller.dart';

/// `GET api/v1/ai-interviews` — start a text-mode practice interview or reopen
/// a past one.
class AiInterviewView extends GetView<AiInterviewController> {
  const AiInterviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          if (!controller.isLoggedIn) {
            return SafeArea(
              child: AuthRequiredState(
                title: 'Masuk untuk latihan interview',
                message:
                    'Latihan wawancara dengan AI dan dapatkan analisis jawabanmu.',
                icon: Iconsax.microphone_2,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            );
          }

          return Column(
            children: [
              const GradientHeaderBar(
                title: 'AI Interview',
                subtitle: 'Latihan wawancara dan analisis AI',
              ),
              Expanded(child: _Body()),
            ],
          );
        }),
      ),
    );
  }
}

class _Body extends GetView<AiInterviewController> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final gutter = EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
          AppSpacing.gutter.w,
          AppSpacing.section.h,
        );

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: gutter,
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        final sessions = controller.sessions.toList();

        return ListView(
          padding: gutter,
          children: [
            const _StartCard(),
            if (sessions.isNotEmpty) ...[
              SizedBox(height: AppSpacing.section.h),
              Text(
                'Riwayat latihan',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              ...sessions.map((session) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                    child: _SessionCard(session: session),
                  )),
            ],
          ],
        );
      }),
    );
  }
}

class _StartCard extends GetView<AiInterviewController> {
  const _StartCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl.w),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(Iconsax.microphone_2, size: 22.sp, color: Colors.white),
          ),
          SizedBox(height: AppSpacing.md.h),
          Text(
            'Latihan interview',
            style: GoogleFonts.poppins(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: AppSpacing.xs.h),
          Text(
            'Jawab beberapa pertanyaan wawancara, lalu AI menilai kekuatan dan '
            'hal yang bisa diperbaiki.',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: AppSpacing.lg.h),
          Obx(
            () => ElevatedButton.icon(
              onPressed: controller.isStarting.value
                  ? null
                  : controller.startPractice,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandNavy,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl.w,
                  vertical: AppSpacing.md.h,
                ),
              ),
              icon: controller.isStarting.value
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(Iconsax.play, size: 16.sp),
              label: Text(
                'Mulai latihan',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends GetView<AiInterviewController> {
  const _SessionCard({required this.session});

  final InterviewSession session;

  static const Map<String, ({String label, Color color})> _statusMeta = {
    'completed': (label: 'Selesai', color: AppColors.success),
    'analyzing': (label: 'Dianalisis', color: AppColors.warning),
    'in_progress': (label: 'Berlangsung', color: AppColors.primary),
    'pending': (label: 'Belum mulai', color: AppColors.mutedForeground),
    'expired': (label: 'Kedaluwarsa', color: AppColors.mutedForeground),
    'cancelled': (label: 'Dibatalkan', color: AppColors.mutedForeground),
  };

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta[session.status] ??
        (label: session.status, color: AppColors.mutedForeground);

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => controller.openSession(session),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(
                  Iconsax.microphone_2,
                  size: 20.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.jobTitle ?? 'Latihan interview',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      session.createdAt == null
                          ? 'Sesi latihan'
                          : Formatters.relative(session.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.md.w,
                  vertical: 5.h,
                ),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  meta.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: meta.color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
