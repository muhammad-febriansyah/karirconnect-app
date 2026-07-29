import 'package:get/get.dart';

import '../controllers/ai_career_controller.dart';

class AiCareerBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiCareerController>(
      () => AiCareerController(),
    );
  }
}
