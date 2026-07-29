import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/gradient_header.dart';
import '../../controllers/home_controller.dart';

/// Two rows of four shortcuts, riding on the [HeaderSheet] that rises over the
/// blue header — see that class for why the overlap is painted, not translated.
///
/// The shortcuts are deliberately the endpoints the five bottom-nav tabs do
/// *not* already own. Three of them (salary insights, companies, career
/// resources) are public, so a guest can use the menu without a login wall.
class QuickMenu extends GetView<HomeController> {
  const QuickMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return HeaderSheet(
      // A tighter gutter than the sheet's default: eight tiles across need the
      // extra width, and each tile pads its own label.
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md.w,
        AppSpacing.xl.h,
        AppSpacing.md.w,
        0,
      ),
      child: Column(
        children: [
          _Row(items: HomeController.quickMenu.sublist(0, 4), offset: 0),
          SizedBox(height: AppSpacing.lg.h),
          _Row(items: HomeController.quickMenu.sublist(4), offset: 4),
        ],
      ),
    );
  }
}

class _Row extends GetView<HomeController> {
  const _Row({required this.items, required this.offset});

  final List<QuickMenuItem> items;

  /// Index of the first item within the full menu, so the tint cycle carries
  /// across both rows instead of restarting on the second.
  final int offset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (index, item) in items.indexed)
          Expanded(
            child: _Tile(
              item: item,
              tone: offset + index,
              onTap: () => controller.openQuickMenu(item),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.tone, required this.onTap});

  final QuickMenuItem item;

  /// Position in the tint cycle. Wrapped modulo the palette length so the menu
  /// cannot go out of range if its item count ever changes.
  final int tone;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.tileTints[tone % AppColors.tileTints.length];
    final iconColor = AppColors.tileIcons[tone % AppColors.tileIcons.length];

    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: tint,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(item.icon, size: 22.sp, color: iconColor),
              ),
              SizedBox(height: AppSpacing.sm.h),
              // One line, always: a label that wrapped to two would knock its
              // whole row out of alignment with the other four.
              Text(
                item.label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
