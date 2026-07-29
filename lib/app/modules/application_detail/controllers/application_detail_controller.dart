import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/application_detail_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';

class ApplicationDetailController extends GetxController {
  ApplicationDetailController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  /// Statuses the server refuses to withdraw from — the process is already over
  /// there, so the button is hidden rather than offered and rejected.
  static const Set<String> terminalStatuses = {
    'hired',
    'rejected',
    'withdrawn',
  };

  final EmployeeRepository _repository;

  late final int id = (Get.arguments as int?) ?? 0;

  final detail = Rxn<ApplicationDetailModel>();
  final isLoading = true.obs;
  final isWithdrawing = false.obs;
  final errorMessage = RxnString();

  bool get canWithdraw {
    final status = detail.value?.application.status;
    return status != null && !terminalStatuses.contains(status);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (id == 0) {
      errorMessage.value = 'Lamaran tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      detail.value = await _repository.application(id);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> withdraw() async {
    if (isWithdrawing.value) return;

    isWithdrawing.value = true;

    try {
      await _repository.withdrawApplication(id);
      AppToast.success('Lamaran dibatalkan.');
      await load();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isWithdrawing.value = false;
    }
  }
}
