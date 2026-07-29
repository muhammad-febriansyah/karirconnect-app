import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/career_resource_model.dart';
import '../../../data/models/paginated.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../routes/app_pages.dart';

class CareerResourceController extends GetxController {
  CareerResourceController({CatalogRepository? repository})
      : _repository = repository ?? CatalogRepository();

  static const int _perPage = 20;
  static const Duration _debounce = Duration(milliseconds: 450);

  final CatalogRepository _repository;

  final searchController = TextEditingController();
  final scrollController = ScrollController();

  final resources = <CareerResourceModel>[].obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final errorMessage = RxnString();
  final activeCategory = RxnString();

  /// Categories are a free-text column server-side, so there is no taxonomy
  /// endpoint for them — they are derived from whatever the first page returns.
  final categories = <String>[].obs;

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
      resources.assignAll(page.items);
      _lastPage = page.lastPage;

      // Only refresh the chip row from an unfiltered page, otherwise filtering
      // by one category would collapse the row to that single option.
      if (activeCategory.value == null) {
        categories.assignAll(
          page.items
              .map((resource) => resource.category)
              .whereType<String>()
              .toSet()
              .toList()
            ..sort(),
        );
      }
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      resources.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoading.value || isLoadingMore.value || _page >= _lastPage) return;

    isLoadingMore.value = true;

    try {
      final page = await _fetch(_page + 1);
      resources.addAll(page.items);
      _page = page.currentPage;
      _lastPage = page.lastPage;
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<Paginated<CareerResourceModel>> _fetch(int page) =>
      _repository.careerResources(
        page: page,
        perPage: _perPage,
        search: searchController.text.trim(),
        category: activeCategory.value,
      );

  void selectCategory(String? category) {
    if (activeCategory.value == category) return;
    activeCategory.value = category;
    load();
  }

  void openResource(CareerResourceModel resource) =>
      Get.toNamed(Routes.ARTICLE_DETAIL, arguments: resource.slug);

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
