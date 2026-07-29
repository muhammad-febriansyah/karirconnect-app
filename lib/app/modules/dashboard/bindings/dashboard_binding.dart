import 'package:get/get.dart';

import '../../ai_career/controllers/ai_career_controller.dart';
import '../../applications/controllers/applications_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../jobs/controllers/jobs_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardController>(
      () => DashboardController(),
    );

    // Tab screens are built inside DashboardView, so their routes never run and
    // their own bindings never fire. Every tab controller has to be registered
    // here. lazyPut keeps each one uninstantiated until its tab is first shown,
    // so opening the app still only fires the Beranda requests.
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<JobsController>(() => JobsController());
    Get.lazyPut<AiCareerController>(() => AiCareerController());
    Get.lazyPut<ApplicationsController>(() => ApplicationsController());
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
