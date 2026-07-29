import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/recommendation_model.dart';
import '../controllers/recommendation_controller.dart';

/// `GET api/v1/recommendations` — jobs matched to the profile, each with the
/// reasons it matched.
class RecommendationView extends GetView<RecommendationController> {
  const RecommendationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const GradientHeaderBar(
              title: 'Rekomendasi',
              subtitle: 'Lowongan yang cocok dengan profilmu',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) return const SectionLoader();

                  final gutter = EdgeInsets.fromLTRB(
                    AppSpacing.gutter.w,
                    AppSpacing.xl.h,
                    AppSpacing.gutter.w,
                    AppSpacing.xl.h,
                  );

                  final error = controller.errorMessage.value;
                  if (error != null) {
                    return ListView(
                      padding: gutter,
                      children: [
                        ErrorState(message: error, onRetry: controller.load),
                      ],
                    );
                  }

                  final items = controller.items.toList();
                  if (items.isEmpty) {
                    return ListView(
                      padding: gutter,
                      children: [
                        EmptyState(
                          icon: Iconsax.magic_star,
                          message: controller.profileCompletion.value < 60
                              ? 'Profilmu baru ${controller.profileCompletion.value}% lengkap. Lengkapi profil agar rekomendasi lebih akurat.'
                              : 'Belum ada rekomendasi baru. Cek lagi nanti.',
                        ),
                      ],
                    );
                  }

                  final saved = controller.savedSlugs;

                  return ListView.separated(
                    padding: gutter,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.lg.h),
                    itemBuilder: (context, index) {
                      final item = items[index];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          JobCard(
                            job: item.job,
                            isSaved: saved.contains(item.job.slug),
                            onTap: () => controller.openJob(item.job),
                            onSave: () => controller.toggleSave(item.job),
                          ),
                          SizedBox(height: AppSpacing.sm.h),
                          _MatchPanel(
                            item: item,
                            onDismiss: () => controller.dismiss(item),
                          ),
                        ],
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPanel extends StatelessWidget {
  const _MatchPanel({required this.item, required this.onDismiss});

  final RecommendationModel item;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final score = item.score.round();

    return Container(
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 8.w, 12.h),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.magic_star,
                size: 15.sp,
                color: AppColors.accentForeground,
              ),
              SizedBox(width: 7.w),
              Text(
                'Cocok $score%',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentForeground,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: AppColors.mutedForeground,
                ),
                child: Text(
                  'Sembunyikan',
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
          if (item.explanation.isNotEmpty) ...[
            SizedBox(height: 4.h),
            ...item.explanation.take(3).map(
                  (reason) => Padding(
                    padding: EdgeInsets.only(bottom: 3.h, right: 8.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Icon(
                            Iconsax.tick_circle,
                            size: 12.sp,
                            color: AppColors.accentForeground,
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              height: 1.35,
                              color: AppColors.foreground.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
