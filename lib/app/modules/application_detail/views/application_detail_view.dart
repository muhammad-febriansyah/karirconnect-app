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
import '../../../data/models/application_detail_model.dart';
import '../controllers/application_detail_controller.dart';

/// `GET api/v1/applications/{id}` plus the withdraw action.
class ApplicationDetailView extends GetView<ApplicationDetailController> {
  const ApplicationDetailView({super.key});

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
            const GradientHeaderBar(title: 'Detail Lamaran'),
            Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _Body extends GetView<ApplicationDetailController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const SectionLoader();

      final error = controller.errorMessage.value;
      if (error != null) {
        return ListView(
          padding: EdgeInsets.all(AppSpacing.gutter.w),
          children: [ErrorState(message: error, onRetry: controller.load)],
        );
      }

      final detail = controller.detail.value;
      if (detail == null) {
        return const EmptyState(message: 'Lamaran tidak ditemukan.');
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
        ),
        children: [
            _Summary(detail: detail),
            if (detail.coverLetter != null) ...[
              SizedBox(height: 16.h),
              _Block(
                title: 'Surat lamaran',
                child: Text(
                  detail.coverLetter!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    height: 1.55,
                    color: AppColors.foreground.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            if (detail.statusLogs.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _Block(
                title: 'Riwayat status',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: detail.statusLogs
                      .map((log) => _LogRow(log: log))
                      .toList(),
                ),
              ),
            ],
            SizedBox(height: 20.h),
            if (controller.canWithdraw)
              OutlinedButton.icon(
                onPressed: controller.isWithdrawing.value
                    ? null
                    : () => _confirmWithdraw(context),
                icon: Icon(
                  Iconsax.close_circle,
                  size: 17.sp,
                  color: AppColors.destructive,
                ),
                label: Text(
                  'Batalkan lamaran',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.destructive,
                  ),
                ),
              ),
          ],
        );
      });
  }

  /// Withdrawing cannot be undone — the server treats withdrawn as terminal —
  /// so it asks first.
  Future<void> _confirmWithdraw(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Batalkan lamaran?',
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
          ),
        ),
        content: Text(
          'Lamaran yang dibatalkan tidak bisa dikirim ulang untuk lowongan ini.',
          style: GoogleFonts.poppins(
            fontSize: 12.5.sp,
            height: 1.5,
            color: AppColors.mutedForeground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Batalkan',
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.destructive,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) await controller.withdraw();
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.detail});

  final ApplicationDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final application = detail.application;
    final job = application.job;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            job?.title ?? 'Lowongan',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            job?.companyName ?? '-',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          SizedBox(height: 14.h),
          _Row(
            icon: Iconsax.status,
            label: 'Status',
            value: application.statusLabel ??
                Formatters.status(application.status),
          ),
          _Row(
            icon: Iconsax.clock,
            label: 'Dilamar',
            value: Formatters.relative(application.appliedAt),
          ),
          if (application.aiMatchScore != null)
            _Row(
              icon: Iconsax.magic_star,
              label: 'Skor kecocokan',
              value: '${application.aiMatchScore!.round()}%',
            ),
          if (detail.expectedSalary != null)
            _Row(
              icon: Iconsax.wallet_3,
              label: 'Ekspektasi gaji',
              value: Formatters.rupiahShort(detail.expectedSalary),
            ),
          if (detail.cvLabel != null)
            _Row(
              icon: Iconsax.document_text,
              label: 'CV terlampir',
              value: detail.cvLabel!,
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(icon, size: 15.sp, color: AppColors.mutedForeground),
          SizedBox(width: 10.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.brandNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});

  final ApplicationStatusLog log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8.w,
            height: 8.w,
            margin: EdgeInsets.only(top: 5.h),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Formatters.status(log.toStatus),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.foreground,
                  ),
                ),
                if (log.note != null && log.note!.isNotEmpty)
                  Text(
                    log.note!,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      height: 1.4,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                Text(
                  [
                    Formatters.relative(log.createdAt),
                    if (log.changedBy != null) log.changedBy!,
                  ].join(' · '),
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
