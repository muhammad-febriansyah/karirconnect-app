import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/ai_interview_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/ai_interview_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

/// AI Interview Practice hub: start a new practice run or reopen a past one.
class AiInterviewController extends GetxController {
  AiInterviewController({AiInterviewRepository? repository})
      : _repository = repository ?? AiInterviewRepository();

  final AiInterviewRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final sessions = <InterviewSession>[].obs;

  final isLoading = false.obs;
  final isStarting = false.obs;
  final errorMessage = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    if (isLoggedIn) load();
    ever(_auth.user, (_) => isLoggedIn ? load() : sessions.clear());
  }

  Future<void> load() async {
    if (!isLoggedIn) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      sessions.assignAll(await _repository.sessions());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      sessions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startPractice() async {
    if (isStarting.value) return;

    isStarting.value = true;

    try {
      final detail = await _repository.startPractice();
      await Get.toNamed(Routes.AI_INTERVIEW_RUN, arguments: detail.session.id);
      await load();
    } on ApiException catch (error) {
      // The quota-exceeded 422 lands here with the server's message.
      AppToast.error(error.message);
    } finally {
      isStarting.value = false;
    }
  }

  Future<void> openSession(InterviewSession session) async {
    await Get.toNamed(Routes.AI_INTERVIEW_RUN, arguments: session.id);
    await load();
  }

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
