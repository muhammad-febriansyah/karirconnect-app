import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/assessment_model.dart';
import '../controllers/skill_assessment_controller.dart';

/// `GET api/v1/skill-assessments` — pick a skill to be tested on, or reopen a
/// past attempt.
class SkillAssessmentView extends GetView<SkillAssessmentController> {
  const SkillAssessmentView({super.key});

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
                title: 'Masuk untuk uji keahlian',
                message:
                    'Uji skill-mu dan tampilkan hasilnya ke perekrut sebagai bukti kemampuan.',
                icon: Iconsax.medal_star,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            );
          }

          return Column(
            children: [
              const GradientHeaderBar(
                title: 'Skill Assessment',
                subtitle: 'Uji keahlian dan buktikan ke perekrut',
              ),
              Expanded(child: _Body()),
            ],
          );
        }),
      ),
    );
  }
}

class _Body extends GetView<SkillAssessmentController> {
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

        final skills = controller.skills.toList();
        final attempts = controller.attempts.toList();

        if (skills.isEmpty && attempts.isEmpty) {
          return ListView(
            padding: gutter,
            children: const [
              EmptyState(
                icon: Iconsax.medal_star,
                message: 'Belum ada skill yang bisa diuji saat ini.',
              ),
            ],
          );
        }

        return ListView(
          padding: gutter,
          children: [
            if (attempts.isNotEmpty) ...[
              const SectionHeader(title: 'Riwayat asesmen'),
              SizedBox(height: AppSpacing.md.h),
              ...attempts.map((attempt) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                    child: _AttemptCard(attempt: attempt),
                  )),
              SizedBox(height: AppSpacing.lg.h),
            ],
            if (skills.isNotEmpty) ...[
              const SectionHeader(
                title: 'Pilih skill',
                subtitle: 'Setiap asesmen berisi beberapa pertanyaan singkat.',
              ),
              SizedBox(height: AppSpacing.md.h),
              ...skills.map((skill) => Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                    child: _SkillCard(skill: skill),
                  )),
            ],
          ],
        );
      }),
    );
  }
}

class _SkillCard extends GetView<SkillAssessmentController> {
  const _SkillCard({required this.skill});

  final AssessmentSkill skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(Iconsax.code, size: 20.sp, color: AppColors.primary),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skill.name,
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
                  [
                    if (skill.category != null) skill.category!,
                    '${skill.questionCount} soal',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Obx(() {
            final busy = controller.startingSkillId.value == skill.id;

            return SizedBox(
              height: 36.h,
              child: ElevatedButton(
                onPressed: busy ? null : () => controller.startSkill(skill),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                ),
                child: busy
                    ? SizedBox(
                        width: 15.w,
                        height: 15.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Mulai',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AttemptCard extends GetView<SkillAssessmentController> {
  const _AttemptCard({required this.attempt});

  final AssessmentAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final completed = attempt.isCompleted;
    final score = attempt.score?.round();
    final passed = (score ?? 0) >= 70;
    final tone = !completed
        ? AppColors.warning
        : passed
            ? AppColors.success
            : AppColors.destructive;

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: () => controller.openAttempt(attempt),
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Row(
            children: [
              // A score dial for completed attempts, a "lanjutkan" glyph for
              // in-progress ones.
              Container(
                width: 46.w,
                height: 46.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: completed
                    ? Text(
                        '$score',
                        style: GoogleFonts.poppins(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: tone,
                        ),
                      )
                    : Icon(Iconsax.play, size: 18.sp, color: tone),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attempt.skill ?? 'Asesmen',
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
                      completed
                          ? '${attempt.correctAnswers ?? 0}/${attempt.totalQuestions} benar'
                          : 'Belum selesai · lanjutkan',
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
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
