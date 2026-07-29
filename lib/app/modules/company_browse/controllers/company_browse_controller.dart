import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/company_model.dart';
import '../../../data/models/paginated.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../routes/app_pages.dart';

class CompanyBrowseController extends GetxController {
  CompanyBrowseController({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  static const int _perPage = 20;
  static const Duration _debounce = Duration(milliseconds: 450);

  final CatalogRepository _repository;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final companies = <CompanyModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final verifiedOnly = false.obs;

  int _page = 1;
  int _lastPage = 1;
  Timer? _searchDebounce;

  @override
  void onInit() {
    super.onInit();

    searchController.addListener(_onSearchChanged);
    scrollController.addListener(_onScroll);

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

  Future<void> load() async {
    _page = 1;
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _fetch(1);
      companies.assignAll(page.items);
      _lastPage = page.lastPage;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      companies.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || _page >= _lastPage) return;

    isLoadingMore.value = true;

    try {
      final page = await _fetch(_page + 1);
      companies.addAll(page.items);
      _page = page.currentPage;
      _lastPage = page.lastPage;
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<Paginated<CompanyModel>> _fetch(int page) => _repository.companies(
        page: page,
        perPage: _perPage,
        search: searchController.text.trim(),
        verifiedOnly: verifiedOnly.value,
      );

  void toggleVerifiedOnly() {
    verifiedOnly.toggle();
    load();
  }

  void openCompany(CompanyModel company) =>
      Get.toNamed(Routes.COMPANY_DETAIL, arguments: company.slug);

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
