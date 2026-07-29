import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/skill_assessment_repository.dart';

/// One attempt: answer the questions one at a time, submit, then review the
/// same screen with correctness revealed.
class AssessmentQuizController extends GetxController {
  AssessmentQuizController({SkillAssessmentRepository? repository})
      : _repository = repository ?? SkillAssessmentRepository();

  final SkillAssessmentRepository _repository;

  late final int id = Get.arguments as int? ?? 0;

  final detail = Rxn<AssessmentDetail>();
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  /// Local answers keyed by question id, seeded from anything already saved.
  final answers = <int, String>{}.obs;

  /// Question on screen while answering.
  final currentIndex = 0.obs;

  List<AssessmentQuestion> get questions => detail.value?.questions ?? const [];

  bool get isReview => detail.value?.attempt.isCompleted ?? false;

  int get answeredCount =>
      questions.where((q) => (answers[q.id] ?? '').trim().isNotEmpty).length;

  bool get allAnswered =>
      questions.isNotEmpty && answeredCount == questions.length;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (id == 0) {
      errorMessage.value = 'Asesmen tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.detail(id);
      detail.value = result;

      answers.assignAll({
        for (final question in result.questions)
          if ((question.answer ?? '').isNotEmpty) question.id: question.answer!,
      });
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  void setAnswer(int questionId, String value) => answers[questionId] = value;

  void next() {
    if (currentIndex.value < questions.length - 1) currentIndex.value++;
  }

  void prev() {
    if (currentIndex.value > 0) currentIndex.value--;
  }

  void goTo(int index) => currentIndex.value = index;

  Future<void> submit() async {
    if (isSubmitting.value) return;

    if (!allAnswered) {
      AppToast.warning('Jawab semua pertanyaan dulu sebelum mengirim.');
      return;
    }

    isSubmitting.value = true;

    try {
      await _repository.submit(id, answers);
      // Re-fetch so the review shows correctness and the score.
      await load();
      currentIndex.value = 0;
      AppToast.success('Asesmen terkirim.');
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSubmitting.value = false;
    }
  }
}
