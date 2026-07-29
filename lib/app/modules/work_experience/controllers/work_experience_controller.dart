import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/models/profile_record_models.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../profile/controllers/profile_controller.dart';

class WorkExperienceController extends GetxController {
  WorkExperienceController({
    EmployeeRepository? repository,
    CatalogRepository? catalog,
  })  : _repository = repository ?? EmployeeRepository(),
        _catalog = catalog ?? CatalogRepository();

  final EmployeeRepository _repository;
  final CatalogRepository _catalog;

  final records = <WorkExperienceModel>[].obs;
  final meta = AppMeta.empty.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    _loadMeta();
    load();
  }

  Future<void> _loadMeta() async {
    try {
      meta.value = await _catalog.meta();
    } on ApiException catch (_) {
      meta.value = AppMeta.empty;
    }
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      records.assignAll(await _repository.workExperiences());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      records.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save({
    WorkExperienceModel? existing,
    required Map<String, dynamic> payload,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;

    try {
      if (existing == null) {
        await _repository.createWorkExperience(payload);
        AppToast.success('Pengalaman ditambahkan.');
      } else {
        await _repository.updateWorkExperience(existing.id, payload);
        AppToast.success('Pengalaman diperbarui.');
      }

      await load();
      _refreshProfileTab();
      return true;
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> remove(WorkExperienceModel record) async {
    final index = records.indexWhere((row) => row.id == record.id);
    if (index == -1) return;

    records.removeAt(index);

    try {
      await _repository.deleteWorkExperience(record.id);
      AppToast.info('Pengalaman dihapus.');
      _refreshProfileTab();
    } on ApiException catch (error) {
      records.insert(index, record);
      AppToast.error(error.message);
    }
  }

  void _refreshProfileTab() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().load();
    }
  }
}
