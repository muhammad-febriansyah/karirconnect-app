import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/assessment_model.dart';
import '../controllers/assessment_quiz_controller.dart';

/// One attempt. While `status` is in-progress the questions are answered one at
/// a time; once submitted the same screen becomes a scored review.
class AssessmentQuizView extends GetView<AssessmentQuizController> {
  const AssessmentQuizView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          if (controller.isLoading.value) {
            return Column(
              children: [
                const GradientHeaderBar(title: 'Asesmen'),
                const Expanded(child: SectionLoader()),
              ],
            );
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return Column(
              children: [
                const GradientHeaderBar(title: 'Asesmen'),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(AppSpacing.gutter.w),
                    children: [
                      ErrorState(message: error, onRetry: controller.load),
                    ],
                  ),
                ),
              ],
            );
          }

          return controller.isReview ? const _Review() : const _Quiz();
        }),
      ),
    );
  }
}

// ---- Answer mode ----------------------------------------------------------

class _Quiz extends GetView<AssessmentQuizController> {
  const _Quiz();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final questions = controller.questions;
      final index = controller.currentIndex.value;
      final question = questions[index];
      final total = questions.length;

      return Column(
        children: [
          GradientHeaderBar(
            title: controller.detail.value?.attempt.skill ?? 'Asesmen',
            subtitle: 'Soal ${index + 1} dari $total',
          ),
          _ProgressBar(value: (index + 1) / total),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter.w,
                AppSpacing.xl.h,
                AppSpacing.gutter.w,
                AppSpacing.xl.h,
              ),
              children: [
                _QuestionText(question: question),
                SizedBox(height: AppSpacing.lg.h),
                if (question.isChoice)
                  _Choices(question: question)
                else
                  // Keyed by question id so its State — and the text controller
                  // inside it — is rebuilt when the question changes.
                  _FreeText(key: ValueKey(question.id), question: question),
              ],
            ),
          ),
          _QuizFooter(index: index, total: total),
        ],
      );
    });
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter.w,
        AppSpacing.lg.h,
        AppSpacing.gutter.w,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: LinearProgressIndicator(
          value: value,
          minHeight: 6.h,
          backgroundColor: AppColors.surfaceSoft,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.question});

  final AssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (question.difficulty != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              Formatters.status(question.difficulty),
              style: GoogleFonts.poppins(
                fontSize: 10.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.accentForeground,
              ),
            ),
          ),
        SizedBox(height: AppSpacing.md.h),
        Text(
          question.question,
          style: GoogleFonts.poppins(
            fontSize: 16.sp,
            height: 1.45,
            fontWeight: FontWeight.w600,
            color: AppColors.brandNavy,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _Choices extends GetView<AssessmentQuizController> {
  const _Choices({required this.question});

  final AssessmentQuestion question;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.answers[question.id];

      return Column(
        children: question.options.map((option) {
          final active = selected == option;

          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md.h),
            child: Material(
              color: active ? AppColors.accent : AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: InkWell(
                onTap: () => controller.setAnswer(question.id, option),
                borderRadius: BorderRadius.circular(AppRadius.card),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg.w),
                  child: Row(
                    children: [
                      Icon(
                        active
                            ? Iconsax.tick_circle5
                            : Iconsax.record_circle,
                        size: 20.sp,
                        color: active
                            ? AppColors.primary
                            : AppColors.mutedForeground,
                      ),
                      SizedBox(width: AppSpacing.md.w),
                      Expanded(
                        child: Text(
                          option,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            height: 1.4,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.w500,
                            color: active
                                ? AppColors.brandNavy
                                : AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _FreeText extends StatefulWidget {
  const _FreeText({super.key, required this.question});

  final AssessmentQuestion question;

  @override
  State<_FreeText> createState() => _FreeTextState();
}

class _FreeTextState extends State<_FreeText> {
  final _controller = Get.find<AssessmentQuizController>();
  late final TextEditingController _text = TextEditingController(
    text: _controller.answers[widget.question.id] ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _text,
      minLines: 4,
      maxLines: 10,
      maxLength: 4000,
      onChanged: (value) =>
          _controller.setAnswer(widget.question.id, value),
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        height: 1.5,
        color: AppColors.foreground,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: widget.question.type == 'code'
            ? 'Tulis jawaban atau potongan kode di sini'
            : 'Tulis jawabanmu di sini',
      ),
    );
  }
}

class _QuizFooter extends GetView<AssessmentQuizController> {
  const _QuizFooter({required this.index, required this.total});

  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isLast = index == total - 1;

    return Container(
      color: AppColors.surfaceSoft,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter.w,
            AppSpacing.md.h,
            AppSpacing.gutter.w,
            AppSpacing.md.h,
          ),
          child: Row(
            children: [
              if (index > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.prev,
                    child: const Text('Sebelumnya'),
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
              ],
              Expanded(
                child: isLast
                    ? Obx(
                        () => ElevatedButton(
                          onPressed: controller.isSubmitting.value
                              ? null
                              : controller.submit,
                          child: controller.isSubmitting.value
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Kirim jawaban'),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: controller.next,
                        child: const Text('Berikutnya'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Review mode ----------------------------------------------------------

class _Review extends GetView<AssessmentQuizController> {
  const _Review();

  @override
  Widget build(BuildContext context) {
    final attempt = controller.detail.value!.attempt;
    final questions = controller.questions;

    return Column(
      children: [
        GradientHeaderBar(
          title: attempt.skill ?? 'Hasil asesmen',
          subtitle: 'Hasil asesmen',
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.gutter.w,
              AppSpacing.xl.h,
              AppSpacing.gutter.w,
              AppSpacing.section.h,
            ),
            children: [
              _ScoreHero(attempt: attempt),
              SizedBox(height: AppSpacing.xl.h),
              Text(
                'Pembahasan',
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: AppSpacing.md.h),
              ...questions.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.md.h),
                      child: _ReviewCard(
                        number: entry.key + 1,
                        question: entry.value,
                        answer: controller.answers[entry.value.id] ?? '',
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.attempt});

  final AssessmentAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final score = attempt.score?.round() ?? 0;
    final passed = score >= 70;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl.w),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Text(
            passed ? 'Selamat, kamu lulus!' : 'Terus berlatih',
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: AppSpacing.sm.h),
          Text(
            '$score',
            style: GoogleFonts.poppins(
              fontSize: 48.sp,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          Text(
            'dari 100',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: AppSpacing.lg.h),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.w,
              vertical: AppSpacing.sm.h,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              '${attempt.correctAnswers ?? 0} dari ${attempt.totalQuestions} jawaban benar',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.number,
    required this.question,
    required this.answer,
  });

  final int number;
  final AssessmentQuestion question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final correct = question.isCorrect ?? false;
    final tone = correct ? AppColors.success : AppColors.destructive;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                correct ? Iconsax.tick_circle5 : Iconsax.close_circle5,
                size: 18.sp,
                color: tone,
              ),
              SizedBox(width: AppSpacing.sm.w),
              Expanded(
                child: Text(
                  '$number. ${question.question}',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          _Answer(
            label: 'Jawabanmu',
            value: answer.isEmpty ? '(kosong)' : answer,
            tone: tone,
          ),
          if (!correct && (question.correctAnswer ?? '').isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm.h),
            _Answer(
              label: 'Jawaban benar',
              value: question.correctAnswer!,
              tone: AppColors.success,
            ),
          ],
        ],
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md.w),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: tone,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12.5.sp,
              height: 1.4,
              color: AppColors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
