import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/company_detail_model.dart';
import '../controllers/company_detail_controller.dart';

/// `GET api/v1/companies/{slug}` plus its jobs and reviews. All public.
class CompanyDetailView extends GetView<CompanyDetailController> {
  const CompanyDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil Perusahaan'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        final detail = controller.detail.value;
        if (detail == null) {
          return const EmptyState(message: 'Perusahaan tidak ditemukan.');
        }

        final jobs = controller.jobs.toList();
        final reviews = controller.reviews.toList();
        final saved = controller.savedSlugs;

        return ListView(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 24.h),
          children: [
            _Header(detail: detail),
            SizedBox(height: 14.h),
            _Facts(detail: detail),
            if (detail.badges.isNotEmpty) ...[
              SizedBox(height: 14.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: detail.badges
                    .map(
                      (badge) => Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          badge.name,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accentForeground,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            _Section(title: 'Tentang', body: detail.about),
            _Section(title: 'Budaya kerja', body: detail.culture),
            _Section(title: 'Benefit', body: detail.benefits),
            if (detail.offices.isNotEmpty) ...[
              SizedBox(height: 20.h),
              _Title('Kantor'),
              SizedBox(height: 8.h),
              ...detail.offices.map((office) => _OfficeRow(office: office)),
            ],
            if (jobs.isNotEmpty) ...[
              SizedBox(height: 22.h),
              _Title('Lowongan aktif (${jobs.length})'),
              SizedBox(height: 10.h),
              ...jobs.map(
                (job) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: JobCard(
                    job: job,
                    isSaved: saved.contains(job.slug),
                    onTap: () => controller.openJob(job),
                    onSave: () => controller.toggleSave(job),
                  ),
                ),
              ),
            ],
            if (reviews.isNotEmpty) ...[
              SizedBox(height: 22.h),
              _ReviewHeader(
                total: controller.reviewTotal.value,
                avgRating: controller.avgRating.value,
              ),
              SizedBox(height: 10.h),
              ...reviews.map((review) => _ReviewCard(review: review)),
            ],
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final CompanyDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final company = detail.company;
    final logoUrl = company.logoUrl;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 58.w,
          height: 58.w,
          decoration: BoxDecoration(
            color: AppColors.muted,
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
          clipBehavior: Clip.antiAlias,
          alignment: Alignment.center,
          child: logoUrl == null || logoUrl.isEmpty
              ? _initials(company.name)
              : Image.network(
                  logoUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => _initials(company.name),
                ),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      company.name,
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandNavy,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  if (company.isVerified) ...[
                    SizedBox(width: 5.w),
                    Icon(
                      Iconsax.verify5,
                      size: 15.sp,
                      color: AppColors.primary,
                    ),
                  ],
                ],
              ),
              if (company.tagline != null) ...[
                SizedBox(height: 3.h),
                Text(
                  company.tagline!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    height: 1.4,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static Widget _initials(String name) => Text(
        Formatters.initials(name),
        style: GoogleFonts.poppins(
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.brandNavy,
        ),
      );
}

class _Facts extends StatelessWidget {
  const _Facts({required this.detail});

  final CompanyDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final company = detail.company;

    final rows = <({IconData icon, String label, String value})>[
      if (company.industry != null)
        (icon: Iconsax.buildings_2, label: 'Industri', value: company.industry!),
      if (company.size != null)
        (icon: Iconsax.profile_2user, label: 'Ukuran', value: company.size!),
      if (company.city != null || detail.province != null)
        (
          icon: Iconsax.location,
          label: 'Lokasi',
          value: [
            if (company.city != null) company.city!,
            if (detail.province != null) detail.province!,
          ].join(', '),
        ),
      if (detail.foundedYear != null)
        (
          icon: Iconsax.calendar_2,
          label: 'Berdiri',
          value: '${detail.foundedYear}',
        ),
      if (detail.website != null)
        (icon: Iconsax.global, label: 'Website', value: detail.website!),
    ];

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Row(
                  children: [
                    Icon(
                      row.icon,
                      size: 15.sp,
                      color: AppColors.mutedForeground,
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      row.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        row.value,
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
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14.sp,
        fontWeight: FontWeight.w700,
        color: AppColors.brandNavy,
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
    final text = Formatters.richTextToPlain(body);
    if (text.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 18.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Title(title),
          SizedBox(height: 6.h),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12.5.sp,
              height: 1.55,
              color: AppColors.foreground.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfficeRow extends StatelessWidget {
  const _OfficeRow({required this.office});

  final CompanyOffice office;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(
              office.isHeadquarter ? Iconsax.building_4 : Iconsax.location,
              size: 15.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    office.label ?? 'Kantor',
                    if (office.isHeadquarter) '(Pusat)',
                  ].join(' '),
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
                if (office.address != null)
                  Text(
                    office.address!,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      height: 1.4,
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

class _ReviewHeader extends StatelessWidget {
  const _ReviewHeader({required this.total, required this.avgRating});

  final int total;
  final double avgRating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Title('Ulasan karyawan'),
        const Spacer(),
        Icon(Iconsax.star1, size: 15.sp, color: const Color(0xFFFFB900)),
        SizedBox(width: 5.w),
        Text(
          '${avgRating.toStringAsFixed(1)} · $total ulasan',
          style: GoogleFonts.poppins(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.brandNavy,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final CompanyReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
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
                  review.title ?? 'Ulasan',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Row(
                children: [
                  Icon(
                    Iconsax.star1,
                    size: 13.sp,
                    color: const Color(0xFFFFB900),
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    '${review.rating}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            [
              review.displayName,
              if (review.jobTitle != null) review.jobTitle!,
              Formatters.relative(review.createdAt),
            ].where((part) => part.isNotEmpty).join(' · '),
            style: GoogleFonts.poppins(
              fontSize: 10.5.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          if (review.pros != null && review.pros!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            _Aspect(
              icon: Iconsax.like_1,
              color: AppColors.success,
              text: review.pros!,
            ),
          ],
          if (review.cons != null && review.cons!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            _Aspect(
              icon: Iconsax.dislike,
              color: AppColors.destructive,
              text: review.cons!,
            ),
          ],
          if (review.responseBody != null &&
              review.responseBody!.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balasan perusahaan',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.brandNavy,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    review.responseBody!,
                    style: GoogleFonts.poppins(
                      fontSize: 11.sp,
                      height: 1.45,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Aspect extends StatelessWidget {
  const _Aspect({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(icon, size: 13.sp, color: color),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              height: 1.45,
              color: AppColors.foreground.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}
