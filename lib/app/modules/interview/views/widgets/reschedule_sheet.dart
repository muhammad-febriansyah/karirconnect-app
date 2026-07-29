import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/values/app_colors.dart';
import '../../../../data/models/interview_model.dart';
import '../../controllers/interview_controller.dart';

/// Reason capture for `POST api/v1/interviews/{id}/reschedule`.
///
/// The endpoint also wants 1–5 proposed slots; the controller derives three
/// from the current schedule, so this sheet only collects the reason.
class RescheduleSheet extends StatefulWidget {
  const RescheduleSheet({
    super.key,
    required this.controller,
    required this.interview,
  });

  final InterviewController controller;
  final InterviewModel interview;

  static Future<void> show(
    BuildContext context,
    InterviewController controller,
    InterviewModel interview,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: RescheduleSheet(controller: controller, interview: interview),
      ),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    await widget.controller.requestReschedule(
      widget.interview,
      _reasonController.text.trim(),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Minta jadwal ulang',
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Kami ajukan tiga alternatif waktu di tiga hari berikutnya. '
                'Perekrut akan memilih salah satunya.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  height: 1.4,
                  color: AppColors.mutedForeground,
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                maxLength: 1000,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.foreground,
                ),
                decoration: InputDecoration(
                  hintText: 'Alasan minta jadwal ulang',
                  errorStyle: GoogleFonts.poppins(fontSize: 11.sp),
                ),
                validator: (value) {
                  final reason = (value ?? '').trim();
                  if (reason.isEmpty) return 'Alasan wajib diisi.';
                  return null;
                },
              ),
              SizedBox(height: 4.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Kirim permintaan'),
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
