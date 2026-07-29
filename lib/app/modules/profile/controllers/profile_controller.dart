import 'package:get/get.dart';

import '../../../data/models/employee_profile_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class ProfileController extends GetxController {
  ProfileController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final profile = Rxn<EmployeeProfileModel>();
  final missingItems = <ProfileMissingItem>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;
  UserModel? get user => _auth.user.value;

  @override
  void onInit() {
    super.onInit();

    if (isLoggedIn) load();

    ever(_auth.user, (_) {
      if (isLoggedIn) {
        load();
      } else {
        profile.value = null;
        missingItems.clear();
      }
    });
  }

  Future<void> load() async {
    if (!isLoggedIn) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.profile();
      profile.value = result.profile;
      missingItems.assignAll(result.missingItems);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      profile.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logout() => _auth.logout();

  /// Each of these returns to this screen, which then refetches — the edit and
  /// CRUD controllers call back into `load()` on save so the counts and the
  /// completion percentage stay in step.
  void openEdit() => Get.toNamed(Routes.PROFILE_EDIT);
  void openEducations() => Get.toNamed(Routes.EDUCATION);
  void openWorkExperiences() => Get.toNamed(Routes.WORK_EXPERIENCE);
  void openCertifications() => Get.toNamed(Routes.CERTIFICATION);
  void openCvs() => Get.toNamed(Routes.CV);
  void openOnboarding() => Get.toNamed(Routes.PROFILE_ONBOARDING);

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
