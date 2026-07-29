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
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/job_detail_model.dart';
import '../controllers/job_detail_controller.dart';
import 'widgets/apply_sheet.dart';

/// `GET api/v1/jobs/{slug}` — public, so a guest sees the whole posting and is
/// only sent to login when they try to save or apply.
///
/// The identity block (logo, title, company) sits in a **fixed** header rather
/// than scrolling away. The body here is long — description, responsibilities,
/// qualifications, benefits — and a reader deep in the qualifications should
/// still be able to see which posting they are reading and reach Back.
class JobDetailView extends GetView<JobDetailController> {
  const JobDetailView({super.key});

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
            const _DetailHeader(),
            Expanded(child: const _DetailBody()),
          ],
        ),
        bottomNavigationBar: const _ApplyBar(),
      ),
    );
  }
}

class _DetailHeader extends GetView<JobDetailController> {
  const _DetailHeader();

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleButton(
                icon: Iconsax.arrow_left_2,
                label: 'Kembali',
                onTap: Get.back,
              ),
              const Spacer(),
              Obx(
                () => _CircleButton(
                  icon: controller.isSaved.value
                      ? Iconsax.archive_tick
                      : Iconsax.archive_add,
                  label: controller.isSaved.value
                      ? 'Hapus dari simpanan'
                      : 'Simpan lowongan',
                  onTap: controller.toggleSave,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl.h),
          Obx(() {
            final detail = controller.detail.value;

            // Same two-line shape while loading, so the header does not jump
            // in height once the posting arrives.
            if (detail == null) {
              return Text(
                controller.isLoading.value
                    ? 'Memuat lowongan…'
                    : 'Detail lowongan',
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              );
            }

            return _Identity(detail: detail);
          }),
        ],
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.detail});

  final JobDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final job = detail.job;
    final logoUrl = job.company.logoUrl;

    final initials = Text(
      Formatters.initials(job.company.name),
      style: GoogleFonts.poppins(
        fontSize: 18.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.brandNavy,
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54.w,
          height: 54.w,
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: logoUrl == null || logoUrl.isEmpty
              ? initials
              : Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => initials,
                ),
        ),
        SizedBox(width: AppSpacing.lg.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      job.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5.sp,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  if (job.company.isVerified) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Iconsax.verify5,
                      size: 13.sp,
                      color: AppColors.brandCyan,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Translucent white circle, the same treatment Beranda's notification bell
/// uses. Sized to the 44pt minimum rather than to the glyph.
class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Icon(icon, size: 20.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends GetView<JobDetailController> {
  const _DetailBody();

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
        return const EmptyState(message: 'Lowongan tidak ditemukan.');
      }

      return ListView(
        padding: EdgeInsets.zero,
        children: [
          // The sheet's rounded top rides over the header's gradient, the same
          // join Beranda and Lowongan use.
          HeaderSheet(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SalaryBlock(detail: detail),
                SizedBox(height: AppSpacing.lg.h),
                _Facts(detail: detail),
                if (detail.matchScore != null) ...[
                  SizedBox(height: AppSpacing.md.h),
                  _MatchBanner(score: detail.matchScore!),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter.w,
              0,
              AppSpacing.gutter.w,
              AppSpacing.xl.h,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Section(title: 'Deskripsi', body: detail.description),
                _Section(
                  title: 'Tanggung jawab',
                  body: detail.responsibilities,
                ),
                _Section(title: 'Kualifikasi', body: detail.requirements),
                _Section(title: 'Benefit', body: detail.benefits),
                _Section(
                  title: 'Tentang perusahaan',
                  body: detail.companyAbout,
                ),
                if (detail.job.skills.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.section.h),
                  _Heading(text: 'Keahlian'),
                  SizedBox(height: AppSpacing.md.h),
                  Wrap(
                    spacing: AppSpacing.sm.w,
                    runSpacing: AppSpacing.sm.h,
                    children: detail.job.skills
                        .map((skill) => _SkillChip(label: skill))
                        .toList(),
                  ),
                ],
                if (detail.similarJobs.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.section.h),
                  const SectionHeader(title: 'Lowongan serupa'),
                  SizedBox(height: AppSpacing.md.h),
                  ...detail.similarJobs.map(
                    (job) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: Obx(
                        () => JobCard(
                          job: job,
                          isSaved:
                              controller.savedSimilarSlugs.contains(job.slug),
                          onTap: () => controller.openSimilar(job),
                          onSave: () => controller.toggleSaveSimilar(job),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      );
    });
  }
}

/// Salary leads the body: it is the figure a jobseeker scans for first, and
/// the deadline sits under it because the two decide whether to read on.
class _SalaryBlock extends StatelessWidget {
  const _SalaryBlock({required this.detail});

  final JobDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final job = detail.job;
    final deadline = job.applicationDeadline;
    final daysLeft = Formatters.daysUntil(deadline);

    // Inside a week is worth flagging; already past is worth flagging harder.
    final urgent = daysLeft != null && daysLeft <= 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Formatters.salaryRange(
            isVisible: job.isSalaryVisible,
            min: job.salaryMin,
            max: job.salaryMax,
          ),
          style: GoogleFonts.poppins(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          'Estimasi gaji per bulan',
          style: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            color: AppColors.mutedForeground,
          ),
        ),
        if (deadline != null && deadline.isNotEmpty) ...[
          SizedBox(height: AppSpacing.md.h),
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: 14.sp,
                color: urgent
                    ? AppColors.accentAmberForeground
                    : AppColors.mutedForeground,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  daysLeft != null && daysLeft < 0
                      ? 'Pendaftaran ditutup ${Formatters.date(deadline)}'
                      : 'Lamar sebelum ${Formatters.date(deadline)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: urgent ? FontWeight.w600 : FontWeight.w400,
                    color: urgent
                        ? AppColors.accentAmberForeground
                        : AppColors.mutedForeground,
                  ),
                ),
              ),
            ],
          ),
        ],
        _Counters(detail: detail),
      ],
    );
  }
}

