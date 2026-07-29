import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/assessment_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/skill_assessment_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

/// The Skill Assessment hub: pick a skill to test, or reopen a past attempt.
class SkillAssessmentController extends GetxController {
  SkillAssessmentController({SkillAssessmentRepository? repository})
      : _repository = repository ?? SkillAssessmentRepository();

  final SkillAssessmentRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final skills = <AssessmentSkill>[].obs;
  final attempts = <AssessmentAttempt>[].obs;

  final isLoading = false.obs;
  final startingSkillId = RxnInt();
  final errorMessage = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    if (isLoggedIn) load();
    ever(_auth.user, (_) {
      if (isLoggedIn) {
        load();
      } else {
        skills.clear();
        attempts.clear();
      }
    });
  }

  Future<void> load() async {
    if (!isLoggedIn) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final overview = await _repository.overview();
      skills.assignAll(overview.skills);
      attempts.assignAll(overview.attempts);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      skills.clear();
      attempts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Start or resume, then open the quiz. Resuming is server-side, so this is
  /// safe to tap on a skill that already has an in-progress attempt.
  Future<void> startSkill(AssessmentSkill skill) async {
    if (startingSkillId.value != null) return;

    startingSkillId.value = skill.id;

    try {
      final attempt = await _repository.start(skill.id);
      await Get.toNamed(Routes.SKILL_ASSESSMENT_QUIZ, arguments: attempt.id);
      // Coming back from the quiz, refresh so a new score shows in the list.
      await load();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      startingSkillId.value = null;
    }
  }

  Future<void> openAttempt(AssessmentAttempt attempt) async {
    await Get.toNamed(Routes.SKILL_ASSESSMENT_QUIZ, arguments: attempt.id);
    await load();
  }

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
