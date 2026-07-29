import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../controllers/article_detail_controller.dart';

/// `GET api/v1/career-resources/{slug}` — public reader.
class ArticleDetailView extends GetView<ArticleDetailController> {
  const ArticleDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Artikel'),
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
          return const EmptyState(
            icon: Iconsax.book_1,
            message: 'Artikel tidak ditemukan.',
          );
        }

        final resource = detail.resource;
        final body = Formatters.richTextToPlain(detail.body);

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            if (resource.thumbnailUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  resource.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.muted,
                    alignment: Alignment.center,
                    child: Icon(
                      Iconsax.book_1,
                      size: 28.sp,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 28.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (resource.category != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
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
                  SizedBox(height: 10.h),
                  Text(
                    resource.title,
                    style: GoogleFonts.poppins(
                      fontSize: 19.sp,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 13.sp,
                        color: AppColors.mutedForeground,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        [
                          Formatters.relative(resource.publishedAt),
                          if (detail.author != null) detail.author!,
                        ].where((part) => part.isNotEmpty).join(' · '),
                        style: GoogleFonts.poppins(
                          fontSize: 10.5.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  if (resource.tags.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: resource.tags
                          .map(
                            (tag) => Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 9.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.muted,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.md),
                              ),
                              child: Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 10.sp,
                                  color: AppColors.foreground
                                      .withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const Divider(height: 28, color: AppColors.border),
                  Text(
                    body.isEmpty
                        ? (resource.excerpt ?? 'Isi artikel belum tersedia.')
                        : body,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      height: 1.7,
                      color: AppColors.foreground.withValues(alpha: 0.88),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
