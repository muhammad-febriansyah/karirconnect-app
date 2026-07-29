import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../../../data/models/profile_record_models.dart';
import '../../controllers/certification_controller.dart';

class CertificationFormSheet extends StatefulWidget {
  const CertificationFormSheet({
    super.key,
    required this.controller,
    this.existing,
  });

  final CertificationController controller;
  final CertificationModel? existing;

  static Future<void> show(
    BuildContext context,
    CertificationController controller, {
    CertificationModel? existing,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CertificationFormSheet(
          controller: controller,
          existing: existing,
        ),
      ),
    );
  }

  @override
  State<CertificationFormSheet> createState() => _CertificationFormSheetState();
}

class _CertificationFormSheetState extends State<CertificationFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _issuer =
      TextEditingController(text: widget.existing?.issuer ?? '');
  late final _credentialId =
      TextEditingController(text: widget.existing?.credentialId ?? '');
  late final _credentialUrl =
      TextEditingController(text: widget.existing?.credentialUrl ?? '');

  late DateTime? _issuedDate = _parse(widget.existing?.issuedDate);
  late DateTime? _expiresDate = _parse(widget.existing?.expiresDate);

  static DateTime? _parse(String? iso) =>
      iso == null || iso.isEmpty ? null : DateTime.tryParse(iso);

  @override
  void dispose() {
    _name.dispose();
    _issuer.dispose();
    _credentialId.dispose();
    _credentialUrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isIssued}) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: (isIssued ? _issuedDate : _expiresDate) ?? now,
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 20),
    );

    if (picked == null) return;

    setState(() {
      if (isIssued) {
        _issuedDate = picked;
      } else {
        _expiresDate = picked;
      }
    });
  }

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Server rule: `expires_date` must be on or after `issued_date`.
    if (_issuedDate != null &&
        _expiresDate != null &&
        _expiresDate!.isBefore(_issuedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tanggal berlaku tidak boleh sebelum terbit.'),
          backgroundColor: AppColors.destructive,
        ),
      );
      return;
    }

    final credentialId = _credentialId.text.trim();
    final credentialUrl = _credentialUrl.text.trim();

    final saved = await widget.controller.save(
      existing: widget.existing,
      payload: {
        'name': _name.text.trim(),
        'issuer': _issuer.text.trim(),
        if (credentialId.isNotEmpty) 'credential_id': credentialId,
        if (credentialUrl.isNotEmpty) 'credential_url': credentialUrl,
        if (_issuedDate != null) 'issued_date': _iso(_issuedDate!),
        if (_expiresDate != null) 'expires_date': _iso(_expiresDate!),
      },
    );

    if (saved && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheetShell(
      title: widget.existing == null ? 'Tambah sertifikat' : 'Ubah sertifikat',
      submitLabel: widget.existing == null ? 'Tambah' : 'Simpan',
      onSubmit: _submit,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LabeledField(
              label: 'Nama sertifikat',
              controller: _name,
              hint: 'Misal: AWS Certified Developer',
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Nama wajib diisi.' : null,
            ),
            LabeledField(
              label: 'Penerbit',
              controller: _issuer,
              hint: 'Misal: Amazon Web Services',
              validator: (value) =>
                  (value ?? '').trim().isEmpty ? 'Penerbit wajib diisi.' : null,
            ),
            LabeledField(
              label: 'ID kredensial (opsional)',
              controller: _credentialId,
              hint: 'Nomor sertifikat',
            ),
            LabeledField(
              label: 'Tautan kredensial (opsional)',
              controller: _credentialUrl,
              hint: 'https://…',
              keyboardType: TextInputType.url,
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;

                // Server rule is `url`, which rejects a bare domain.
                final uri = Uri.tryParse(text);
                if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
                  return 'Tautan harus lengkap, contoh https://…';
                }
                return null;
              },
            ),
            _DateRow(
              label: 'Tanggal terbit (opsional)',
              value: _issuedDate,
              onTap: () => _pickDate(isIssued: true),
            ),
            _DateRow(
              label: 'Berlaku sampai (opsional)',
              value: _expiresDate,
              onTap: () => _pickDate(isIssued: false),
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
