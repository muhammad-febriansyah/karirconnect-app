import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../jobs/controllers/jobs_controller.dart';

/// One shortcut in the home quick menu.
class QuickMenuItem {
  const QuickMenuItem({
    required this.label,
    required this.icon,
    required this.route,
    this.requiresAuth = false,
  });

  final String label;
  final IconData icon;

  /// `null` means the destination screen does not exist yet.
  final String? route;

  /// True for anything behind `auth:api` + `role:employee`.
  final bool requiresAuth;
}

class HomeController extends GetxController {
  HomeController({
    CatalogRepository? catalog,
    EmployeeRepository? employee,
  })  : _catalog = catalog ?? CatalogRepository(),
        _employee = employee ?? EmployeeRepository();

  /// Typing pause before a search fires, so each keystroke is not a request.
  static const Duration _debounce = Duration(milliseconds: 450);

  /// The eight shortcuts, chosen as the employee endpoints the five bottom-nav
  /// tabs do not already own. Rendered as two rows of four, so the count must
  /// stay at eight.
  static const List<QuickMenuItem> quickMenu = [
    QuickMenuItem(
      label: 'Rekomendasi',
      icon: Iconsax.magic_star,
      route: Routes.RECOMMENDATION,
      requiresAuth: true,
    ),
    QuickMenuItem(
      label: 'Tersimpan',
      icon: Iconsax.archive_tick,
      route: Routes.SAVED_JOB,
      requiresAuth: true,
    ),
    QuickMenuItem(
      label: 'Job Alert',
      icon: Iconsax.notification_bing,
      route: Routes.JOB_ALERT,
      requiresAuth: true,
    ),
    QuickMenuItem(
      label: 'Interview',
      icon: Iconsax.calendar_2,
      route: Routes.INTERVIEW,
      requiresAuth: true,
    ),
    QuickMenuItem(
      label: 'Insight Gaji',
      icon: Iconsax.chart_2,
      route: Routes.SALARY_INSIGHT,
    ),
    QuickMenuItem(
      label: 'Perusahaan',
      icon: Iconsax.buildings_2,
      route: Routes.COMPANY_BROWSE,
    ),
    QuickMenuItem(
      label: 'Pesan',
      icon: Iconsax.messages_2,
      route: Routes.MESSAGE,
      requiresAuth: true,
    ),
    QuickMenuItem(
      label: 'Artikel',
      icon: Iconsax.book_1,
      route: Routes.CAREER_RESOURCE,
    ),
  ];

  final CatalogRepository _catalog;
  final EmployeeRepository _employee;
  final AuthService _auth = Get.find<AuthService>();

  final searchController = TextEditingController();

  final meta = AppMeta.empty.obs;

  /// `featured_only` postings, shown as the "Lowongan Pilihan" rail.
  final suggestedJobs = <JobModel>[].obs;

  /// Latest postings, filtered by the category chips.
  final recentJobs = <JobModel>[].obs;

  final companies = <CompanyModel>[].obs;

  final isLoading = true.obs;
  final isRecentLoading = false.obs;
  final errorMessage = RxnString();

  /// `null` is "Semua lokasi" / the "Semua" category chip.
  final activeProvinceId = RxnInt();
  final activeCategoryId = RxnInt();

  // Filter-sheet state.
  final employmentType = RxnString();
  final workArrangement = RxnString();
  final experienceLevel = RxnString();

  /// Slugs saved this session, so the bookmark can flip without a refetch.
  final savedSlugs = <String>{}.obs;

  Timer? _searchDebounce;

  String get locationLabel {
    final id = activeProvinceId.value;
    if (id == null) return 'Semua lokasi';

    return meta.value.provinces
        .firstWhereOrNull((province) => province.id == id)
        ?.name ??
        'Semua lokasi';
  }

