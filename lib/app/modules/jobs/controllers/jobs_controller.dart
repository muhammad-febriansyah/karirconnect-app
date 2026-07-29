import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/job_category_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/paginated.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class JobsController extends GetxController {
  JobsController({
    CatalogRepository? catalog,
    EmployeeRepository? employee,
  })  : _catalog = catalog ?? CatalogRepository(),
        _employee = employee ?? EmployeeRepository();

  static const int _perPage = 20;

  /// Typing pause before a search fires, so each keystroke is not a request.
  static const Duration _debounce = Duration(milliseconds: 450);

  static const List<({String value, String label})> sortOptions = [
    (value: 'latest', label: 'Terbaru'),
    (value: 'oldest', label: 'Terlama'),
    (value: 'salary_desc', label: 'Gaji tertinggi'),
    (value: 'salary_asc', label: 'Gaji terendah'),
  ];

  final CatalogRepository _catalog;
  final EmployeeRepository _employee;
  final AuthService _auth = Get.find<AuthService>();

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final jobs = <JobModel>[].obs;
  final categories = <JobCategoryModel>[].obs;

  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();

  /// `meta.total` for the current filter set, shown in the header. Not
  /// `jobs.length` — that only counts the pages fetched so far.
  final total = 0.obs;

  final activeCategoryId = RxnInt();
  final activeSort = 'latest'.obs;
  final workArrangement = RxnString();

  /// Slugs the user has saved this session, so the bookmark icon can flip
  /// without refetching the whole list.
  final savedSlugs = <String>{}.obs;

  int _page = 1;
  int _lastPage = 1;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();

    searchController.addListener(_onSearchChanged);
    scrollController.addListener(_onScroll);

    _loadCategories();
    load();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounce, load);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    final position = scrollController.position;
    if (position.pixels < position.maxScrollExtent - 400) return;

    loadMore();
  }

  Future<void> _loadCategories() async {
    try {
      categories.assignAll(await _catalog.jobCategories());
    } on ApiException catch (_) {
      categories.clear();
    }
  }

  Future<void> load() async {
    _page = 1;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _fetch(1);
      jobs.assignAll(page.items);
      _lastPage = page.lastPage;
      total.value = page.total;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      jobs.clear();
      total.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || _page >= _lastPage) return;

    isLoadingMore.value = true;

    try {
      final page = await _fetch(_page + 1);
      jobs.addAll(page.items);
      _page = page.currentPage;
      _lastPage = page.lastPage;
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<Paginated<JobModel>> _fetch(int page) => _catalog.jobs(
        page: page,
        perPage: _perPage,
        sort: activeSort.value,
        categoryId: activeCategoryId.value,
        workArrangement: workArrangement.value,
        search: searchController.text.trim(),
      );

  void selectCategory(int? categoryId) {
    if (activeCategoryId.value == categoryId) return;
    activeCategoryId.value = categoryId;
    load();
  }

  void selectSort(String sort) {
    if (activeSort.value == sort) return;
    activeSort.value = sort;
    load();
  }

  void toggleRemote() {
    workArrangement.value = workArrangement.value == 'remote' ? null : 'remote';
    load();
  }

  void openJob(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);

  /// `POST/DELETE api/v1/saved-jobs/{slug}` sit behind `role:employee`, so a
  /// guest is sent to login rather than issued a request that would 401.
  Future<void> toggleSave(JobModel job) async {
    if (!_auth.isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final wasSaved = savedSlugs.contains(job.slug);

    // Optimistic: flip now, roll back if the call fails.
    if (wasSaved) {
      savedSlugs.remove(job.slug);
    } else {
      savedSlugs.add(job.slug);
    }

    try {
      if (wasSaved) {
        await _employee.unsaveJob(job.slug);
        AppToast.info('Lowongan dihapus dari simpanan.');
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

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
