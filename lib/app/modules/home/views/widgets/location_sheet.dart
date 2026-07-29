import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/values/app_colors.dart';
import '../../controllers/home_controller.dart';
import 'sheet_shell.dart';

/// Province picker for the header. Provinces come from `GET api/v1/meta`, which
/// is the same list the web hero's location combobox uses.
class LocationSheet extends StatelessWidget {
  const LocationSheet({super.key, required this.controller});

  final HomeController controller;

  static Future<void> show(BuildContext context, HomeController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LocationSheet(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: 'Pilih lokasi',
      child: Obx(() {
        final provinces = controller.meta.value.provinces;
        final activeId = controller.activeProvinceId.value;

        if (provinces.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 28.h),
            child: Center(
              child: Text(
                'Daftar lokasi belum tersedia.',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.only(bottom: 8.h),
          itemCount: provinces.length + 1,
          separatorBuilder: (_, _) =>
              const Divider(height: 1, color: AppColors.border),
          itemBuilder: (context, index) {
            // Index 0 clears the filter.
            final province = index == 0 ? null : provinces[index - 1];
            final selected = activeId == province?.id;

            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                province == null ? Iconsax.global : Iconsax.location,
                size: 18.sp,
                color: selected ? AppColors.primary : AppColors.mutedForeground,
              ),
              title: Text(
                province?.name ?? 'Semua lokasi',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:
                      selected ? AppColors.primary : AppColors.foreground,
                ),
              ),
              trailing: selected
                  ? Icon(
                      Iconsax.tick_circle,
                      size: 18.sp,
                      color: AppColors.primary,
                    )
                  : null,
              onTap: () {
                controller.selectProvince(province?.id);
                Navigator.of(context).pop();
              },
            );
          },
        );
      }),
    );
  }
}
