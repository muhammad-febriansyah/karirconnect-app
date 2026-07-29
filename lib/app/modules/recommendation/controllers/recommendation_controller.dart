import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/recommendation_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../routes/app_pages.dart';

class RecommendationController extends GetxController {
  RecommendationController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;

  final items = <RecommendationModel>[].obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  /// Reported by the endpoint. A thin profile is the usual reason the list
  /// comes back empty, so the empty state says so rather than blaming the API.
  final profileCompletion = 0.obs;

  final savedSlugs = <String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.recommendations(limit: 20);
      items.assignAll(result.items);
      profileCompletion.value = result.profileCompletion;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      items.clear();
    } catch (_) {
      // A parse failure here would otherwise leave the list empty and the
      // completion at 0, which renders as "lengkapi profilmu" — actively
      // misleading when the real problem is a payload this client cannot read.
      errorMessage.value = 'Gagal membaca data rekomendasi dari server.';
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Hides a recommendation so it stops coming back. Removed optimistically and
  /// restored at its original index if the call fails.
  Future<void> dismiss(RecommendationModel item) async {
    final index = items.indexWhere((row) => row.job.slug == item.job.slug);
    if (index == -1) return;

    items.removeAt(index);

    try {
      await _repository.dismissRecommendation(item.job.slug);
      AppToast.info('Rekomendasi disembunyikan.');
    } on ApiException catch (error) {
      items.insert(index, item);
      AppToast.error(error.message);
    }
  }

  Future<void> toggleSave(JobModel job) async {
    final wasSaved = savedSlugs.contains(job.slug);

    if (wasSaved) {
      savedSlugs.remove(job.slug);
    } else {
      savedSlugs.add(job.slug);
    }

    try {
      if (wasSaved) {
        await _repository.unsaveJob(job.slug);
        AppToast.info('Lowongan dihapus dari simpanan.');
      } else {
        await _repository.saveJob(job.slug);
        AppToast.success('Lowongan disimpan.');
      }
    } on ApiException catch (error) {
      if (wasSaved) {
        savedSlugs.add(job.slug);
      } else {
        savedSlugs.remove(job.slug);
      }
      AppToast.error(error.message);
    }
  }

  void openJob(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);
}
