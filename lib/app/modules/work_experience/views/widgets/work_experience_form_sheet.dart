import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../data/models/profile_record_models.dart';
import '../../controllers/work_experience_controller.dart';

class WorkExperienceFormSheet extends StatefulWidget {
  const WorkExperienceFormSheet({
    super.key,
    required this.controller,
    this.existing,
  });

  final WorkExperienceController controller;
  final WorkExperienceModel? existing;

  static Future<void> show(
    BuildContext context,
    WorkExperienceController controller, {
    WorkExperienceModel? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: WorkExperienceFormSheet(
          controller: controller,
          existing: existing,
        ),
      ),
    );
  }

  @override
  State<WorkExperienceFormSheet> createState() =>
      _WorkExperienceFormSheetState();
}

class _WorkExperienceFormSheetState extends State<WorkExperienceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _company =
      TextEditingController(text: widget.existing?.companyName ?? '');
  late final _position =
      TextEditingController(text: widget.existing?.position ?? '');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');

  late String? _employmentType = widget.existing?.employmentType;
  late bool _isCurrent = widget.existing?.isCurrent ?? false;
  late DateTime? _startDate = _parse(widget.existing?.startDate);
  late DateTime? _endDate = _parse(widget.existing?.endDate);

  static DateTime? _parse(String? iso) =>
      iso == null || iso.isEmpty ? null : DateTime.tryParse(iso);

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 5),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_startDate == null) {
      _showDateError('Tanggal mulai wajib diisi.');
      return;
    }

    // Server rule: `end_date` must be on or after `start_date`.
    if (!_isCurrent && _endDate != null && _endDate!.isBefore(_startDate!)) {
      _showDateError('Tanggal selesai tidak boleh sebelum tanggal mulai.');
      return;
    }

    final description = _description.text.trim();

    final saved = await widget.controller.save(
      existing: widget.existing,
      payload: {
        'company_name': _company.text.trim(),
        'position': _position.text.trim(),
        'start_date': _iso(_startDate!),
        'is_current': _isCurrent,
        'employment_type': ?_employmentType,
        // A current role has no end date, and sending one alongside
        // is_current=true is contradictory.
        if (!_isCurrent && _endDate != null) 'end_date': _iso(_endDate!),
        if (description.isNotEmpty) 'description': description,
      },
    );

    if (saved && mounted) Navigator.of(context).pop();
  }

  void _showDateError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.destructive),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: widget.existing == null ? 'Tambah pengalaman' : 'Ubah pengalaman',
      submitLabel: widget.existing == null ? 'Tambah' : 'Simpan',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Posisi',
              controller: _position,
              hint: 'Misal: Frontend Developer',
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Posisi wajib diisi.' : null,
            ),
            LabeledField(
              label: 'Perusahaan',
              controller: _company,
              hint: 'Nama perusahaan',
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Perusahaan wajib diisi.'
                  : null,
            ),
            ChipPicker(
              label: 'Tipe pekerjaan',
              options: widget.controller.meta.value.employmentTypes
                  .map((option) => (value: option.value, label: option.label))
                  .toList(),
              selected: _employmentType,
              onSelected: (value) => setState(() => _employmentType = value),
            ),
            _DateRow(
              label: 'Tanggal mulai',
              value: _startDate,
              onTap: () => _pickDate(isStart: true),
            ),
            if (!_isCurrent)
              _DateRow(
                label: 'Tanggal selesai',
                value: _endDate,
                onTap: () => _pickDate(isStart: false),
              ),
            SwitchListTile.adaptive(
              value: _isCurrent,
              onChanged: (value) => setState(() => _isCurrent = value),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              title: Text(
                'Masih bekerja di sini',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            LabeledField(
              label: 'Deskripsi (opsional)',
              controller: _description,
              hint: 'Tanggung jawab dan pencapaian',
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

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
          InkWell(
            onTap: onTap,
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Text(
                value == null
                    ? 'Pilih tanggal'
                    : '${value!.day.toString().padLeft(2, '0')}/'
                        '${value!.month.toString().padLeft(2, '0')}/'
                        '${value!.year}',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: value == null
                      ? AppColors.mutedForeground
                      : AppColors.foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
