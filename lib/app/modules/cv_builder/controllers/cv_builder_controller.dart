import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/cv_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../cv/controllers/cv_controller.dart';
import '../../profile/controllers/profile_controller.dart';

class CvBuilderController extends GetxController {
  CvBuilderController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final labelController = TextEditingController(text: 'CV Builder');
  final fullNameController = TextEditingController();
  final headlineController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final locationController = TextEditingController();
  final websiteController = TextEditingController();
  final summaryController = TextEditingController();
  final skillsController = TextEditingController();

  final experiences = <CvBuilderExperience>[].obs;
  final educations = <CvBuilderEducation>[].obs;
  final certifications = <CvBuilderCertification>[].obs;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      _fill(await _repository.cvBuilderDraft());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    } finally {
      isLoading.value = false;
    }
  }

  void _fill(CvBuilderDraft draft) {
    final personal = draft.personal;

    // A brand-new draft is empty, so the account's own name and email are the
    // sensible starting point rather than blank fields.
    fullNameController.text =
        personal.fullName.isNotEmpty ? personal.fullName : (_auth.user.value?.name ?? '');
    emailController.text =
        personal.email ?? _auth.user.value?.email ?? '';
    phoneController.text = personal.phone ?? _auth.user.value?.phone ?? '';

    headlineController.text = personal.headline ?? '';
    locationController.text = personal.location ?? '';
    websiteController.text = personal.website ?? '';
    summaryController.text = draft.summary ?? '';
    skillsController.text = draft.skills.join(', ');

    experiences.assignAll(draft.experiences);
    educations.assignAll(draft.educations);
    certifications.assignAll(draft.certifications);
  }

  void addExperience(CvBuilderExperience row) => experiences.add(row);
  void removeExperience(int index) => experiences.removeAt(index);

  void addEducation(CvBuilderEducation row) => educations.add(row);
  void removeEducation(int index) => educations.removeAt(index);

  void addCertification(CvBuilderCertification row) => certifications.add(row);
  void removeCertification(int index) => certifications.removeAt(index);

  /// Skills are typed as one comma-separated line; the API wants an array.
  List<String> get _skills => skillsController.text
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  Future<void> build() async {
    if (isSaving.value) return;

    final fullName = fullNameController.text.trim();
    if (fullName.isEmpty) {
      AppToast.warning('Nama lengkap wajib diisi.');
      return;
    }

    isSaving.value = true;

    try {
      final headline = headlineController.text.trim();
      final email = emailController.text.trim();
      final phone = phoneController.text.trim();
      final location = locationController.text.trim();
      final website = websiteController.text.trim();
      final summary = summaryController.text.trim();
      final label = labelController.text.trim();

      await _repository.buildCv({
        if (label.isNotEmpty) 'label': label,
        'personal': {
          'full_name': fullName,
          if (headline.isNotEmpty) 'headline': headline,
          if (email.isNotEmpty) 'email': email,
          if (phone.isNotEmpty) 'phone': phone,
          if (location.isNotEmpty) 'location': location,
          if (website.isNotEmpty) 'website': website,
        },
        if (summary.isNotEmpty) 'summary': summary,
        'experiences': experiences.map((row) => row.toJson()).toList(),
        'educations': educations.map((row) => row.toJson()).toList(),
        'skills': _skills,
        'certifications': certifications.map((row) => row.toJson()).toList(),
      });

      AppToast.success('CV dibuat dan PDF di-generate.');

      // The generated CV lands in the CV list and counts toward completion.
      if (Get.isRegistered<CvController>()) {
        await Get.find<CvController>().load();
      }
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().load();
      }

      Get.back<void>();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    labelController.dispose();
    fullNameController.dispose();
    headlineController.dispose();
    emailController.dispose();
    phoneController.dispose();
    locationController.dispose();
    websiteController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    super.onClose();
  }
}
