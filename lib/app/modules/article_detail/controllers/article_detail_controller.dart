import 'package:get/get.dart';

import '../../../data/models/career_resource_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';

class ArticleDetailController extends GetxController {
  ArticleDetailController({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  final CatalogRepository _repository;

  late final String slug = Get.arguments as String? ?? '';

  final detail = Rxn<CareerResourceDetailModel>();
  final isLoading = true.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (slug.isEmpty) {
      errorMessage.value = 'Artikel tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      detail.value = await _repository.careerResource(slug);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }
}
