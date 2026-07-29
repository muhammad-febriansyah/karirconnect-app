import 'package:get/get.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class DashboardController extends GetxController {
  /// Drives the `PersistentTabView`. Exposed so any screen can jump tabs with
  /// `Get.find<DashboardController>().goToTab(1)`.
  late final PersistentTabController tabController;

  /// Mirrors [tabController] so widgets can react with `Obx`.
  final currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = PersistentTabController(initialIndex: 0);
  }

  void onTabChanged(int index) => currentIndex.value = index;

  void goToTab(int index) {
    tabController.jumpToTab(index);
    currentIndex.value = index;
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
