import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/values/app_assets.dart';
import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class OnboardingController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();

  final PageController pageController = PageController();

  final currentPage = 0.obs;

  int get pageCount => AppAssets.onboarding.length;

  bool get isLastPage => currentPage.value == pageCount - 1;

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (isLastPage) {
      finish();
      return;
    }

    pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void skip() => finish();

  /// Marks onboarding as done before leaving, so the splash never routes back
  /// here on the next launch.
  Future<void> finish() async {
    await _storage.markOnboardingSeen();
    Get.offAllNamed(Routes.DASHBOARD);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
