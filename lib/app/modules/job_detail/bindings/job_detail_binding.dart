import 'package:get/get.dart';

import '../controllers/job_detail_controller.dart';

class JobDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobDetailController>(
      () => JobDetailController(),
    );
  }
}
