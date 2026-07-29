import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../data/models/company_model.dart';

/// Port of `CompanyGridCard` in `resources/js/pages/welcome.tsx`, reflowed as a
/// fixed-width tile for the horizontal rail on mobile.
class CompanyCard extends StatelessWidget {
  const CompanyCard({super.key, required this.company, required this.onTap});

  final CompanyModel company;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168.w,
      child: Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                _Logo(company: company),
                SizedBox(height: AppSpacing.md.h),
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
                SizedBox(height: 2.h),
                Text(
                  company.industry ?? company.city ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11.sp,
                    color: AppColors.mutedForeground,
                  ),
                ),
                // Pins the count to the bottom so a one-line and a two-line
                // tile still align across the rail.
                const Spacer(),
                // No `alignment` here: a Container with one expands to the
                // largest size its constraints allow, which stretched the
                // badge across the whole tile. Padding alone hugs the label.
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm.w,
                    vertical: 5.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '${company.openJobsCount ?? 0} lowongan',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentForeground,
                    ),
                  ),
                ),
              ],
            ),
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
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceInset,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.brandNavy,
        ),
      );
}
