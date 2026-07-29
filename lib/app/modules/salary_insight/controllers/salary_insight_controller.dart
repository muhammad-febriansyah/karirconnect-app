import 'package:get/get.dart';

import '../../../data/models/meta_model.dart';
import '../../../data/models/salary_insight_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';

class SalaryInsightController extends GetxController {
  SalaryInsightController({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  final data = SalaryInsightData.empty.obs;
  final meta = AppMeta.empty.obs;

  final isLoading = true.obs;
  final errorMessage = RxnString();

  final activeCategoryId = RxnInt();
  final activeExperience = RxnString();

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
}
