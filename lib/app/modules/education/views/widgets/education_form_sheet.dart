import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/widgets/form_fields.dart';
import '../../../../data/models/profile_record_models.dart';
import '../../controllers/education_controller.dart';

class EducationFormSheet extends StatefulWidget {
  const EducationFormSheet({
    super.key,
    required this.controller,
    this.existing,
  });

  final EducationController controller;
  final EducationModel? existing;

  static Future<void> show(
    BuildContext context,
    EducationController controller, {
    EducationModel? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EducationFormSheet(controller: controller, existing: existing),
      ),
    );
  }

  @override
  State<EducationFormSheet> createState() => _EducationFormSheetState();
}

class _EducationFormSheetState extends State<EducationFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _institution =
      TextEditingController(text: widget.existing?.institution ?? '');
  late final _major = TextEditingController(text: widget.existing?.major ?? '');
  late final _gpa =
      TextEditingController(text: widget.existing?.gpa?.toString() ?? '');
  late final _startYear = TextEditingController(
    text: widget.existing?.startYear.toString() ?? '',
  );
  late final _endYear = TextEditingController(
    text: widget.existing?.endYear?.toString() ?? '',
  );
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');

  late String _level = widget.existing?.level ?? 's1';

  @override
  void dispose() {
    _institution.dispose();
    _major.dispose();
    _gpa.dispose();
    _startYear.dispose();
    _endYear.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final major = _major.text.trim();
    final gpa = double.tryParse(_gpa.text.trim().replaceAll(',', '.'));
    final endYear = int.tryParse(_endYear.text.trim());
    final description = _description.text.trim();

    final saved = await widget.controller.save(
      existing: widget.existing,
      payload: {
        'level': _level,
        'institution': _institution.text.trim(),
        'start_year': int.parse(_startYear.text.trim()),
        if (major.isNotEmpty) 'major': major,
        'gpa': ?gpa,
        'end_year': ?endYear,
        if (description.isNotEmpty) 'description': description,
      },
    );

    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: widget.existing == null ? 'Tambah pendidikan' : 'Ubah pendidikan',
      submitLabel: widget.existing == null ? 'Tambah' : 'Simpan',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChipPicker(
              label: 'Jenjang',
              options: EducationController.levels,
              selected: _level,
              // `level` is required server-side.
              allowClear: false,
              onSelected: (value) => setState(() => _level = value ?? _level),
            ),
            LabeledField(
              label: 'Institusi',
              controller: _institution,
              hint: 'Nama sekolah atau universitas',
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Institusi wajib diisi.';
                return null;
              },
            ),
            LabeledField(
              label: 'Jurusan (opsional)',
              controller: _major,
              hint: 'Misal: Teknik Informatika',
            ),
            LabeledField(
              label: 'IPK (opsional)',
              controller: _gpa,
              hint: '0 – 4',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;

                final gpa = double.tryParse(text.replaceAll(',', '.'));
                if (gpa == null) return 'IPK harus berupa angka.';
                if (gpa < 0 || gpa > 4) return 'IPK harus antara 0 dan 4.';
                return null;
              },
            ),
            LabeledField(
              label: 'Tahun mulai',
              controller: _startYear,
              hint: 'Misal: 2018',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _yearValidator(required: true),
            ),
            LabeledField(
              label: 'Tahun selesai (opsional)',
              controller: _endYear,
              hint: 'Kosongkan jika masih berjalan',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final base = _yearValidator(required: false)(value);
                if (base != null) return base;

                final end = int.tryParse((value ?? '').trim());
                final start = int.tryParse(_startYear.text.trim());
                if (end != null && start != null && end < start) {
                  return 'Tahun selesai tidak boleh sebelum tahun mulai.';
                }
                return null;
              },
            ),
            LabeledField(
              label: 'Deskripsi (opsional)',
              controller: _description,
              hint: 'Prestasi, organisasi, atau fokus studi',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  /// Server rule: `integer|min:1950|max:2100`.
  String? Function(String?) _yearValidator({required bool required}) {
    return (value) {
      final text = (value ?? '').trim();

      if (text.isEmpty) return required ? 'Tahun wajib diisi.' : null;

      final year = int.tryParse(text);
      if (year == null) return 'Tahun harus berupa angka.';
      if (year < 1950 || year > 2100) return 'Tahun harus antara 1950 dan 2100.';
      return null;
    };
  }
}
