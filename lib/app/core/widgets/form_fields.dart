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
class FormSheetShell extends StatelessWidget {
  const FormSheetShell({
    super.key,
    required this.title,
    required this.child,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final Widget child;
  final String submitLabel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 0.88.sh),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandNavy,
              ),
            ),
            SizedBox(height: 14.h),
            Flexible(child: SingleChildScrollView(child: child)),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSubmit,
                child: Text(submitLabel),
              ),
            ),
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }
}
