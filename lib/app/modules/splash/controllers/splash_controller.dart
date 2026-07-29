import 'package:flutter/animation.dart';
import 'package:get/get.dart';

import '../../../data/services/storage_service.dart';
import '../../../routes/app_pages.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  /// Long enough for the logo animation to land, short enough not to feel like
  /// a stall. The route decision itself is synchronous.
  static const Duration _hold = Duration(milliseconds: 1800);

  final StorageService _storage = Get.find<StorageService>();

  late final AnimationController animation;

  @override
  void onInit() {
    super.onInit();

    animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void onReady() {
    super.onReady();
    _decideNextRoute();
  }

  Future<void> _decideNextRoute() async {
    await Future.delayed(_hold);

    // offAllNamed, not toNamed: the splash must not stay on the back stack.
    if (!_storage.onboardingSeen) {
      Get.offAllNamed(Routes.ONBOARDING);
      return;
    }

    Get.offAllNamed(Routes.DASHBOARD);
  }

  @override
  void onClose() {
    animation.dispose();
    super.onClose();
  }
}
