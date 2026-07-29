import 'package:get/get.dart';

import '../controllers/cv_builder_controller.dart';

class CvBuilderBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CvBuilderController>(
      () => CvBuilderController(),
    );
  }
}
