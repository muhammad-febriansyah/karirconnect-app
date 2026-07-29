import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/career_resource_model.dart';
import '../controllers/career_resource_controller.dart';

/// `GET api/v1/career-resources` — public, so this screen works signed out.
class CareerResourceView extends GetView<CareerResourceController> {
  const CareerResourceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Artikel Karier'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 10.h),
            child: TextField(
              controller: controller.searchController,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppColors.foreground,
              ),
              decoration: InputDecoration(
                hintText: 'Cari artikel',
                fillColor: AppColors.muted,
                prefixIcon: Icon(
                  Iconsax.search_normal_1,
                  size: 18.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          ),
          const _CategoryChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.load,
              color: AppColors.primary,
              child: Obx(() {
                if (controller.isLoading.value) return const SectionLoader();

                final error = controller.errorMessage.value;
                if (error != null) {
                  return ListView(
                    padding: EdgeInsets.all(18.w),
                    children: [
                      ErrorState(message: error, onRetry: controller.load),
                    ],
                  );
                }

                final resources = controller.resources.toList();
                if (resources.isEmpty) {
                  return ListView(
                    padding: EdgeInsets.all(18.w),
                    children: const [
                      EmptyState(
                        icon: Iconsax.book_1,
                        message: 'Belum ada artikel untuk filter ini.',
                      ),
                    ],
                  );
                }

                final loadingMore = controller.isLoadingMore.value;

                return ListView.separated(
                  controller: controller.scrollController,
                  padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 24.h),
                  itemCount: resources.length + (loadingMore ? 1 : 0),
                  separatorBuilder: (_, _) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    if (index >= resources.length) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    final resource = resources[index];

                    return _ArticleCard(
                      resource: resource,
                      onTap: () => controller.openResource(resource),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends GetView<CareerResourceController> {
  const _CategoryChips();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final categories = controller.categories.toList();
      final active = controller.activeCategory.value;

      if (categories.isEmpty) return const SizedBox.shrink();

      return SizedBox(
        height: 32.h,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 18.w),
            itemCount: categories.length + 1,
            separatorBuilder: (_, _) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final category = index == 0 ? null : categories[index - 1];
              final selected = active == category;

              return Material(
                color: selected ? AppColors.primary : AppColors.surfaceSoft,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: () => controller.selectCategory(category),
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Center(
                      child: Text(
                        category == null
                            ? 'Semua'
                            : Formatters.status(category),
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color:
                              selected ? Colors.white : AppColors.mutedForeground,
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

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.resource, required this.onTap});

  final CareerResourceModel resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (resource.thumbnailUrl != null)
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    resource.thumbnailUrl!,
                    fit: BoxFit.cover,
                    // A broken thumbnail must not blank out the card.
                    errorBuilder: (_, _, _) => Container(
                      color: AppColors.muted,
                      alignment: Alignment.center,
                      child: Icon(
                        Iconsax.book_1,
                        size: 24.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: EdgeInsets.all(14.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (resource.category != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          Formatters.status(resource.category),
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accentForeground,
                          ),
                        ),
                      ),
                    SizedBox(height: 8.h),
                    Text(
                      resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    if (resource.excerpt != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        resource.excerpt!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          height: 1.4,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12.sp,
                          color: AppColors.mutedForeground,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          Formatters.relative(resource.publishedAt),
                          style: GoogleFonts.poppins(
                            fontSize: 10.sp,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
