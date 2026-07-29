import 'package:get/get.dart';

import '../controllers/work_experience_controller.dart';

class WorkExperienceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkExperienceController>(
      () => WorkExperienceController(),
    );
  }
}
