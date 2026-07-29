import 'package:get/get.dart';

import '../controllers/career_coach_controller.dart';

class CareerCoachBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CareerCoachController>(() => CareerCoachController());
  }
}
