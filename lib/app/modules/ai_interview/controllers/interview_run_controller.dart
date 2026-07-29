import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/ai_interview_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/ai_interview_repository.dart';

/// One practice session: answer the questions in order, finalise, then read the
/// AI analysis. Three phases — [InterviewPhase].
enum InterviewPhase { run, analyzing, result }

class InterviewRunController extends GetxController {
  InterviewRunController({AiInterviewRepository? repository})
      : _repository = repository ?? AiInterviewRepository();

  final AiInterviewRepository _repository;

  late final int id = Get.arguments as int? ?? 0;

  final detail = Rxn<InterviewDetail>();
  final result = Rxn<InterviewResult>();

  final isLoading = true.obs;
  final isSaving = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = RxnString();

  /// Local answers keyed by question id, seeded from any already submitted.
  final answers = <int, String>{}.obs;
  final currentIndex = 0.obs;

  List<InterviewQuestion> get questions => detail.value?.questions ?? const [];

  InterviewPhase get phase {
    final analysis = result.value?.analysis;
    if (analysis != null) return InterviewPhase.result;

    final session = detail.value?.session;
    if (session != null && (session.isCompleted || session.isAnalyzing)) {
      return InterviewPhase.analyzing;
    }

    return InterviewPhase.run;
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (id == 0) {
      errorMessage.value = 'Sesi tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.detail(id);
      detail.value = result;
      answers.assignAll({
        for (final q in result.questions)
          if ((q.answer ?? '').isNotEmpty) q.id: q.answer!,
      });

      // A finished session opens straight to its analysis.
      if (result.session.isCompleted || result.session.isAnalyzing) {
        await _fetchResult();
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void setAnswer(int questionId, String value) => answers[questionId] = value;

  void prev() {
    if (currentIndex.value > 0) currentIndex.value--;
  }

  /// Save the current answer, then advance — or finalise on the last question.
  Future<void> saveAndNext() async {
    final question = questions[currentIndex.value];
    final answer = (answers[question.id] ?? '').trim();

    if (answer.isEmpty) {
      AppToast.warning('Tulis jawabanmu dulu.');
      return;
    }

    if (isSaving.value) return;
    isSaving.value = true;

    try {
      await _repository.answer(id, question.id, answer);

      if (currentIndex.value < questions.length - 1) {
        currentIndex.value++;
      } else {
        await _repository.complete(id);
        await _fetchResult();
      }
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSaving.value = false;
    }
  }

  /// Re-poll the result while the analysis is still being generated.
  Future<void> refreshResult() async {
    if (isRefreshing.value) return;
    isRefreshing.value = true;

    try {
      await _fetchResult();
      if (result.value?.analysis == null) {
        AppToast.info('Analisis masih diproses. Coba lagi sebentar.');
      }
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _fetchResult() async {
    final fetched = await _repository.result(id);
    result.value = fetched;
    // Keep the session status in step so `phase` reflects analyzing/completed.
    final current = detail.value;
    if (current != null) {
      detail.value = InterviewDetail(
        session: fetched.session,
        questions: current.questions,
      );
    }
  }
}
