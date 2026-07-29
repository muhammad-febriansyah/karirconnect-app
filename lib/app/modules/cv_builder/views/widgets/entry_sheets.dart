import 'package:flutter/material.dart';

import '../../../../core/widgets/form_fields.dart';
import '../../../../data/models/cv_model.dart';
import '../../controllers/cv_builder_controller.dart';

/// Add-entry sheets for the builder's repeating blocks.
///
/// The builder stores periods as free text (`"2020 – 2023"`) rather than dates,
/// unlike the profile's own work-experience records — so these are plain text
/// fields, not date pickers.

Future<void> _show(BuildContext context, Widget sheet) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: sheet,
    ),
  );
}

class ExperienceSheet extends StatefulWidget {
  const ExperienceSheet({super.key, required this.controller});

  final CvBuilderController controller;

  static Future<void> show(
    BuildContext context,
    CvBuilderController controller,
  ) =>
      _show(context, ExperienceSheet(controller: controller));

  @override
  State<ExperienceSheet> createState() => _ExperienceSheetState();
}

class _ExperienceSheetState extends State<ExperienceSheet> {
  final _position = TextEditingController();
  final _company = TextEditingController();
  final _period = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _position.dispose();
    _company.dispose();
    _period.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final position = _position.text.trim();
    final company = _company.text.trim();

    // Both are `required` on each array item server-side.
    if (position.isEmpty || company.isEmpty) return;

    widget.controller.addExperience(
      CvBuilderExperience(
        company: company,
        position: position,
        period: _period.text.trim().isEmpty ? null : _period.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: 'Tambah pengalaman',
      submitLabel: 'Tambah',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Posisi',
            controller: _position,
            hint: 'Misal: Frontend Developer',
          ),
          LabeledField(
            label: 'Perusahaan',
            controller: _company,
            hint: 'Nama perusahaan',
          ),
          LabeledField(
            label: 'Periode',
            controller: _period,
            hint: 'Misal: 2022 – sekarang',
          ),
          LabeledField(
            label: 'Deskripsi',
            controller: _description,
            hint: 'Tanggung jawab dan pencapaian',
            maxLines: 4,
          ),
        ],
      ),
    );
  }
}

class EducationEntrySheet extends StatefulWidget {
  const EducationEntrySheet({super.key, required this.controller});

  final CvBuilderController controller;

  static Future<void> show(
    BuildContext context,
    CvBuilderController controller,
  ) =>
      _show(context, EducationEntrySheet(controller: controller));

  @override
  State<EducationEntrySheet> createState() => _EducationEntrySheetState();
}

class _EducationEntrySheetState extends State<EducationEntrySheet> {
  final _institution = TextEditingController();
  final _major = TextEditingController();
  final _period = TextEditingController();
  final _gpa = TextEditingController();

  @override
  void dispose() {
    _institution.dispose();
    _major.dispose();
    _period.dispose();
    _gpa.dispose();
    super.dispose();
  }

  void _submit() {
    final institution = _institution.text.trim();
    if (institution.isEmpty) return;

    widget.controller.addEducation(
      CvBuilderEducation(
        institution: institution,
        major: _major.text.trim().isEmpty ? null : _major.text.trim(),
        period: _period.text.trim().isEmpty ? null : _period.text.trim(),
        gpa: _gpa.text.trim().isEmpty ? null : _gpa.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: 'Tambah pendidikan',
      submitLabel: 'Tambah',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Institusi',
            controller: _institution,
            hint: 'Nama sekolah atau universitas',
          ),
          LabeledField(
            label: 'Jurusan',
            controller: _major,
            hint: 'Misal: Teknik Informatika',
          ),
          LabeledField(
            label: 'Periode',
            controller: _period,
            hint: 'Misal: 2018 – 2022',
          ),
          LabeledField(
            label: 'IPK',
            controller: _gpa,
            hint: 'Misal: 3.50',
          ),
        ],
      ),
    );
  }
}

class CertificationEntrySheet extends StatefulWidget {
  const CertificationEntrySheet({super.key, required this.controller});

  final CvBuilderController controller;

  static Future<void> show(
    BuildContext context,
    CvBuilderController controller,
  ) =>
      _show(context, CertificationEntrySheet(controller: controller));

  @override
  State<CertificationEntrySheet> createState() =>
      _CertificationEntrySheetState();
}

class _CertificationEntrySheetState extends State<CertificationEntrySheet> {
  final _name = TextEditingController();
  final _issuer = TextEditingController();
  final _year = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _year.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    widget.controller.addCertification(
      CvBuilderCertification(
        name: name,
        issuer: _issuer.text.trim().isEmpty ? null : _issuer.text.trim(),
        year: _year.text.trim().isEmpty ? null : _year.text.trim(),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: 'Tambah sertifikat',
      submitLabel: 'Tambah',
      onSubmit: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LabeledField(
            label: 'Nama sertifikat',
            controller: _name,
            hint: 'Misal: AWS Certified Developer',
          ),
          LabeledField(
            label: 'Penerbit',
            controller: _issuer,
            hint: 'Misal: Amazon Web Services',
          ),
          LabeledField(
            label: 'Tahun',
            controller: _year,
            hint: 'Misal: 2024',
          ),
        ],
      ),
    );
  }
}
