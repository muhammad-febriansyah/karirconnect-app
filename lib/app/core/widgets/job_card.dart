import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../data/models/job_model.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../values/app_colors.dart';

/// Job listing card: logo + title/company + bookmark, location line, a single
/// row of attribute chips, then a salary / posted-time footer.
///
/// Separated from the page by a tonal fill rather than a border or a shadow.
///
/// The chip row is deliberately **one line that never wraps**. Postings carry
/// between one and four attributes, and a `Wrap` gave every card a different
/// height — that raggedness is what made a list of these read as unordered.
///
/// Pass [width] to use it inside a horizontal rail; leave it null to fill the
/// parent in a vertical list. In rail mode the card stretches to the rail
/// height and pins its footer to the bottom, so every tile lines up.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onSave,
    this.isSaved = false,
    this.width,
  });

  final JobModel job;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaved;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final isRail = width != null;

    final card = Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: isRail ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _TitleRow(job: job, isSaved: isSaved, onSave: onSave),
              SizedBox(height: AppSpacing.md.h),
              Row(
                children: [
                  Icon(
                    Iconsax.location,
                    size: 14.sp,
                    color: AppColors.mutedForeground,
                  ),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      job.city ?? 'Lokasi fleksibel',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.md.h),
              _AttributeChips(job: job),
              // Rail tiles get a tight height from the ListView, so the spacer
              // pushes every footer onto the same baseline. In a vertical list
              // the height is unbounded and a Spacer would throw, hence the
              // fixed gap instead.
              if (isRail)
                const Spacer()
              else
                SizedBox(height: AppSpacing.lg.h),
              _Footer(job: job),
            ],
          ),
        ),
      ),
    );

    return isRail ? SizedBox(width: width, child: card) : card;
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.job,
    required this.isSaved,
    required this.onSave,
  });

  final JobModel job;
  final bool isSaved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanyLogo(job: job),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Flexible(
                    child: Text(
                      job.company.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                  if (job.company.isVerified) ...[
                    SizedBox(width: 4.w),
                    Icon(
                      Iconsax.verify5,
                      size: 12.sp,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        // 44x44 hit area around a 19sp glyph, per the platform minimum.
        InkResponse(
          onTap: onSave,
          radius: 22.r,
          child: Semantics(
            button: true,
            label: isSaved ? 'Hapus dari simpanan' : 'Simpan lowongan',
            child: SizedBox(
              width: 44.w,
              height: 44.w,
              child: Icon(
                isSaved ? Iconsax.archive_tick : Iconsax.archive_add,
                size: 19.sp,
                color: isSaved ? AppColors.primary : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final logoUrl = job.company.logoUrl;

    // White on the card's tint: the logo tile reads as inset with no stroke.
    return Container(
      width: 46.w,
      height: 46.w,
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logoUrl == null || logoUrl.isEmpty
          ? _initials()
          : Image.network(
              logoUrl,
              fit: BoxFit.contain,
              // A broken logo URL must not blank out the card.
              errorBuilder: (_, _, _) => _initials(),
            ),
    );
  }

  Widget _initials() => Text(
        Formatters.initials(
          job.company.name == '-' ? job.title : job.company.name,
        ),
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.brandNavy,
        ),
      );
}

/// "Butuh Cepat", then employment type / work arrangement / experience level —
/// each one omitted when the posting leaves it null.
///
/// Laid out as a non-wrapping `Row`: every chip is `Flexible`, so a long label
/// ellipsises inside its own pill instead of pushing the row onto a second
/// line. That keeps the card a fixed height no matter how many attributes a
/// posting carries.
///
/// How many chips fit depends on the card's width, and Flexible shrinks its
/// children *proportionally* — squeezing in a third chip on a narrow rail tile
/// truncates all three rather than dropping one. So the count is chosen from
/// the measured width and the surplus attributes are dropped whole.
class _AttributeChips extends StatelessWidget {
  const _AttributeChips({required this.job});

  /// Below this the row only has room for two chips at their natural width.
  static const double _threeChipWidth = 250;

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final labels = <(String, bool)>[
      if (job.isFeatured) ('Butuh Cepat', true),
      if (job.employmentType != null)
        (Formatters.status(job.employmentType), false),
      if (job.workArrangement != null)
        (Formatters.status(job.workArrangement), false),
      if (job.experienceLevel != null)
        (Formatters.status(job.experienceLevel), false),
    ];

    if (labels.isEmpty) return SizedBox(height: 26.h);

    return LayoutBuilder(
      builder: (context, constraints) {
        final shown = labels
            .take(constraints.maxWidth >= _threeChipWidth.w ? 3 : 2)
            .toList();

        return Row(
          children: [
            for (final (index, (label, highlighted)) in shown.indexed) ...[
              if (index > 0) SizedBox(width: 6.w),
              Flexible(child: _Chip(label: label, highlighted: highlighted)),
            ],
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.highlighted = false});

  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        // Plain chips invert to white on the card's tint; the featured one
        // keeps the warm accent so it still pulls the eye first.
        color: highlighted
            ? AppColors.accentAmberSoft
            : AppColors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 11.sp,
          fontWeight: FontWeight.w500,
          color: highlighted
              ? AppColors.accentAmberForeground
              : AppColors.mutedForeground,
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.job});

  final JobModel job;

  @override
  Widget build(BuildContext context) {
    // Salary leads: it is the one figure a jobseeker scans for, so it takes
    // the strong left slot and the posted time drops to a muted right rail.
    //
    // JobResource carries no applicant count — the web landing gets that from
    // HomeService, which has no API equivalent.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            Formatters.salaryRange(
              isVisible: job.isSalaryVisible,
              min: job.salaryMin,
              max: job.salaryMax,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: -0.2,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.sm.w),
        Text(
          job.publishedAt == null
              ? 'Baru saja'
              : Formatters.relative(job.publishedAt),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: AppColors.mutedForeground,
          ),
        ),
      ],
    );
  }
}
