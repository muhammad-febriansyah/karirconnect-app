import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/company_detail_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class CompanyDetailController extends GetxController {
  CompanyDetailController({
    CatalogRepository? catalog,
    EmployeeRepository? employee,
  })  : _catalog = catalog ?? CatalogRepository(),
        _employee = employee ?? EmployeeRepository();

  final CatalogRepository _catalog;
  final EmployeeRepository _employee;
  final AuthService _auth = Get.find<AuthService>();

  late final String slug = Get.arguments as String? ?? '';

  final detail = Rxn<CompanyDetailModel>();
  final jobs = <JobModel>[].obs;
  final reviews = <CompanyReviewModel>[].obs;

  final reviewTotal = 0.obs;
  final avgRating = 0.0.obs;

  final isLoading = true.obs;
  final isReviewing = false.obs;
  final errorMessage = RxnString();
  final savedSlugs = <String>{}.obs;

  bool get isLoggedIn => _auth.isLoggedIn;
  String get companyName => detail.value?.company.name ?? 'perusahaan ini';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (slug.isEmpty) {
      errorMessage.value = 'Perusahaan tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    // The three reads are independent. Only the profile itself is fatal — a
    // company with no jobs or no reviews is a normal state, not an error.
    await Future.wait([_loadCompany(), _loadJobs(), _loadReviews()]);

    isLoading.value = false;
  }

  Future<void> _loadCompany() async {
    try {
      detail.value = await _catalog.company(slug);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    }
  }

  Future<void> _loadJobs() async {
    try {
      final page = await _catalog.companyJobs(slug, perPage: 10);
      jobs.assignAll(page.items);
    } on ApiException catch (_) {
      jobs.clear();
    }
  }

  Future<void> _loadReviews() async {
    try {
      final result = await _catalog.companyReviews(slug);
      reviews.assignAll(result.items);
      reviewTotal.value = result.total;
      avgRating.value = result.avgRating;
    } on ApiException catch (_) {
      reviews.clear();
    }
  }

  void openJob(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);

  /// Returns true on success so the sheet can close itself. A rejected review
  /// (no verified tie to the company) 422s and the message is surfaced.
  Future<bool> submitReview(Map<String, dynamic> payload) async {
    if (isReviewing.value) return false;
    isReviewing.value = true;

    try {
      await _employee.submitReview(slug, payload);
      await _loadReviews();
      AppToast.success('Review terkirim. Akan ditinjau sebelum tayang.');
      return true;
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return false;
    } finally {
      isReviewing.value = false;
    }
  }

  Future<void> toggleSave(JobModel job) async {
    if (!_auth.isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final wasSaved = savedSlugs.contains(job.slug);

    if (wasSaved) {
      savedSlugs.remove(job.slug);
    } else {
      savedSlugs.add(job.slug);
    }

    try {
      if (wasSaved) {
        await _employee.unsaveJob(job.slug);
      } else {
        await _employee.saveJob(job.slug);
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
}
