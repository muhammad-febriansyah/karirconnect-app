import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../data/models/meta_model.dart';
import '../../controllers/home_controller.dart';
import 'sheet_shell.dart';

/// Employment type / work arrangement / experience level, all sourced from
/// `GET api/v1/meta` so the options can never drift from what the API accepts.
///
/// Selections are staged locally and only pushed to the controller on
/// "Terapkan", so dismissing the sheet leaves the list untouched.
class FilterSheet extends StatefulWidget {
  const FilterSheet({super.key, required this.controller});

  final HomeController controller;

  static Future<void> show(BuildContext context, HomeController controller) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FilterSheet(controller: controller),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late String? _employment = widget.controller.employmentType.value;
  late String? _arrangement = widget.controller.workArrangement.value;
  late String? _experience = widget.controller.experienceLevel.value;

  @override
  Widget build(BuildContext context) {
    final meta = widget.controller.meta.value;

    return SheetShell(
      title: 'Filter lowongan',
      trailing: TextButton(
        onPressed: () => setState(() {
          _employment = null;
          _arrangement = null;
          _experience = null;
        }),
        child: const Text('Reset'),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Group(
                    label: 'Tipe pekerjaan',
                    options: meta.employmentTypes,
                    selected: _employment,
                    onSelected: (value) => setState(() => _employment = value),
                  ),
                  _Group(
                    label: 'Model kerja',
                    options: meta.workArrangements,
                    selected: _arrangement,
                    onSelected: (value) => setState(() => _arrangement = value),
                  ),
                  _Group(
                    label: 'Level pengalaman',
                    options: meta.experienceLevels,
                    selected: _experience,
                    onSelected: (value) => setState(() => _experience = value),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 12.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.controller.applyFilters(
                  employment: _employment,
                  arrangement: _arrangement,
                  experience: _experience,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Terapkan'),
            ),
          ),
          SizedBox(height: 12.h),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final List<SelectOption> options;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: 18.h),
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
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: options.map((option) {
              final active = selected == option.value;

              return Material(
                color: active ? AppColors.primary : AppColors.muted,
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: InkWell(
                  // Tapping the active option clears it.
                  onTap: () => onSelected(active ? null : option.value),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 9.h,
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
