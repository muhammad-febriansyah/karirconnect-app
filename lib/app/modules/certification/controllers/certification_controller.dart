import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/profile_record_models.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../profile/controllers/profile_controller.dart';

class CertificationController extends GetxController {
  CertificationController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;

  final records = <CertificationModel>[].obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      records.assignAll(await _repository.certifications());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      records.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save({
    CertificationModel? existing,
    required Map<String, dynamic> payload,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;

    try {
      if (existing == null) {
        await _repository.createCertification(payload);
        AppToast.success('Sertifikat ditambahkan.');
      } else {
        await _repository.updateCertification(existing.id, payload);
        AppToast.success('Sertifikat diperbarui.');
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

  Future<void> remove(CertificationModel record) async {
    final index = records.indexWhere((row) => row.id == record.id);
    if (index == -1) return;

    records.removeAt(index);

    try {
      await _repository.deleteCertification(record.id);
      AppToast.info('Sertifikat dihapus.');
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
