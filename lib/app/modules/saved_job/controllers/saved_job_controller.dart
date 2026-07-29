import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/job_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../routes/app_pages.dart';

class SavedJobController extends GetxController {
  SavedJobController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;

  final jobs = <JobModel>[].obs;
  final isLoading = true.obs;
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
      final page = await _repository.savedJobs(perPage: 50);
      jobs.assignAll(page.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      jobs.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Removes optimistically so the row disappears immediately, and puts it back
  /// at its original index if the call fails.
  Future<void> unsave(JobModel job) async {
    final index = jobs.indexWhere((row) => row.slug == job.slug);
    if (index == -1) return;

    jobs.removeAt(index);

    try {
      await _repository.unsaveJob(job.slug);
      AppToast.info('Lowongan dihapus dari simpanan.');
    } on ApiException catch (error) {
      jobs.insert(index, job);
      AppToast.error(error.message);
    }
  }

  void openJob(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);
}
