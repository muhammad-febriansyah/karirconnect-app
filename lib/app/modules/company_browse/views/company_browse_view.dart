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
import '../../../data/models/company_model.dart';
import '../controllers/company_browse_controller.dart';

/// `GET api/v1/companies` — public, so this screen works signed out.
class CompanyBrowseView extends GetView<CompanyBrowseController> {
  const CompanyBrowseView({super.key});

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
            GradientHeaderBar(
              title: 'Perusahaan',
              bottom: HeaderSearchField(
                controller: controller.searchController,
                hintText: 'Cari perusahaan',
              ),
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
                  () => _VerifiedChip(
                    active: controller.verifiedOnly.value,
                    onTap: controller.toggleVerifiedOnly,
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

                  final companies = controller.companies.toList();
                  if (companies.isEmpty) {
                    return ListView(
                      padding: gutter,
                      children: const [
                        EmptyState(
                          icon: Iconsax.buildings_2,
                          message: 'Tidak ada perusahaan yang cocok.',
                        ),
                      ],
                    );
                  }

                  final loadingMore = controller.isLoadingMore.value;

                  return ListView.separated(
                    controller: controller.scrollController,
                    padding: gutter,
                    itemCount: companies.length + (loadingMore ? 1 : 0),
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) {
                      if (index >= companies.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }

                      final company = companies[index];

                      return _CompanyTile(
                        company: company,
                        onTap: () => controller.openCompany(company),
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

class _VerifiedChip extends StatelessWidget {
  const _VerifiedChip({required this.active, required this.onTap});

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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.verify5,
                size: 14.sp,
                color: active ? Colors.white : AppColors.primary,
              ),
              SizedBox(width: 6.w),
              Text(
                'Terverifikasi saja',
                style: GoogleFonts.poppins(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompanyTile extends StatelessWidget {
  const _CompanyTile({required this.company, required this.onTap});

  final CompanyModel company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (company.industry != null) company.industry!,
      if (company.city != null) company.city!,
      if (company.size != null) company.size!,
    ].join(' · ');

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              _Logo(company: company),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            company.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandNavy,
                            ),
                          ),
                        ),
                        if (company.isVerified) ...[
                          SizedBox(width: 4.w),
                          Icon(
                            Iconsax.verify5,
                            size: 13.sp,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 10.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  '${company.openJobsCount ?? 0} loker',
                  style: GoogleFonts.poppins(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentForeground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.company});

  final CompanyModel company;

  @override
  Widget build(BuildContext context) {
    final logoUrl = company.logoUrl;

    return Container(
      width: 44.w,
      height: 44.w,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: logoUrl == null || logoUrl.isEmpty
          ? _initials()
          : Image.network(
              logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _initials(),
            ),
    );
  }

  Widget _initials() => Text(
        Formatters.initials(company.name),
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.brandNavy,
        ),
      );
}
