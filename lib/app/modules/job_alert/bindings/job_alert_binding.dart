import 'package:get/get.dart';

import '../controllers/job_alert_controller.dart';

class JobAlertBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobAlertController>(
      () => JobAlertController(),
    );
  }
}
