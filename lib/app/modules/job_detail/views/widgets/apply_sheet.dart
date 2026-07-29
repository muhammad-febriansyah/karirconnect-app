import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/values/app_colors.dart';
import '../../../../data/models/job_detail_model.dart';
import '../../controllers/job_detail_controller.dart';

/// Cover letter, expected salary and the employer's screening questions.
///
/// Eligibility is not pre-judged here — `SubmitApplicationAction` owns every
/// guard (published, duplicate, own company, 60% profile completion) and its
/// message is what the user sees on failure.
class ApplySheet extends StatelessWidget {
  const ApplySheet({super.key, required this.controller});

  final JobDetailController controller;

  static Future<void> show(
    BuildContext context,
    JobDetailController controller,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ApplySheet(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = controller.detail.value?.screeningQuestions ?? const [];

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
              'Lamar lowongan',
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.brandNavy,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'CV utama dari profilmu akan dilampirkan otomatis.',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                color: AppColors.mutedForeground,
              ),
            ),
            SizedBox(height: 16.h),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label('Surat lamaran (opsional)'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: controller.coverLetterController,
                      maxLines: 5,
                      maxLength: 16000,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: AppColors.foreground,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Ceritakan kenapa kamu cocok untuk posisi ini',
                      ),
                    ),
                    SizedBox(height: 14.h),
                    _Label('Ekspektasi gaji (opsional)'),
                    SizedBox(height: 6.h),
                    TextField(
                      controller: controller.expectedSalaryController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: AppColors.foreground,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: 9000000',
                      ),
                    ),
                    if (questions.isNotEmpty) ...[
                      SizedBox(height: 20.h),
                      Text(
                        'Pertanyaan dari perekrut',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      ...questions.map(
                        (question) => _Question(
                          question: question,
                          controller: controller,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Obx(
              () => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isApplying.value
                      ? null
                      : () async {
                          final sent = await controller.submit();
                          if (sent && context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                  child: controller.isApplying.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Kirim lamaran'),
                ),
              ),
            ),
            SizedBox(height: 12.h),
          ],
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

class _Question extends StatelessWidget {
  const _Question({required this.question, required this.controller});

  final ScreeningQuestion question;
  final JobDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.brandNavy,
              ),
              children: [
                TextSpan(text: question.question),
                if (question.isRequired)
                  TextSpan(
                    text: ' *',
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.destructive,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          _input(),
        ],
      ),
    );
  }

  Widget _input() {
    if (question.isYesNo) {
      return Obx(
        () => _Choices(
          options: const ['Ya', 'Tidak'],
          selected: {
            if (controller.answers[question.id] is String)
              controller.answers[question.id] as String,
          },
          onTap: (option) => controller.setAnswer(question.id, option),
        ),
      );
    }

    if (question.isChoice) {
      return Obx(() {
        final answer = controller.answers[question.id];
        final selected = question.isMultiChoice
            ? ((answer as List?)?.cast<String>().toSet() ?? <String>{})
            : {if (answer is String) answer};

        return _Choices(
          options: question.options,
          selected: selected,
          onTap: (option) => question.isMultiChoice
              ? controller.toggleMultiAnswer(question.id, option)
              : controller.setAnswer(question.id, option),
        );
      });
    }

    return TextField(
      keyboardType:
          question.isNumber ? TextInputType.number : TextInputType.multiline,
      inputFormatters:
          question.isNumber ? [FilteringTextInputFormatter.digitsOnly] : null,
      maxLines: question.isNumber ? 1 : 3,
      onChanged: (value) => controller.setAnswer(question.id, value),
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        color: AppColors.foreground,
      ),
      decoration: const InputDecoration(hintText: 'Jawabanmu'),
    );
  }
}

class _Choices extends StatelessWidget {
  const _Choices({
    required this.options,
    required this.selected,
    required this.onTap,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: options.map((option) {
        final active = selected.contains(option);

        return Material(
          color: active ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: InkWell(
            onTap: () => onTap(option),
            borderRadius: BorderRadius.circular(AppRadius.control),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 8.h),
              child: Text(
                option,
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
    );
  }
}
