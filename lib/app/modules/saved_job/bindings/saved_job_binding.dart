import 'package:get/get.dart';

import '../controllers/saved_job_controller.dart';

class SavedJobBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SavedJobController>(
      () => SavedJobController(),
    );
  }
}
