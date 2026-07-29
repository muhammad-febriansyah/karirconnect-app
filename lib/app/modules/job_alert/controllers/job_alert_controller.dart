import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/job_alert_model.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';

class JobAlertController extends GetxController {
  JobAlertController({
    EmployeeRepository? repository,
    CatalogRepository? catalog,
  })  : _repository = repository ?? EmployeeRepository(),
        _catalog = catalog ?? CatalogRepository();

  /// The only values `JobAlertRequest` accepts for `frequency`.
  static const List<({String value, String label})> frequencies = [
    (value: 'instant', label: 'Instan'),
    (value: 'daily', label: 'Harian'),
    (value: 'weekly', label: 'Mingguan'),
  ];

  final EmployeeRepository _repository;
  final CatalogRepository _catalog;

  final alerts = <JobAlertModel>[].obs;
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
      alerts.assignAll(await _repository.jobAlerts());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      alerts.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates when [existing] is null, otherwise updates it in place.
  Future<bool> save({
    JobAlertModel? existing,
    required Map<String, dynamic> payload,
  }) async {
    if (isSaving.value) return false;

    isSaving.value = true;

    try {
      if (existing == null) {
        final created = await _repository.createJobAlert(payload);
        alerts.insert(0, created);
        AppToast.success('Alert dibuat.');
      } else {
        final updated = await _repository.updateJobAlert(existing.id, payload);
        final index = alerts.indexWhere((row) => row.id == existing.id);
        if (index != -1) alerts[index] = updated;
        AppToast.success('Alert diperbarui.');
      }
      return true;
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  /// The API has no dedicated toggle, so this is a full update carrying the
  /// alert's own fields with `is_active` flipped.
  Future<void> toggleActive(JobAlertModel alert) async {
    final index = alerts.indexWhere((row) => row.id == alert.id);
    if (index == -1) return;

    final optimistic = alert.copyWith(isActive: !alert.isActive);
    alerts[index] = optimistic;

    try {
      alerts[index] = await _repository.updateJobAlert(
        alert.id,
        optimistic.toPayload(),
      );
    } on ApiException catch (error) {
      alerts[index] = alert;
      AppToast.error(error.message);
    }
  }

  Future<void> remove(JobAlertModel alert) async {
    final index = alerts.indexWhere((row) => row.id == alert.id);
    if (index == -1) return;

    alerts.removeAt(index);

    try {
      await _repository.deleteJobAlert(alert.id);
      AppToast.info('Alert dihapus.');
    } on ApiException catch (error) {
      alerts.insert(index, alert);
      AppToast.error(error.message);
    }
  }

  /// Shows what the alert would match right now, so the user can tune it
  /// without waiting for a digest.
  Future<void> preview(JobAlertModel alert) async {
    try {
      final matches = await _repository.previewJobAlert(alert.id);

      AppToast.info(
        matches.isEmpty
            ? 'Belum ada lowongan yang cocok dengan alert ini.'
            : '${matches.length} lowongan cocok sekarang.',
        title: alert.name,
      );
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }
}