/// `views_count` and `applications_count` come down on every detail response
/// but had no surface until now. They are the posting's social proof, so they
/// sit right under the salary.
class _Counters extends StatelessWidget {
  const _Counters({required this.detail});

  final JobDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final views = detail.viewsCount;
    final applicants = detail.applicationsCount;

    if (views == null && applicants == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md.h),
      child: Row(
        children: [
          if (applicants != null)
            _Counter(
              icon: Iconsax.profile_2user,
              label: '${Formatters.count(applicants)} pelamar',
            ),
          if (applicants != null && views != null)
            SizedBox(width: AppSpacing.sm.w),
          if (views != null)
            _Counter(
              icon: Iconsax.eye,
              label: '${Formatters.count(views)} dilihat',
            ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: AppColors.mutedForeground),
          SizedBox(width: 6.w),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}

class _Facts extends StatelessWidget {
  const _Facts({required this.detail});

  final JobDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final job = detail.job;

    // Salary is deliberately absent — it is the hero above this card.
    final rows = <({IconData icon, String label, String value})>[
      if (job.employmentType != null)
        (
          icon: Iconsax.briefcase,
          label: 'Tipe',
          value: Formatters.status(job.employmentType),
        ),
      if (job.workArrangement != null)
        (
          icon: Iconsax.global,
          label: 'Model kerja',
          value: Formatters.status(job.workArrangement),
        ),
      (
        icon: Iconsax.location,
        label: 'Lokasi',
        value: [
          if (job.city != null) job.city!,
          if (detail.province != null) detail.province!,
        ].join(', ').ifEmpty('Lokasi fleksibel'),
      ),
      if (job.experienceLevel != null)
        (
          icon: Iconsax.chart_2,
          label: 'Pengalaman',
          value: Formatters.status(job.experienceLevel),
        ),
      if (detail.minEducation != null)
        (
          icon: Iconsax.teacher,
          label: 'Pendidikan min.',
          value: Formatters.status(detail.minEducation),
        ),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
                child: Row(
                  children: [
                    Icon(
                      row.icon,
                      size: 16.sp,
                      color: AppColors.mutedForeground,
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Text(
                      row.label,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: Text(
                        row.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MatchBanner extends StatelessWidget {
  const _MatchBanner({required this.score});

  final num score;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.md.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.magic_star,
            size: 17.sp,
            color: AppColors.accentForeground,
          ),
          SizedBox(width: AppSpacing.sm.w),
          Expanded(
            child: Text(
              'Cocok ${score.round()}% dengan profilmu',
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.accentForeground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.brandNavy,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: 7.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.accentForeground,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    // The web editors emit a mix of HTML and markdown; rendering raw shows
    // both tags and asterisks.
    final text = Formatters.richTextToPlain(body);
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.section.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Heading(text: title),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              height: 1.65,
              color: AppColors.foreground.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplyBar extends GetView<JobDetailController> {
  const _ApplyBar();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value || controller.detail.value == null) {
        return const SizedBox.shrink();
      }

      final applied = controller.hasApplied.value;

      // Tonal fill rather than a top border: the bar separates from the white
      // page the same way every card does.
      return Container(
        color: AppColors.surfaceSoft,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter.w,
              AppSpacing.md.h,
              AppSpacing.gutter.w,
              AppSpacing.md.h,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    applied ? null : () => ApplySheet.show(context, controller),
                style: ElevatedButton.styleFrom(
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.mutedForeground,
                ),
                child: Text(applied ? 'Sudah dilamar' : 'Lamar sekarang'),
              ),
            ),
          ),
        ),
      );
    });
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
