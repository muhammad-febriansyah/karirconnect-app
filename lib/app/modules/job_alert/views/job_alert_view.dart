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
import '../../../data/models/job_alert_model.dart';
import '../controllers/job_alert_controller.dart';
import 'widgets/job_alert_form_sheet.dart';

/// `api/v1/job-alerts` — saved searches that get mailed as a digest.
class JobAlertView extends GetView<JobAlertController> {
  const JobAlertView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => JobAlertFormSheet.show(context, controller),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Iconsax.add),
          label: Text(
            'Alert baru',
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            const GradientHeaderBar(
              title: 'Job Alert',
              subtitle: 'Lowongan cocok dikirim otomatis',
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) return const SectionLoader();

                  final error = controller.errorMessage.value;
                  if (error != null) {
                    return ListView(
                      padding: EdgeInsets.all(AppSpacing.gutter.w),
                      children: [
                        ErrorState(message: error, onRetry: controller.load),
                      ],
                    );
                  }

                  final alerts = controller.alerts.toList();
                  if (alerts.isEmpty) {
                    return ListView(
                      padding: EdgeInsets.all(AppSpacing.gutter.w),
                      children: const [
                        EmptyState(
                          icon: Iconsax.notification_bing,
                          message:
                              'Belum ada alert. Buat satu agar lowongan yang cocok dikirim otomatis.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.gutter.w,
                      AppSpacing.xl.h,
                      AppSpacing.gutter.w,
                      90.h,
                    ),
                    itemCount: alerts.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) => _AlertCard(
                      alert: alerts[index],
                      controller: controller,
                    ),
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

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.controller});

  final JobAlertModel alert;
  final JobAlertController controller;

  @override
  Widget build(BuildContext context) {
    final criteria = [
      if (alert.keyword != null && alert.keyword!.isNotEmpty) '"${alert.keyword}"',
      if (alert.category != null) alert.category!,
      if (alert.city != null) alert.city!,
      if (alert.employmentType != null) Formatters.status(alert.employmentType),
      if (alert.workArrangement != null)
        Formatters.status(alert.workArrangement),
      if (alert.experienceLevel != null)
        Formatters.status(alert.experienceLevel),
      if (alert.salaryMin != null)
        'min ${Formatters.rupiahShort(alert.salaryMin)}',
    ];

    final frequencyLabel = JobAlertController.frequencies
        .firstWhere(
          (option) => option.value == alert.frequency,
          orElse: () => (value: alert.frequency, label: alert.frequency),
        )
        .label;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              Switch.adaptive(
                value: alert.isActive,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (_) => controller.toggleActive(alert),
              ),
            ],
          ),
          if (criteria.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: criteria
                  .map(
                    (label) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppColors.foreground.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(
                Iconsax.timer_1,
                size: 13.sp,
                color: AppColors.mutedForeground,
              ),
              SizedBox(width: 5.w),
              Text(
                frequencyLabel,
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
              SizedBox(width: 12.w),
              Icon(
                Iconsax.send_2,
                size: 13.sp,
                color: AppColors.mutedForeground,
              ),
              SizedBox(width: 5.w),
              Text(
                '${alert.totalMatchesSent} terkirim',
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: Iconsax.eye,
                  label: 'Pratinjau',
                  onTap: () => controller.preview(alert),
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Iconsax.edit_2,
                  label: 'Ubah',
                  onTap: () => JobAlertFormSheet.show(
                    context,
                    controller,
                    existing: alert,
                  ),
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Iconsax.trash,
                  label: 'Hapus',
                  destructive: true,
                  onTap: () => controller.remove(alert),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.destructive : AppColors.mutedForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
