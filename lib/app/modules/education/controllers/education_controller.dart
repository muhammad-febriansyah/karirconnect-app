import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/profile_record_models.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../profile/controllers/profile_controller.dart';

class EducationController extends GetxController {
  EducationController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  /// `EducationLevel` values. The server validates `level` as a plain
  /// `max:16` string, but only these round-trip to a label on the web.
  static const List<({String value, String label})> levels = [
    (value: 'sma', label: 'SMA / SMK'),
    (value: 'd3', label: 'D3'),
    (value: 'd4', label: 'D4'),
    (value: 's1', label: 'S1'),
    (value: 's2', label: 'S2'),
    (value: 's3', label: 'S3'),
    (value: 'other', label: 'Lainnya'),
  ];

  final EmployeeRepository _repository;

  final records = <EducationModel>[].obs;
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
      records.assignAll(await _repository.educations());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      records.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save({
    EducationModel? existing,
    required Map<String, dynamic> payload,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;

    try {
      if (existing == null) {
        await _repository.createEducation(payload);
        AppToast.success('Pendidikan ditambahkan.');
      } else {
        await _repository.updateEducation(existing.id, payload);
        AppToast.success('Pendidikan diperbarui.');
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

  Future<void> remove(EducationModel record) async {
    final index = records.indexWhere((row) => row.id == record.id);
    if (index == -1) return;

    records.removeAt(index);

    try {
      await _repository.deleteEducation(record.id);
      AppToast.info('Pendidikan dihapus.');
      _refreshProfileTab();
    } on ApiException catch (error) {
      records.insert(index, record);
      AppToast.error(error.message);
    }
  }

  /// The Profil tab shows the counts and the completion percentage, both of
  /// which move when a record is added or removed.
  void _refreshProfileTab() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().load();
    }
  }
}