  int get activeFilterCount => [
        employmentType.value,
        workArrangement.value,
        experienceLevel.value,
      ].where((value) => value != null).length;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    load();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_debounce, _loadRecent);
  }

  /// First paint and pull-to-refresh both land here.
  ///
  /// The four reads are independent, so they go out together. Each owns its
  /// error handling: a companies or meta outage still leaves a usable job list,
  /// and only a failed recent-jobs read surfaces as a page-level error.
  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    await Future.wait([
      _loadMeta(),
      _loadSuggested(),
      _loadRecent(),
      _loadCompanies(),
    ]);

    isLoading.value = false;
  }

  Future<void> _loadMeta() async {
    try {
      meta.value = await _catalog.meta();
    } on ApiException catch (_) {
      meta.value = AppMeta.empty;
    }
  }

  Future<void> _loadSuggested() async {
    try {
      final page = await _catalog.jobs(
        perPage: 8,
        featuredOnly: true,
        provinceId: activeProvinceId.value,
      );
      suggestedJobs.assignAll(page.items);
    } on ApiException catch (_) {
      suggestedJobs.clear();
    }
  }

  Future<void> _loadRecent() async {
    isRecentLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _catalog.jobs(
        perPage: 10,
        sort: 'latest',
        provinceId: activeProvinceId.value,
        categoryId: activeCategoryId.value,
        employmentType: employmentType.value,
        workArrangement: workArrangement.value,
        experienceLevel: experienceLevel.value,
        search: searchController.text.trim(),
      );
      recentJobs.assignAll(page.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      recentJobs.clear();
    } finally {
      isRecentLoading.value = false;
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final page = await _catalog.companies(perPage: 8);
      companies.assignAll(page.items);
    } on ApiException catch (_) {
      companies.clear();
    }
  }

  /// Province changes both rails: a suggested job in another province is not
  /// a suggestion for this user.
  Future<void> selectProvince(int? provinceId) async {
    if (activeProvinceId.value == provinceId) return;

    activeProvinceId.value = provinceId;
    await Future.wait([_loadSuggested(), _loadRecent()]);
  }

  void selectCategory(int? categoryId) {
    if (activeCategoryId.value == categoryId) return;

    activeCategoryId.value = categoryId;
    _loadRecent();
  }

  void applyFilters({
    required String? employment,
    required String? arrangement,
    required String? experience,
  }) {
    employmentType.value = employment;
    workArrangement.value = arrangement;
    experienceLevel.value = experience;
    _loadRecent();
  }

  void resetFilters() => applyFilters(
        employment: null,
        arrangement: null,
        experience: null,
      );

  void submitSearch(String _) => _loadRecent();

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

  void openJob(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);

  /// Auth-gated shortcuts send a guest to login rather than to a screen whose
  /// endpoint would only answer 401.
  void openQuickMenu(QuickMenuItem item) {
    if (item.requiresAuth && !_auth.isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final route = item.route;
    if (route == null) {
      AppToast.info('${item.label} belum tersedia di aplikasi.');
      return;
    }

    Get.toNamed(route);
  }

  void requireLogin() => Get.toNamed(Routes.LOGIN);

  /// The bell is login-gated: the inbox endpoint 401s without a session.
  void openNotifications() => _auth.isLoggedIn
      ? Get.toNamed(Routes.NOTIFICATION)
      : Get.toNamed(Routes.LOGIN);

  void openCompany(CompanyModel company) =>
      Get.toNamed(Routes.COMPANY_DETAIL, arguments: company.slug);

  void goToRegister() => Get.toNamed(Routes.REGISTER);

  /// Jumps to the Lowongan tab carrying the current search text, so "Lihat
  /// semua" continues the query instead of resetting it.
  void openJobsTab() {
    Get.find<JobsController>().searchController.text = searchController.text;
    Get.find<DashboardController>().goToTab(1);
  }

  /// The AI hub is the middle tab; the banner CTA just switches to it.
  void openAiTab() => Get.find<DashboardController>().goToTab(2);

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }
}
