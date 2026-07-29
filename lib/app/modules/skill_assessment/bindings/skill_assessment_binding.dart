import 'package:get/get.dart';

import '../controllers/assessment_quiz_controller.dart';
import '../controllers/skill_assessment_controller.dart';

class SkillAssessmentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SkillAssessmentController>(() => SkillAssessmentController());
  }
}

class AssessmentQuizBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AssessmentQuizController>(() => AssessmentQuizController());
  }
}
