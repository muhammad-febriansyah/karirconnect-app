import 'package:get/get.dart';

import '../controllers/application_detail_controller.dart';

class ApplicationDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApplicationDetailController>(
      () => ApplicationDetailController(),
    );
  }
}
