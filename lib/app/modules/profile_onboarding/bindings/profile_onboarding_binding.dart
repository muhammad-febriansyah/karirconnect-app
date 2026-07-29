import 'package:get/get.dart';

import '../controllers/profile_onboarding_controller.dart';

class ProfileOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileOnboardingController>(
      () => ProfileOnboardingController(),
    );
  }
}
