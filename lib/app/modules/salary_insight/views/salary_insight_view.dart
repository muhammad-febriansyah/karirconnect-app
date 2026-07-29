import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/salary_insight_model.dart';
import '../controllers/salary_insight_controller.dart';

/// `GET api/v1/salary-insights` — public, so this screen works signed out.
class SalaryInsightView extends GetView<SalaryInsightController> {
  const SalaryInsightView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insight Gaji'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: controller.load,
        color: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 28.h),
          children: [
            const _Filters(),
            SizedBox(height: 16.h),
            Obx(() {
              if (controller.isLoading.value) return const SectionLoader();

              final error = controller.errorMessage.value;
              if (error != null) {
                return ErrorState(message: error, onRetry: controller.load);
              }

              final data = controller.data.value;
              if (!data.aggregate.hasData) {
                return const EmptyState(
                  icon: Iconsax.chart_2,
                  message:
                      'Belum ada data gaji untuk filter ini. Coba pilih kategori lain.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AggregateCard(aggregate: data.aggregate),
                  if (data.curatedInsights.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    _SectionTitle(
                      title: 'Kisaran per posisi',
                      subtitle: 'Data kurasi dari riset pasar.',
                    ),
                    SizedBox(height: 10.h),
                    ...data.curatedInsights.map(
                      (insight) => _CuratedTile(insight: insight),
                    ),
                  ],
                  if (data.topCompanies.isNotEmpty) ...[
                    SizedBox(height: 20.h),
                    _SectionTitle(
                      title: 'Perusahaan dengan sampel terbanyak',
                      subtitle: 'Median gaji dari lowongan yang mereka pasang.',
                    ),
                    SizedBox(height: 10.h),
                    ...data.topCompanies.map(
                      (company) => _CompanyTile(company: company),
                    ),
                  ],
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Filters extends GetView<SalaryInsightController> {
  const _Filters();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 32.h,
          child: Obx(() {
            final categories =
                controller.data.value.popularCategories.take(10).toList();
            final activeId = controller.activeCategoryId.value;

            if (categories.isEmpty) return const SizedBox.shrink();

            return ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length + 1,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) {
                  final category = index == 0 ? null : categories[index - 1];

                  return _Chip(
                    label: category == null
                        ? 'Semua'
                        : '${category.name} (${category.count})',
                    active: activeId == category?.id,
                    onTap: () => controller.selectCategory(category?.id),
                  );
                },
              ),
            );
          }),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: 32.h,
          child: Obx(() {
            final levels = controller.meta.value.experienceLevels;
            final active = controller.activeExperience.value;

            if (levels.isEmpty) return const SizedBox.shrink();

            return ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: levels.length,
                separatorBuilder: (_, _) => SizedBox(width: 8.w),
                itemBuilder: (context, index) => _Chip(
                  label: levels[index].label,
                  active: active == levels[index].value,
                  onTap: () => controller.selectExperience(levels[index].value),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
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
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AggregateCard extends StatelessWidget {
  const _AggregateCard({required this.aggregate});

  final SalaryAggregate aggregate;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Median gaji',
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            Formatters.rupiahShort(aggregate.p50),
            style: GoogleFonts.poppins(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              _Stat(label: 'P25', value: Formatters.rupiahShort(aggregate.p25)),
              _Stat(label: 'P75', value: Formatters.rupiahShort(aggregate.p75)),
              _Stat(
                label: 'Rata-rata',
                value: Formatters.rupiahShort(aggregate.average),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Icon(
                Iconsax.info_circle,
                size: 13.sp,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  // Sample size is what tells the user how much to trust this.
                  '${aggregate.sampleSize} sampel '
                  '(${aggregate.postingCount} lowongan, '
                  '${aggregate.submissionCount} laporan pengguna)',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value.isEmpty ? '-' : value,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: AppColors.mutedForeground,
            ),
          ),
      ],
    );
  }
}

class _CuratedTile extends StatelessWidget {
  const _CuratedTile({required this.insight});

  final CuratedSalaryInsight insight;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (insight.city != null) insight.city!,
      if (insight.experienceLevel != null)
        Formatters.status(insight.experienceLevel),
    ].join(' · ');

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
          Text(
            insight.jobTitle,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.brandNavy,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${Formatters.rupiahShort(insight.minSalary)} – '
                  '${Formatters.rupiahShort(insight.maxSalary)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ),
              Text(
                Formatters.rupiahShort(insight.medianSalary),
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company});

  final SalaryCompany company;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Text(
              Formatters.initials(company.companyName),
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandNavy,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.companyName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
                Text(
                  '${company.count} lowongan bergaji',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.rupiahShort(company.p50),
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
