import 'package:get/get.dart';

import '../../../data/models/application_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class ApplicationsController extends GetxController {
  ApplicationsController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  /// Server-side `ApplicationStatus` values, in the order a candidate moves
  /// through them. `null` is the "Semua" filter.
  static const List<({String? value, String label})> statusFilters = [
    (value: null, label: 'Semua'),
    (value: 'submitted', label: 'Dikirim'),
    (value: 'reviewed', label: 'Ditinjau'),
    (value: 'shortlisted', label: 'Shortlist'),
    (value: 'interview', label: 'Interview'),
    (value: 'offered', label: 'Ditawari'),
    (value: 'hired', label: 'Diterima'),
    (value: 'rejected', label: 'Ditolak'),
    (value: 'withdrawn', label: 'Dibatalkan'),
  ];

  final EmployeeRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final applications = <ApplicationModel>[].obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();
  final activeStatus = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();

    // Every endpoint behind this screen 401s without a session, so a signed-out
    // user gets the login prompt instead of a wasted request.
    if (isLoggedIn) load();

    // Signing in or out while the tab is alive has to reload it.
    ever(_auth.user, (_) => isLoggedIn ? load() : applications.clear());
  }

  Future<void> load() async {
    if (!isLoggedIn) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _repository.applications(status: activeStatus.value);
      applications.assignAll(page.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      applications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void selectStatus(String? status) {
    if (activeStatus.value == status) return;
    activeStatus.value = status;
    load();
  }

  void open(ApplicationModel application) =>
      Get.toNamed(Routes.APPLICATION_DETAIL, arguments: application.id);

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
