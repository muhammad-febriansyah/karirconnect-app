import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../controllers/home_controller.dart';
import 'filter_sheet.dart';
import 'location_sheet.dart';

/// Beranda's header: location picker + notification bell on top, search field
/// and filter button underneath.
///
/// The gradient block, contour pattern, search field, amber action button and
/// the white sheet below all come from `core/widgets/gradient_header.dart`, so
/// this and the Lowongan tab cannot drift apart.
class HomeHeader extends GetView<HomeController> {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _LocationPicker()),
              SizedBox(width: AppSpacing.md.w),
              const _BellButton(),
            ],
          ),
          SizedBox(height: AppSpacing.xl.h),
          const _SearchRow(),
        ],
      ),
    );
  }
}

class _LocationPicker extends GetView<HomeController> {
  const _LocationPicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lokasi',
          style: GoogleFonts.poppins(
            fontSize: 11.sp,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(height: 2.h),
        InkWell(
          onTap: () => LocationSheet.show(context, controller),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Iconsax.location5, size: 16.sp, color: AppColors.brandCyan),
              SizedBox(width: 6.w),
              Flexible(
                child: Obx(
                  () => Text(
                    controller.locationLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Iconsax.arrow_down_1,
                size: 14.sp,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BellButton extends GetView<HomeController> {
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: controller.openNotifications,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: Padding(
          padding: EdgeInsets.all(10.w),
          child: Icon(Iconsax.notification, size: 20.sp, color: Colors.white),
        ),
      ),
    );
  }
}

class _SearchRow extends GetView<HomeController> {
  const _SearchRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: HeaderSearchField(
            controller: controller.searchController,
            hintText: 'Cari posisi atau perusahaan',
            onSubmitted: controller.submitSearch,
          ),
        ),
        SizedBox(width: AppSpacing.md.w),
        Obx(
          () => HeaderActionButton(
            icon: Iconsax.setting_4,
            showDot: controller.activeFilterCount > 0,
            onTap: () => FilterSheet.show(context, controller),
          ),
        ),
      ],
    );
  }
}
