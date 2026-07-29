import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';
import '../values/app_colors.dart';

/// The blue block that opens Beranda and Lowongan: the landing's hero gradient
/// with its contour lines redrawn at phone scale.
///
/// Square-bottomed on purpose — [HeaderSheet] continues the gradient behind
/// its own rounded top corners, so the curve belongs to that block. Rounding
/// here too would stack two curves on the same edge.
class GradientHeader extends StatelessWidget {
  const GradientHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _ContourPainter())),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter.w,
                AppSpacing.md.h,
                AppSpacing.gutter.w,
                AppSpacing.xl.h,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// A [GradientHeader] pre-laid for a *pushed* page: a back circle on the left,
/// a title (and optional subtitle) beside it, and optional trailing actions.
///
/// This is the counterpart to the freeform [GradientHeader] the tabs use. Every
/// screen reached by `Get.toNamed` should wear this instead of a white `AppBar`
/// so a detail page still reads as the same app as the tab that opened it.
class GradientHeaderBar extends StatelessWidget {
  const GradientHeaderBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String? subtitle;

  /// Defaults to `Get.back`-style pop via the Navigator when null.
  final VoidCallback? onBack;

  /// Trailing controls, right-aligned. Use [HeaderCircleButton] for parity with
  /// the back control.
  final List<Widget> actions;

  /// Extra content under the title row — a search field, a stat strip. Sits
  /// inside the same gradient block, above the sheet.
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              HeaderCircleButton(
                icon: Iconsax.arrow_left_2,
                label: 'Kembali',
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 1.h),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (final action in actions) ...[
                SizedBox(width: AppSpacing.sm.w),
                action,
              ],
            ],
          ),
          if (bottom != null) ...[
            SizedBox(height: AppSpacing.xl.h),
            bottom!,
          ],
        ],
      ),
    );
  }
}

/// The translucent-white circle used for header controls (back, save, bell) on
/// the gradient — sized to the 44pt minimum rather than to the glyph.
class HeaderCircleButton extends StatelessWidget {
  const HeaderCircleButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Tints the glyph with the brand cyan when it reflects an on-state.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Icon(
              icon,
              size: 20.sp,
              color: active ? AppColors.brandCyan : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// The white content sheet that rises over a [GradientHeader].
///
/// The overlap is painted, not translated: the sheet is backed by the header
/// gradient's final colour, so its rounded top corners reveal blue and the two
/// blocks read as one — while the widget still reports its true height. A
/// `Transform.translate` would leave a strip of dead space below equal to the
/// offset, because a transform does not affect layout.
///
/// It needs no border and no shadow: white against the gradient is already the
/// strongest edge available, and the page continues on the same white.
class HeaderSheet extends StatelessWidget {
  const HeaderSheet({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.heroGradientEnd,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.card + 8),
          ),
        ),
        padding: padding ??
            EdgeInsets.fromLTRB(
              AppSpacing.gutter.w,
              AppSpacing.xl.h,
              AppSpacing.gutter.w,
              0,
            ),
        child: child,
      ),
    );
  }
}

/// The search field the header carries, white on the gradient.
///
/// Built by hand rather than through `InputDecorationTheme`, because the theme
/// fill (`surfaceSoft`) is tuned for a white page and would nearly vanish here.
class HeaderSearchField extends StatelessWidget {
  const HeaderSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          Icon(
            Iconsax.search_normal_1,
            size: 18.sp,
            color: AppColors.mutedForeground,
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: AppColors.brandNavy,
              ),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.mutedForeground.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The amber square beside [HeaderSearchField]. Sized to match the field so
/// the two read as one control pair.
///
/// Takes a [child] rather than an `onTap` so a caller can hand it to a
/// `PopupMenuButton`, which owns its own gesture.
class HeaderActionButton extends StatelessWidget {
  const HeaderActionButton({
    super.key,
    required this.icon,
    this.onTap,
    this.showDot = false,
  });

  final IconData icon;
  final VoidCallback? onTap;

  /// Marks the control as carrying a non-default selection.
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    final face = SizedBox(
      width: 48.h,
      height: 48.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(icon, size: 21.sp, color: AppColors.brandNavy),
          if (showDot)
            Positioned(
              top: 8.h,
              right: 8.w,
              child: Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  color: AppColors.destructive,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );

    return Material(
      color: AppColors.accentAmber,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: onTap == null
          ? face
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: face,
            ),
    );
  }
}

/// A filter pill. Selection is a fill swap, not an outline swap: at rest it is
/// the same tonal surface every other resting element uses, so the active one
/// is the only thing that stands out.
class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 14.sp,
                  color: active ? Colors.white : AppColors.primary,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The flowing contour lines the web hero uses, redrawn at phone scale.
class _ContourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.14);

    final w = size.width;
    final h = size.height;

    for (var i = 0; i < 3; i++) {
      final offset = h * (0.18 + i * 0.22);

      canvas.drawPath(
        Path()
          ..moveTo(-w * 0.1, offset)
          ..cubicTo(w * 0.25, offset - h * 0.16, w * 0.6, offset + h * 0.14,
              w * 1.1, offset - h * 0.06),
        paint..color = Colors.white.withValues(alpha: 0.14 - i * 0.035),
      );
    }

    canvas.drawCircle(
      Offset(w * 0.95, -h * 0.1),
      h * 0.42,
      Paint()..color = AppColors.brandCyan.withValues(alpha: 0.10),
    );
  }

  @override
  bool shouldRepaint(covariant _ContourPainter oldDelegate) => false;
}
