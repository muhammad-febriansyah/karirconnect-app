import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_toast.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../core/widgets/form_fields.dart';
import '../../controllers/company_detail_controller.dart';

/// `POST companies/{slug}/reviews`. A focused subset of the web's fields — the
/// overall rating, a headline, employment context, pros/cons, and the two
/// flags — which is a complete, valid submission (the sub-ratings are all
/// optional server-side).
class ReviewSheet extends StatefulWidget {
  const ReviewSheet({super.key, required this.controller});

  final CompanyDetailController controller;

  static Future<void> show(
    BuildContext context,
    CompanyDetailController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ReviewSheet(controller: controller),
      ),
    );
  }

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  final _titleController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _prosController = TextEditingController();
  final _consController = TextEditingController();

  int _rating = 0;
  String _employment = 'current';
  bool _wouldRecommend = true;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _titleController.dispose();
    _jobTitleController.dispose();
    _prosController.dispose();
    _consController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      AppToast.warning('Beri rating dulu.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      AppToast.warning('Judul review wajib diisi.');
      return;
    }

    final pros = _prosController.text.trim();
    final cons = _consController.text.trim();
    final jobTitle = _jobTitleController.text.trim();

    final ok = await widget.controller.submitReview({
      'title': _titleController.text.trim(),
      'rating': _rating,
      'employment_status': _employment,
      'would_recommend': _wouldRecommend,
      'is_anonymous': _isAnonymous,
      if (jobTitle.isNotEmpty) 'job_title': jobTitle,
      if (pros.isNotEmpty) 'pros': pros,
      if (cons.isNotEmpty) 'cons': cons,
    });

    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => FormSheetShell(
        title: 'Tulis review',
        subtitle: 'Bagikan pengalamanmu di ${widget.controller.companyName}.',
        submitLabel:
            widget.controller.isReviewing.value ? 'Mengirim…' : 'Kirim review',
        onSubmit: _submit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label('Rating keseluruhan'),
            SizedBox(height: AppSpacing.sm.h),
            _StarPicker(
              value: _rating,
              onChanged: (value) => setState(() => _rating = value),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Judul'),
            SizedBox(height: 6.h),
            TextField(
              controller: _titleController,
              maxLength: 200,
              style: _inputStyle,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Ringkas pengalamanmu dalam satu kalimat',
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Status'),
            SizedBox(height: AppSpacing.sm.h),
            Row(
              children: [
                _Choice(
                  label: 'Karyawan saat ini',
                  active: _employment == 'current',
                  onTap: () => setState(() => _employment = 'current'),
                ),
                SizedBox(width: AppSpacing.sm.w),
                _Choice(
                  label: 'Mantan karyawan',
                  active: _employment == 'former',
                  onTap: () => setState(() => _employment = 'former'),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Posisi (opsional)'),
            SizedBox(height: 6.h),
            TextField(
              controller: _jobTitleController,
              maxLength: 120,
              style: _inputStyle,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Misal: Backend Engineer',
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Kelebihan (opsional)'),
            SizedBox(height: 6.h),
            TextField(
              controller: _prosController,
              maxLines: 3,
              maxLength: 2000,
              style: _inputStyle,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Hal yang kamu suka',
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            _Label('Kekurangan (opsional)'),
            SizedBox(height: 6.h),
            TextField(
              controller: _consController,
              maxLines: 3,
              maxLength: 2000,
              style: _inputStyle,
              decoration: const InputDecoration(
                counterText: '',
                hintText: 'Hal yang bisa lebih baik',
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            _Toggle(
              label: 'Merekomendasikan ke teman',
              value: _wouldRecommend,
              onChanged: (value) => setState(() => _wouldRecommend = value),
            ),
            _Toggle(
              label: 'Kirim sebagai anonim',
              value: _isAnonymous,
              onChanged: (value) => setState(() => _isAnonymous = value),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle get _inputStyle =>
      GoogleFonts.poppins(fontSize: 13.sp, color: AppColors.foreground);
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        final filled = star <= value;

        return Padding(
          padding: EdgeInsets.only(right: AppSpacing.sm.w),
          child: InkResponse(
            onTap: () => onChanged(star),
            radius: 24.r,
            child: Icon(
              filled ? Iconsax.star1 : Iconsax.star,
              size: 32.sp,
              color: filled ? AppColors.warning : AppColors.mutedForeground,
            ),
          ),
        );
      }),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: active ? AppColors.accent : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md.h),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: active ? AppColors.primary : AppColors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.brandNavy,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
          ),
        ],
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
