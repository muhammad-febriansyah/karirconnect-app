import 'package:get/get.dart';

import '../controllers/company_browse_controller.dart';

class CompanyBrowseBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CompanyBrowseController>(
      () => CompanyBrowseController(),
    );
  }
}
