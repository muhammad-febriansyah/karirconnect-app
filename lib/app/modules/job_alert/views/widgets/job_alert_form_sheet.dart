import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../data/models/job_alert_model.dart';
import '../../../../data/models/meta_model.dart';
import '../../controllers/job_alert_controller.dart';

/// Create / edit form for a job alert.
///
/// `name` and `frequency` are the only fields `JobAlertRequest` requires;
/// everything else is optional and omitted from the payload when unset, so a
/// cleared field really clears the criterion rather than sending a stale id.
class JobAlertFormSheet extends StatefulWidget {
  const JobAlertFormSheet({
    super.key,
    required this.controller,
    this.existing,
  });

  final JobAlertController controller;
  final JobAlertModel? existing;

  static Future<void> show(
    BuildContext context,
    JobAlertController controller, {
    JobAlertModel? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        // Lifts the sheet above the keyboard while a field is focused.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: JobAlertFormSheet(controller: controller, existing: existing),
      ),
    );
  }

  @override
  State<JobAlertFormSheet> createState() => _JobAlertFormSheetState();
}

class _JobAlertFormSheetState extends State<JobAlertFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _nameController =
      TextEditingController(text: widget.existing?.name ?? '');
  late final _keywordController =
      TextEditingController(text: widget.existing?.keyword ?? '');
  late final _salaryController = TextEditingController(
    text: widget.existing?.salaryMin?.toString() ?? '',
  );

  late String _frequency = widget.existing?.frequency ?? 'daily';
  late int? _categoryId = widget.existing?.jobCategoryId;
  late int? _provinceId = widget.existing?.provinceId;
  late String? _employmentType = widget.existing?.employmentType;
  late String? _workArrangement = widget.existing?.workArrangement;
  late String? _experienceLevel = widget.existing?.experienceLevel;
  late bool _isActive = widget.existing?.isActive ?? true;

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _payload() {
    final keyword = _keywordController.text.trim();
    final salary = int.tryParse(_salaryController.text.trim());

    return {
      'name': _nameController.text.trim(),
      'frequency': _frequency,
      'is_active': _isActive,
      if (keyword.isNotEmpty) 'keyword': keyword,
      'job_category_id': ?_categoryId,
      'province_id': ?_provinceId,
      'employment_type': ?_employmentType,
      'work_arrangement': ?_workArrangement,
      'experience_level': ?_experienceLevel,
      'salary_min': ?salary,
    };
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final saved = await widget.controller.save(
      existing: widget.existing,
      payload: _payload(),
    );

    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final meta = widget.controller.meta.value;

    return Container(
      constraints: BoxConstraints(maxHeight: 0.88.sh),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 0),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
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
                widget.existing == null ? 'Alert baru' : 'Ubah alert',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
              SizedBox(height: 14.h),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Field(
                        label: 'Nama alert',
                        controller: _nameController,
                        hint: 'Misal: Frontend Jakarta',
                        validator: (value) {
                          final name = (value ?? '').trim();
                          if (name.isEmpty) return 'Nama wajib diisi.';
                          if (name.length > 120) {
                            return 'Maksimal 120 karakter.';
                          }
                          return null;
                        },
                      ),
                      _Field(
                        label: 'Kata kunci (opsional)',
                        controller: _keywordController,
                        hint: 'Posisi atau skill',
                      ),
                      _Field(
                        label: 'Gaji minimum (opsional)',
                        controller: _salaryController,
                        hint: 'Contoh: 8000000',
                        keyboardType: TextInputType.number,
                      ),
                      _OptionGroup(
                        label: 'Frekuensi',
                        options: JobAlertController.frequencies
                            .map((option) => SelectOption(
                                  value: option.value,
                                  label: option.label,
                                ))
                            .toList(),
                        selected: _frequency,
                        // Required server-side, so this one cannot be cleared.
                        allowClear: false,
                        onSelected: (value) =>
                            setState(() => _frequency = value ?? _frequency),
                      ),
                      _OptionGroup(
                        label: 'Kategori',
                        options: meta.jobCategories
                            .take(12)
                            .map((category) => SelectOption(
                                  value: '${category.id}',
                                  label: category.name,
                                ))
                            .toList(),
                        selected: _categoryId?.toString(),
                        onSelected: (value) => setState(
                          () => _categoryId =
                              value == null ? null : int.tryParse(value),
                        ),
                      ),
                      _OptionGroup(
                        label: 'Provinsi',
                        options: meta.provinces
                            .take(12)
                            .map((province) => SelectOption(
                                  value: '${province.id}',
                                  label: province.name,
                                ))
                            .toList(),
                        selected: _provinceId?.toString(),
                        onSelected: (value) => setState(
                          () => _provinceId =
                              value == null ? null : int.tryParse(value),
                        ),
                      ),
                      _OptionGroup(
                        label: 'Tipe pekerjaan',
                        options: meta.employmentTypes,
                        selected: _employmentType,
                        onSelected: (value) =>
                            setState(() => _employmentType = value),
                      ),
                      _OptionGroup(
                        label: 'Model kerja',
                        options: meta.workArrangements,
                        selected: _workArrangement,
                        onSelected: (value) =>
                            setState(() => _workArrangement = value),
                      ),
                      _OptionGroup(
                        label: 'Level pengalaman',
                        options: meta.experienceLevels,
                        selected: _experienceLevel,
                        onSelected: (value) =>
                            setState(() => _experienceLevel = value),
                      ),
                      SwitchListTile.adaptive(
                        value: _isActive,
                        onChanged: (value) => setState(() => _isActive = value),
                        contentPadding: EdgeInsets.zero,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                        title: Text(
                          'Aktifkan alert',
                          style: GoogleFonts.poppins(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brandNavy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.existing == null ? 'Buat alert' : 'Simpan perubahan',
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.validator,
    this.keyboardType,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

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

class _OptionGroup extends StatelessWidget {
  const _OptionGroup({
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.allowClear = true,
  });

  final String label;
  final List<SelectOption> options;
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
                  onTap: () => onSelected(
                    active && allowClear ? null : option.value,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 13.w,
                      vertical: 8.h,
                    ),
                    child: Text(
                      option.label,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
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
