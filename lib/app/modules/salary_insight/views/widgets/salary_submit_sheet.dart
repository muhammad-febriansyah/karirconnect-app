import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../controllers/salary_insight_controller.dart';

/// `POST salary-submissions`. `sample_size` and `source` are filled in by the
/// controller, so the form only collects the figures.
class SalarySubmitSheet extends StatefulWidget {
  const SalarySubmitSheet({super.key, required this.controller});

  final SalaryInsightController controller;

  static Future<void> show(
    BuildContext context,
    SalaryInsightController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SalarySubmitSheet(controller: controller),
      ),
    );
  }

  @override
  State<SalarySubmitSheet> createState() => _SalarySubmitSheetState();
}

class _SalarySubmitSheetState extends State<SalarySubmitSheet> {
  final _jobTitleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _minController = TextEditingController();
  final _medianController = TextEditingController();
  final _maxController = TextEditingController();

  String? _experience;

  @override
  void dispose() {
    _jobTitleController.dispose();
    _categoryController.dispose();
    _minController.dispose();
    _medianController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  int? _int(TextEditingController controller) =>
      int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), ''));

  Future<void> _submit() async {
    final jobTitle = _jobTitleController.text.trim();
    final category = _categoryController.text.trim();
    final min = _int(_minController);
    final median = _int(_medianController);
    final max = _int(_maxController);

    if (jobTitle.isEmpty || category.isEmpty) {
      AppToast.warning('Posisi dan kategori wajib diisi.');
      return;
    }
    if (_experience == null) {
      AppToast.warning('Pilih level pengalaman.');
      return;
    }
    if (min == null || median == null || max == null) {
      AppToast.warning('Isi ketiga angka gaji.');
      return;
    }
    if (!(min <= median && median <= max)) {
      AppToast.warning('Urutan gaji harus minimum ≤ median ≤ maksimum.');
      return;
    }

    final ok = await widget.controller.submitSalary({
      'job_title': jobTitle,
      'role_category': category,
      'experience_level': _experience,
      'min_salary': min,
      'median_salary': median,
      'max_salary': max,
    });

    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final levels = widget.controller.meta.value.experienceLevels;

    return Obx(
      () => FormSheetShell(
        title: 'Bagikan data gaji',
        subtitle:
            'Data dikirim anonim dan ditinjau sebelum masuk agregat publik.',
        submitLabel:
            widget.controller.isSubmitting.value ? 'Mengirim…' : 'Kirim data',
        onSubmit: _submit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Posisi'),
            SizedBox(height: 6.h),
            _Field(controller: _jobTitleController, hint: 'Misal: Backend Engineer'),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Kategori'),
            SizedBox(height: 6.h),
            _Field(
              controller: _categoryController,
              hint: 'Misal: Software Engineering',
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Level pengalaman'),
            SizedBox(height: AppSpacing.sm.h),
            Wrap(
              spacing: AppSpacing.sm.w,
              runSpacing: AppSpacing.sm.h,
              children: levels
                  .map(
                    (level) => _Pill(
                      label: level.label,
                      active: _experience == level.value,
                      onTap: () => setState(() => _experience = level.value),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Gaji per bulan (Rp)'),
            SizedBox(height: 6.h),
            Row(
              children: [
                Expanded(
                  child: _NumberField(controller: _minController, hint: 'Min'),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: _NumberField(
                    controller: _medianController,
                    hint: 'Median',
                  ),
                ),
                SizedBox(width: AppSpacing.sm.w),
                Expanded(
                  child: _NumberField(controller: _maxController, hint: 'Maks'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: 160,
      style: GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.foreground),
      decoration: InputDecoration(counterText: '', hintText: hint),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.hint});

  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.foreground),
      decoration: InputDecoration(hintText: hint),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w,
            vertical: AppSpacing.sm.h,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.brandNavy,
      ),
    );
  }
}
