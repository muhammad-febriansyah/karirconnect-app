import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../values/app_colors.dart';

/// Labelled text field shared by the profile forms.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              color: AppColors.foreground,
            ),
            decoration: InputDecoration(
              hintText: hint,
              errorStyle: GoogleFonts.poppins(fontSize: 11.sp),
            ),
          ),
        ],
      ),
    );
  }
}

/// Single-select chip row. Tapping the active option clears it unless
/// [allowClear] is false, which is what a server-side `required` field needs.
class ChipPicker extends StatelessWidget {
  const ChipPicker({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allowClear = true,
  });

  final String label;
  final List<({String value, String label})> options;
  final String? selected;
  final ValueChanged<String?> onSelected;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: options.map((option) {
              final active = selected == option.value;

              return Material(
                color: active ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  onTap: () =>
                      onSelected(active && allowClear ? null : option.value),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 13.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      option.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w500,
                        color: active ? Colors.white : AppColors.foreground,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Bottom-sheet chrome for the add/edit forms of the profile sub-resources.
/// The chrome every bottom sheet in the app shares: a grab handle, the rounded
/// top, the safe-area inset and the standard gutter. Pulled out so the two
/// shells and the hand-rolled sheets round and pad identically.
class SheetContainer extends StatelessWidget {
  const SheetContainer({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.88,
  });

  final Widget child;

  /// Fraction of screen height the sheet may grow to before its body scrolls.
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: maxHeightFactor.sh),
      decoration: BoxDecoration(
        color: AppColors.background,
        // Matches HeaderSheet's top radius so sheets and the page sheet round
        // the same way.
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.card + 8),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter.w,
        AppSpacing.md.h,
        AppSpacing.gutter.w,
        0,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SheetGrabber(), child],
        ),
      ),
    );
  }
}

/// The drag handle. A short bar, not a stroke — this is the one hairline the
/// borderless system keeps, because a sheet needs a grab affordance.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        margin: EdgeInsets.only(bottom: AppSpacing.lg.h),
        decoration: BoxDecoration(
          color: AppColors.mutedForeground.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(4.r),
        ),
      ),
    );
  }
}

class FormSheetShell extends StatelessWidget {
  const FormSheetShell({
    super.key,
    required this.title,
    required this.child,
    required this.submitLabel,
    required this.onSubmit,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
              letterSpacing: -0.2,
            ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 3.h),
            Text(
              subtitle!,
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                height: 1.4,
                color: AppColors.mutedForeground,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.lg.h),
          Flexible(child: SingleChildScrollView(child: child)),
          SizedBox(height: AppSpacing.md.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: Text(submitLabel),
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
        ],
      ),
    );
  }
}
