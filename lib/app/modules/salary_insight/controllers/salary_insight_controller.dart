import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/models/salary_insight_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class SalaryInsightController extends GetxController {
  SalaryInsightController({
    CatalogRepository? repository,
    EmployeeRepository? employee,
  })  : _repository = repository ?? CatalogRepository(),
        _employee = employee ?? EmployeeRepository();

  final CatalogRepository _repository;
  final EmployeeRepository _employee;
  final AuthService _auth = Get.find<AuthService>();

  final data = SalaryInsightData.empty.obs;
  final meta = AppMeta.empty.obs;

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = RxnString();

  final activeCategoryId = RxnInt();
  final activeExperience = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    _loadMeta();
    load();
  }

  Future<void> _loadMeta() async {
    try {
      meta.value = await _repository.meta();
    } on ApiException catch (_) {
      meta.value = AppMeta.empty;
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      data.value = await _repository.salaryInsights(
        jobCategoryId: activeCategoryId.value,
        experienceLevel: activeExperience.value,
      );
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      data.value = SalaryInsightData.empty;
    } finally {
      isLoading.value = false;
    }
  }

  void selectCategory(int? categoryId) {
    if (activeCategoryId.value == categoryId) return;
    activeCategoryId.value = categoryId;
    load();
  }

  void selectExperience(String? level) {
    // Tapping the active level clears it.
    activeExperience.value = activeExperience.value == level ? null : level;
    load();
  }

  void requireLogin() => Get.toNamed(Routes.LOGIN);

  /// `POST salary-submissions`. Individual reports carry `sample_size: 1` and a
  /// fixed source; the server moderates before the figure joins the aggregate.
  Future<bool> submitSalary(Map<String, dynamic> payload) async {
    if (isSubmitting.value) return false;
    isSubmitting.value = true;

    try {
      await _employee.submitSalary({
        ...payload,
        'sample_size': 1,
        'source': 'Pengalaman pribadi',
      });
      await load();
      AppToast.success('Data gaji terkirim. Akan ditinjau sebelum tayang.');
      return true;
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }
}
