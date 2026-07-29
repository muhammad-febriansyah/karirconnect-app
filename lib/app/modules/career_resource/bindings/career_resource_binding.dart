import 'package:get/get.dart';

import '../controllers/career_resource_controller.dart';

class CareerResourceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CareerResourceController>(
      () => CareerResourceController(),
    );
  }
}
