import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../values/app_colors.dart';

/// Title + subtitle pair the landing repeats above each section, with the
/// optional "Lihat semua" affordance on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onSeeAll,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                  letterSpacing: -0.3,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 3.h),
                Text(
                  subtitle!,
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
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              visualDensity: VisualDensity.compact,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat semua',
                  style: GoogleFonts.poppins(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 2.w),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 13.sp,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
