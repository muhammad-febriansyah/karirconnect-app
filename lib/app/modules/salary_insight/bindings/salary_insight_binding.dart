import 'package:get/get.dart';

import '../controllers/salary_insight_controller.dart';

class SalaryInsightBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SalaryInsightController>(
      () => SalaryInsightController(),
    );
  }
}
