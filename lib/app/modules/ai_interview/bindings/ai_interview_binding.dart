import 'package:get/get.dart';

import '../controllers/ai_interview_controller.dart';
import '../controllers/interview_run_controller.dart';

class AiInterviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AiInterviewController>(() => AiInterviewController());
  }
}

class InterviewRunBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InterviewRunController>(() => InterviewRunController());
  }
}
