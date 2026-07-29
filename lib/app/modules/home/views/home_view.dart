import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/states.dart';
import '../controllers/home_controller.dart';
import 'widgets/company_card.dart';
import 'widgets/home_header.dart';
import 'widgets/quick_menu.dart';

/// Beranda: blue header with the location picker and search, a "Lowongan
/// Pilihan" rail, then the category-filtered "Lowongan Terbaru" list.
///
/// Composed from the public browsing endpoints because the backend has no
/// single `api/v1/home` route.
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: RefreshIndicator(
          onRefresh: controller.load,
          color: AppColors.primary,
          // No `physics:` here — an explicit one would shadow
          // AppScrollBehavior and lose the bounce on this screen only.
          child: CustomScrollView(
            slivers: [
              // Header and quick menu stay in one sliver: QuickMenu carries
              // the tail of the header gradient behind its rounded top, so the
              // two only read as a single block while they lay out together.
              const SliverToBoxAdapter(
                child: Column(
                  children: [HomeHeader(), QuickMenu()],
                ),
              ),
              const _SuggestedSection(),
              const _RecentSection(),
              const _CompaniesSection(),
              const _AiCvBanner(),
              const _LoginCta(),
              SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl.h)),
            ],
          ),
        ),
      ),
    );
  }
}

/// How much the user has scaled system text, clamped to what a fixed-height
/// horizontal rail can absorb before it crowds out the rest of the screen.
double _textScale(BuildContext context) =>
    MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4);

class _SuggestedSection extends GetView<HomeController> {
  const _SuggestedSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final jobs = controller.suggestedJobs.toList();
        final saved = controller.savedSlugs;

        if (controller.isLoading.value) {
          return const SectionLoader();
        }

        if (jobs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.section.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
              child: SectionHeader(
                title: 'Lowongan Pilihan',
                onSeeAll: controller.openJobsTab,
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            SizedBox(
              // Tall enough for a two-line title over the single-line chip row;
              // JobCard pins its footer to the bottom of whatever is left.
              //
              // A horizontal ListView hands its children a tight height, so
              // this has to grow with the system text size or the card
              // overflows instead of reflowing. Capped at 1.4 — past that the
              // rail would eat the whole viewport.
              height: 192.h * _textScale(context),
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
                  itemCount: jobs.length,
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
                  itemBuilder: (context, index) {
                    final job = jobs[index];

                    return JobCard(
                      job: job,
                      width: 268.w,
                      isSaved: saved.contains(job.slug),
                      onTap: () => controller.openJob(job),
                      onSave: () => controller.toggleSave(job),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _RecentSection extends GetView<HomeController> {
  const _RecentSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.section.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
            child: SectionHeader(
              title: 'Lowongan Terbaru',
              onSeeAll: controller.openJobsTab,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          const _CategoryChips(),
          SizedBox(height: AppSpacing.lg.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
            child: Obx(() {
              if (controller.isLoading.value ||
                  controller.isRecentLoading.value) {
                return const SectionLoader();
              }

              final error = controller.errorMessage.value;
              if (error != null) {
                return ErrorState(message: error, onRetry: controller.load);
              }

              final jobs = controller.recentJobs.toList();
              if (jobs.isEmpty) {
                return const EmptyState(
                  message: 'Belum ada lowongan yang cocok dengan filter ini.',
                );
              }

              final saved = controller.savedSlugs;

              return Column(
                children: jobs
                    .map(
                      (job) => Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                        child: JobCard(
                          job: job,
                          isSaved: saved.contains(job.slug),
                          onTap: () => controller.openJob(job),
                          onSave: () => controller.toggleSave(job),
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends GetView<HomeController> {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Both observables are read here rather than inside itemBuilder, which
      // runs outside Obx's tracking scope and would register no dependency.
      final categories = controller.meta.value.jobCategories.take(8).toList();
      final activeId = controller.activeCategoryId.value;

      if (categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 36.h,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
            // Index 0 is the "Semua" tab, which clears the category filter.
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm.w),
            itemBuilder: (context, index) {
              final category = index == 0 ? null : categories[index - 1];
              final active = activeId == category?.id;

              // Selection is a fill swap, not an outline swap: an inactive
              // chip is the same tonal surface every other resting element
              // uses, so the active one is the only thing that stands out.
              return Material(
                color: active ? AppColors.primary : AppColors.surfaceSoft,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: () => controller.selectCategory(category?.id),
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
                    child: Center(
                      child: Text(
                        category?.name ?? 'Semua',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: active
                              ? Colors.white
                              : AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

class _CompaniesSection extends GetView<HomeController> {
  const _CompaniesSection();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Obx(() {
        final companies = controller.companies.toList();
        if (companies.isEmpty) return const SizedBox.shrink();

        // No tinted band around this section any more. One grey block in an
        // otherwise white feed read as an unexplained interruption; the cards
        // already carry the tint, so the section needs nothing of its own.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: AppSpacing.section.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
              child: const SectionHeader(
                title: 'Perusahaan terbaik',
                subtitle: 'Perusahaan terverifikasi yang sedang membuka posisi.',
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            SizedBox(
              height: 156.h * _textScale(context),
              child: ScrollConfiguration(
                behavior:
                    ScrollConfiguration.of(context).copyWith(scrollbars: false),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
                  itemCount: companies.length,
                  separatorBuilder: (_, _) => SizedBox(width: AppSpacing.md.w),
                  itemBuilder: (context, index) => CompanyCard(
                    company: companies[index],
                    onTap: () => controller.openCompany(companies[index]),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Mirrors the landing's "Analisis CV-mu dengan Kecerdasan Buatan" block.
class _AiCvBanner extends GetView<HomeController> {
  const _AiCvBanner();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.section.h,
          AppSpacing.gutter.w,
          0,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Wrapped so the pill hugs its label — a bare Container with an
              // `alignment` would expand to the banner's full width.
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Iconsax.magicpen,
                        size: 13.sp,
                        color: AppColors.brandCyan,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'AI CV Review',
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              Text(
                'Analisis CV-mu dengan\nKecerdasan Buatan',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              Text(
                'Dapatkan skor dan saran perbaikan instan sebelum melamar.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  height: 1.5,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              ElevatedButton(
                onPressed: controller.openAiTab,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brandNavy,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl.w,
                    vertical: AppSpacing.md.h,
                  ),
                ),
                child: Text(
                  'Coba Sekarang',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
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

class _LoginCta extends GetView<HomeController> {
  const _LoginCta();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.lg.h,
          AppSpacing.gutter.w,
          0,
        ),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl.w),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            children: [
              Text(
                'Sudah punya akun KarirConnect?',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
              SizedBox(height: AppSpacing.xs.h),
              Text(
                'Masuk untuk melamar, menyimpan lowongan, dan melacak lamaranmu.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  height: 1.5,
                  color: AppColors.mutedForeground,
                ),
              ),
              SizedBox(height: AppSpacing.lg.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: controller.goToRegister,
                      child: const Text('Daftar'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: controller.requireLogin,
                      child: const Text('Masuk'),
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
