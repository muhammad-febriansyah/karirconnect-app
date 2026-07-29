import 'package:get/get.dart';

import '../controllers/company_detail_controller.dart';

class CompanyDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanyDetailController>(
      () => CompanyDetailController(),
    );
  }
}
