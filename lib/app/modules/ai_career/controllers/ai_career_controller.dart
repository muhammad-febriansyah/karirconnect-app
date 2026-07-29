import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

/// One row in the AI hub.
class AiFeature {
  const AiFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.endpoint,
  });

  final IconData icon;
  final String title;
  final String description;

  /// The `api/v1` route this feature will call once its screen exists. Kept
  /// here so the hub documents what is already available server-side.
  final String endpoint;
}

class AiCareerController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  /// Every entry sits behind `auth:api` + `role:employee` and, on the server,
  /// a 30-requests-per-minute throttle because each can reach a paid model.
  static const List<AiFeature> features = [
    AiFeature(
      icon: Iconsax.document_text,
      title: 'AI CV Review',
      description: 'Unggah CV dan dapatkan skor serta saran perbaikan instan.',
      endpoint: 'POST /onboarding/parse-cv',
    ),
    AiFeature(
      icon: Iconsax.microphone_2,
      title: 'AI Interview Practice',
      description: 'Latihan wawancara sesuai posisi yang kamu incar.',
      endpoint: 'POST /ai-interviews/practice',
    ),
    AiFeature(
      icon: Iconsax.messages_2,
      title: 'Career Coach',
      description: 'Tanya jawab soal karier dengan pendamping AI.',
      endpoint: 'POST /career-coach',
    ),
    AiFeature(
      icon: Iconsax.edit_2,
      title: 'CV Builder',
      description: 'Susun CV profesional langsung dari data profilmu.',
      endpoint: 'GET /cv-builder',
    ),
    AiFeature(
      icon: Iconsax.medal_star,
      title: 'Skill Assessment',
      description: 'Uji keahlianmu dan tampilkan hasilnya ke perekrut.',
      endpoint: 'GET /skill-assessments',
    ),
  ];

  bool get isLoggedIn => _auth.isLoggedIn;

  String get greetingName => _auth.user.value?.name ?? '';

  void open(AiFeature feature) {
    if (!isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    AppToast.info('${feature.title} belum tersedia di aplikasi.');
  }

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
