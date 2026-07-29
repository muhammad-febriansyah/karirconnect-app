import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/ai_interview_model.dart';
import '../controllers/interview_run_controller.dart';

/// One practice session: answer mode, an analysing wait, then the AI result —
/// all on this screen, switched by `controller.phase`.
class InterviewRunView extends GetView<InterviewRunController> {
  const InterviewRunView({super.key});

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
              children: const [
                GradientHeaderBar(title: 'Interview'),
                Expanded(child: SectionLoader()),
              ],
            );
          }

          final error = controller.errorMessage.value;
          if (error != null) {
            return Column(
              children: [
                const GradientHeaderBar(title: 'Interview'),
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

          switch (controller.phase) {
            case InterviewPhase.result:
              return const _Result();
            case InterviewPhase.analyzing:
              return const _Analyzing();
            case InterviewPhase.run:
              return const _Run();
          }
        }),
      ),
    );
  }
}

// ---- Answer mode ----------------------------------------------------------

class _Run extends GetView<InterviewRunController> {
  const _Run();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final questions = controller.questions;
      final index = controller.currentIndex.value;

      if (questions.isEmpty) {
        return Column(
          children: [
            const GradientHeaderBar(title: 'Interview'),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(AppSpacing.gutter.w),
                children: const [
                  EmptyState(
                    icon: Iconsax.microphone_2,
                    message: 'Pertanyaan belum siap. Coba muat ulang.',
                  ),
                ],
              ),
            ),
          ],
        );
      }

      final question = questions[index];
      final total = questions.length;

      return Column(
        children: [
          GradientHeaderBar(
            title: 'Latihan interview',
            subtitle: 'Pertanyaan ${index + 1} dari $total',
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
                Row(
                  children: [
                    const _CoachAvatar(),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: Text(
                        'Pewawancara',
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                  ],
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
                SizedBox(height: AppSpacing.lg.h),
                _AnswerField(key: ValueKey(question.id), question: question),
              ],
            ),
          ),
          _RunFooter(index: index, total: total),
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

class _AnswerField extends StatefulWidget {
  const _AnswerField({super.key, required this.question});

  final InterviewQuestion question;

  @override
  State<_AnswerField> createState() => _AnswerFieldState();
}

class _AnswerFieldState extends State<_AnswerField> {
  final _controller = Get.find<InterviewRunController>();
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
      minLines: 5,
      maxLines: 12,
      maxLength: 8000,
      onChanged: (value) => _controller.setAnswer(widget.question.id, value),
      style: GoogleFonts.poppins(
        fontSize: 13.sp,
        height: 1.5,
        color: AppColors.foreground,
      ),
      decoration: const InputDecoration(
        counterText: '',
        hintText: 'Tulis jawabanmu selengkap mungkin…',
      ),
    );
  }
}

class _RunFooter extends GetView<InterviewRunController> {
  const _RunFooter({required this.index, required this.total});

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
                child: Obx(
                  () => ElevatedButton(
                    onPressed:
                        controller.isSaving.value ? null : controller.saveAndNext,
                    child: controller.isSaving.value
                        ? SizedBox(
                            width: 18.w,
                            height: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(isLast ? 'Simpan & selesai' : 'Simpan & lanjut'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Analysing ------------------------------------------------------------

class _Analyzing extends GetView<InterviewRunController> {
  const _Analyzing();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const GradientHeaderBar(title: 'Analisis'),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.gutter.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72.w,
                    height: 72.w,
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.magicpen,
                      size: 30.sp,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Text(
                    'Menganalisis jawabanmu…',
                    style: GoogleFonts.poppins(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandNavy,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sm.h),
                  Text(
                    'AI sedang menilai jawaban interview-mu. Ini biasanya '
                    'butuh beberapa detik.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: AppColors.mutedForeground,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl.h),
                  Obx(
                    () => ElevatedButton.icon(
                      onPressed: controller.isRefreshing.value
                          ? null
                          : controller.refreshResult,
                      icon: controller.isRefreshing.value
                          ? SizedBox(
                              width: 16.w,
                              height: 16.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Iconsax.refresh, size: 16.sp),
                      label: Text(
                        'Lihat hasil',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---- Result ---------------------------------------------------------------

class _Result extends GetView<InterviewRunController> {
  const _Result();

  @override
  Widget build(BuildContext context) {
    final analysis = controller.result.value!.analysis!;

    return Column(
      children: [
        const GradientHeaderBar(
          title: 'Hasil interview',
          subtitle: 'Analisis AI atas jawabanmu',
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
              _ScoreHero(score: analysis.overallScore ?? 0),
              if ((analysis.summary ?? '').isNotEmpty) ...[
                SizedBox(height: AppSpacing.xl.h),
                _Block(
                  icon: Iconsax.document_text,
                  title: 'Ringkasan',
                  child: Text(
                    analysis.summary!,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      height: 1.55,
                      color: AppColors.foreground.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
              if (analysis.strengths.isNotEmpty) ...[
                SizedBox(height: AppSpacing.md.h),
                _PointList(
                  icon: Iconsax.tick_circle,
                  title: 'Kekuatan',
                  tone: AppColors.success,
                  points: analysis.strengths,
                ),
              ],
              if (analysis.weaknesses.isNotEmpty) ...[
                SizedBox(height: AppSpacing.md.h),
                _PointList(
                  icon: Iconsax.info_circle,
                  title: 'Bisa diperbaiki',
                  tone: AppColors.warning,
                  points: analysis.weaknesses,
                ),
              ],
              if ((analysis.recommendation ?? '').isNotEmpty) ...[
                SizedBox(height: AppSpacing.md.h),
                _Block(
                  icon: Iconsax.lamp_on,
                  title: 'Rekomendasi',
                  child: Text(
                    analysis.recommendation!,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      height: 1.55,
                      color: AppColors.foreground.withValues(alpha: 0.85),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
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
            passed ? 'Interview yang kuat!' : 'Terus berlatih',
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
            'skor keseluruhan dari 100',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17.sp, color: AppColors.primary),
              SizedBox(width: AppSpacing.sm.w),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md.h),
          child,
        ],
      ),
    );
  }
}

class _PointList extends StatelessWidget {
  const _PointList({
    required this.icon,
    required this.title,
    required this.tone,
    required this.points,
  });

  final IconData icon;
  final String title;
  final Color tone;
  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          ...points.map(
            (point) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: Icon(icon, size: 15.sp, color: tone),
                  ),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      point,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5.sp,
                        height: 1.45,
                        color: AppColors.foreground.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34.w,
      height: 34.w,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(Iconsax.user, size: 16.sp, color: Colors.white),
    );
  }
}
