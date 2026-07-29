import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';

/// Rounded bottom-sheet chrome for a list/filter sheet: shared [SheetContainer]
/// (grab handle + rounded top + safe area), a title row, then the content.
class SheetShell extends StatelessWidget {
  const SheetShell({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      maxHeightFactor: 0.7,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandNavy,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          Flexible(child: child),
        ],
      ),
    );
  }
}
