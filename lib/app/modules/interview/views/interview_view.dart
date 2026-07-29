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
import '../../../data/models/interview_model.dart';
import '../controllers/interview_controller.dart';
import 'widgets/reschedule_sheet.dart';

/// `api/v1/interviews` — the candidate side: see the schedule, accept or
/// decline the invitation, or ask for another slot.
class InterviewView extends GetView<InterviewController> {
  const InterviewView({super.key});

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
              title: 'Interview',
              subtitle: 'Jadwal dan undangan wawancaramu',
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter.w,
                AppSpacing.lg.h,
                AppSpacing.gutter.w,
                0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Obx(
                  () => _FilterChip(
                    active: controller.upcomingOnly.value,
                    onTap: controller.toggleUpcoming,
                  ),
                ),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) return const SectionLoader();

                  final gutter = EdgeInsets.fromLTRB(
                    AppSpacing.gutter.w,
                    AppSpacing.lg.h,
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

                  final interviews = controller.interviews.toList();
                  if (interviews.isEmpty) {
                    return ListView(
                      padding: gutter,
                      children: const [
                        EmptyState(
                          icon: Iconsax.calendar_2,
                          message:
                              'Belum ada jadwal interview. Undangan akan muncul di sini setelah perekrut menjadwalkanmu.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: gutter,
                    itemCount: interviews.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) => _InterviewCard(
                      interview: interviews[index],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          child: Text(
            'Akan datang saja',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _InterviewCard extends StatelessWidget {
  const _InterviewCard({required this.interview, required this.controller});

  final InterviewModel interview;
  final InterviewController controller;

  @override
  Widget build(BuildContext context) {
    final isOnline = interview.mode == 'online';

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      interview.title,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    if (interview.job != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        [
                          if (interview.job!.title != null) interview.job!.title!,
                          if (interview.job!.company != null)
                            interview.job!.company!,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _StatusBadge(interview: interview),
            ],
          ),
          SizedBox(height: 12.h),
          _Detail(
            icon: Iconsax.calendar_2,
            text: _scheduleLabel(),
          ),
          if (interview.stage != null)
            _Detail(
              icon: Iconsax.hierarchy_square_2,
              text: 'Tahap ${Formatters.status(interview.stage)}',
            ),
          _Detail(
            icon: isOnline ? Iconsax.video : Iconsax.location,
            text: isOnline
                ? (interview.meetingUrl ?? 'Tautan menyusul')
                : (interview.locationName ??
                    interview.locationAddress ??
                    'Lokasi menyusul'),
          ),
          if (interview.candidateInstructions != null) ...[
            SizedBox(height: 6.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                interview.candidateInstructions!,
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  height: 1.4,
                  color: AppColors.foreground.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          if (interview.needsResponse) ...[
            const Divider(height: 22, color: AppColors.border),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => controller.respond(interview, 'accepted'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                    ),
                    child: Text(
                      'Terima',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => controller.respond(interview, 'declined'),
                    // Red on the theme's blue `accent` fill only reaches
                    // 4.19:1, so a destructive button brings its own tint.
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      foregroundColor: AppColors.destructive,
                      backgroundColor: AppColors.destructiveSoft,
                    ),
                    child: Text(
                      'Tolak',
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  RescheduleSheet.show(context, controller, interview),
              icon: Icon(Iconsax.refresh_2, size: 14.sp),
              label: Text(
                'Minta jadwal ulang',
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _scheduleLabel() {
    final parsed = DateTime.tryParse(interview.scheduledAt ?? '')?.toLocal();
    if (parsed == null) return 'Jadwal belum ditentukan';

    final date = '${parsed.day.toString().padLeft(2, '0')}/'
        '${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    final time = '${parsed.hour.toString().padLeft(2, '0')}:'
        '${parsed.minute.toString().padLeft(2, '0')}';

    final duration = interview.durationMinutes == null
        ? ''
        : ' · ${interview.durationMinutes} menit';

    return '$date, $time${interview.timezone == null ? '' : ' ${interview.timezone}'}$duration';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.interview});

  final InterviewModel interview;

  @override
  Widget build(BuildContext context) {
    final (label, color) = interview.isConfirmed
        ? ('Terkonfirmasi', AppColors.success)
        : interview.needsResponse
            ? ('Perlu jawaban', AppColors.warning)
            : (Formatters.status(interview.status), AppColors.mutedForeground);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(icon, size: 14.sp, color: AppColors.mutedForeground),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                height: 1.35,
                color: AppColors.foreground.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
