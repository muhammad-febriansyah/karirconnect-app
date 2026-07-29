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
import '../../../core/widgets/states.dart';
import '../controllers/jobs_controller.dart';

/// Lowongan: the same header shell as Beranda — gradient block with a search
/// field and an amber action button, then the white sheet carrying the filter
/// chips — over an infinitely scrolling job list.
///
/// The header and chip row sit *outside* the scroll view rather than in
/// slivers. Beranda's header scrolls away because its feed is one page; this
/// list paginates, and filters that scroll off after a hundred results are
/// filters the user cannot get back to without scrolling to the top.
class JobsView extends GetView<JobsController> {
  const JobsView({super.key});

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
            const _JobsHeader(),
            const _FilterBar(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.primary,
                child: const _JobList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JobsHeader extends GetView<JobsController> {
  const _JobsHeader();

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lowongan',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.4,
            ),
          ),
          SizedBox(height: 2.h),
          Obx(() {
            // Reads `total`, not `jobs.length` — the latter only counts the
            // pages fetched so far, so it would climb as the user scrolls.
            final loading = controller.isLoading.value;
            final total = controller.total.value;

            return Text(
              loading
                  ? 'Memuat lowongan…'
                  : '${Formatters.count(total)} lowongan tersedia',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            );
          }),
          SizedBox(height: AppSpacing.xl.h),
          Row(
            children: [
              Expanded(
                child: HeaderSearchField(
                  controller: controller.searchController,
                  hintText: 'Cari posisi, skill, perusahaan',
                ),
              ),
              SizedBox(width: AppSpacing.md.w),
              const _SortButton(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sort lives on the amber button so the header matches Beranda's shape. It
/// keeps the popup it always had — `PopupMenuButton` owns the gesture, which
/// is why [HeaderActionButton] takes no `onTap` here.
class _SortButton extends GetView<JobsController> {
  const _SortButton();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final active = controller.activeSort.value;

      return PopupMenuButton<String>(
        onSelected: controller.selectSort,
        position: PopupMenuPosition.under,
        tooltip: 'Urutkan',
        color: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
        itemBuilder: (context) => JobsController.sortOptions
            .map(
              (option) => PopupMenuItem<String>(
                value: option.value,
                child: Text(
                  option.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: option.value == active
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: option.value == active
                        ? AppColors.primary
                        : AppColors.foreground,
                  ),
                ),
              ),
            )
            .toList(),
        child: HeaderActionButton(
          icon: Iconsax.sort,
          showDot: active != JobsController.sortOptions.first.value,
        ),
      );
    });
  }
}

class _FilterBar extends GetView<JobsController> {
  const _FilterBar();

  @override
  Widget build(BuildContext context) {
    return HeaderSheet(
      // The bottom padding is load-bearing. The chip row is pinned while the
      // list scrolls under it, and with no padding the list's top edge butts
      // straight against the chips — a card gets sliced flush at the chip
      // baseline and reads as bleeding through.
      padding: EdgeInsets.only(top: AppSpacing.xl.h, bottom: AppSpacing.lg.h),
      child: SizedBox(
        height: 36.h,
        child: Obx(() {
          // Both observables are read here rather than inside itemBuilder,
          // which runs outside Obx's tracking scope.
          final categories = controller.categories.toList();
          final activeId = controller.activeCategoryId.value;
          final remote = controller.workArrangement.value == 'remote';

          return ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter.w),
              children: [
                FilterChipButton(
                  label: 'Remote',
                  icon: Iconsax.global,
                  active: remote,
                  onTap: controller.toggleRemote,
                ),
                SizedBox(width: AppSpacing.sm.w),
                FilterChipButton(
                  label: 'Semua',
                  active: activeId == null,
                  onTap: () => controller.selectCategory(null),
                ),
                for (final category in categories) ...[
                  SizedBox(width: AppSpacing.sm.w),
                  FilterChipButton(
                    label: category.name,
                    active: activeId == category.id,
                    onTap: () => controller.selectCategory(category.id),
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _JobList extends GetView<JobsController> {
  const _JobList();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
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

      final jobs = controller.jobs.toList();
      if (jobs.isEmpty) {
        return ListView(
          padding: gutter,
          children: const [
            EmptyState(
              message:
                  'Tidak ada lowongan yang cocok. Coba ubah kata kunci atau filter.',
            ),
          ],
        );
      }

      final loadingMore = controller.isLoadingMore.value;
      final saved = controller.savedSlugs;

      return ListView.separated(
        controller: controller.scrollController,
        padding: gutter,
        itemCount: jobs.length + (loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
        itemBuilder: (context, index) {
          if (index >= jobs.length) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg.h),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }

          final job = jobs[index];

          return JobCard(
            job: job,
            isSaved: saved.contains(job.slug),
            onTap: () => controller.openJob(job),
            onSave: () => controller.toggleSave(job),
          );
        },
      );
    });
  }
}
