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
import '../../../data/models/application_model.dart';
import '../controllers/applications_controller.dart';

/// Lamaran tab. Wears the same header shell as Beranda and Lowongan so the five
/// bottom-nav tabs read as one app.
class ApplicationsView extends GetView<ApplicationsController> {
  const ApplicationsView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          // Signed out: a full-screen prompt, no header. Every endpoint here
          // 401s without a session, so there is nothing to head.
          if (!controller.isLoggedIn) {
            return SafeArea(
              child: AuthRequiredState(
                title: 'Masuk untuk melihat lamaran',
                message:
                    'Lacak status setiap lamaran dan jadwal interview dalam satu tempat.',
                icon: Iconsax.document_text,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            );
          }

          return Column(
            children: [
              const _ApplicationsHeader(),
              const _StatusFilter(),
              Expanded(child: _Body()),
            ],
          );
        }),
      ),
    );
  }
}

class _ApplicationsHeader extends GetView<ApplicationsController> {
  const _ApplicationsHeader();

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lamaran',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 2.h),
          Obx(() {
            final loading = controller.isLoading.value;
            final count = controller.applications.length;

            return Text(
              loading
                  ? 'Memuat lamaran…'
                  : count == 0
                      ? 'Lacak status lamaranmu di sini'
                      : '$count lamaran di daftarmu',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusFilter extends GetView<ApplicationsController> {
  const _StatusFilter();

  @override
  Widget build(BuildContext context) {
    return HeaderSheet(
      // Bottom padding keeps the pinned chip row off the list scrolling under
      // it — see jobs_view for the slicing this prevents.
      padding: EdgeInsets.only(top: AppSpacing.xl.h, bottom: AppSpacing.md.h),
      child: SizedBox(
        height: 36.h,
        child: Obx(() {
          final active = controller.activeStatus.value;

          return ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
              itemCount: ApplicationsController.statusFilters.length,
              separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
              itemBuilder: (context, index) {
                final filter = ApplicationsController.statusFilters[index];

                return FilterChipButton(
                  label: filter.label,
                  active: active == filter.value,
                  onTap: () => controller.selectStatus(filter.value),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

class _Body extends GetView<ApplicationsController> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final gutter = EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.md.h,
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
        );

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: gutter,
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        final applications = controller.applications.toList();
        if (applications.isEmpty) {
          return ListView(
            padding: gutter,
            children: const [
              EmptyState(
                icon: Iconsax.document_text,
                message:
                    'Belum ada lamaran di status ini. Mulai melamar dari tab Lowongan.',
              ),
            ],
          );
        }

        return ListView.separated(
          padding: gutter,
          itemCount: applications.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) => _ApplicationCard(
            application: applications[index],
            onTap: () => controller.open(applications[index]),
          ),
        );
      }),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application, required this.onTap});

  final ApplicationModel application;
  final VoidCallback onTap;

  /// Colour per status family. Anything unmapped falls back to the muted
  /// treatment rather than guessing.
  static const Map<String, Color> _statusColors = {
    'submitted': AppColors.primary,
    'reviewed': AppColors.primary,
    'shortlisted': AppColors.brandCyan,
    'interview': AppColors.warning,
    'offered': AppColors.success,
    'hired': AppColors.success,
    'rejected': AppColors.destructive,
    'withdrawn': AppColors.mutedForeground,
  };

  @override
  Widget build(BuildContext context) {
    final job = application.job;
    final statusColor =
        _statusColors[application.status] ?? AppColors.mutedForeground;

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44.w,
                    height: 44.w,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceInset,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      Formatters.initials(job?.companyName ?? job?.title),
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandNavy,
                      ),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job?.title ?? 'Lowongan',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.sp,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandNavy,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          job?.companyName ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      application.statusLabel ??
                          Formatters.status(application.status),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Iconsax.clock,
                    size: 13.sp,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    Formatters.relative(application.appliedAt),
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
