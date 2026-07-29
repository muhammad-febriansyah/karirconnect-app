import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/employee_profile_model.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../profile/controllers/profile_controller.dart';

/// The jobseeker onboarding wizard.
///
/// The mobile API deliberately does **not** enforce the onboarding middleware,
/// so nobody is trapped here — but `profile_completion` gates applying at 60%,
/// and this is the fastest way past it.
class ProfileOnboardingController extends GetxController {
  ProfileOnboardingController({
    EmployeeRepository? repository,
    CatalogRepository? catalog,
  })  : _repository = repository ?? EmployeeRepository(),
        _catalog = catalog ?? CatalogRepository();

  static const int stepCount = 3;

  static const List<({String value, String label})> genders = [
    (value: 'male', label: 'Laki-laki'),
    (value: 'female', label: 'Perempuan'),
  ];

  final EmployeeRepository _repository;
  final CatalogRepository _catalog;

  final headlineController = TextEditingController();
  final aboutController = TextEditingController();
  final phoneController = TextEditingController();
  final positionController = TextEditingController();
  final skillsController = TextEditingController();
  final linkedinController = TextEditingController();
  final portfolioController = TextEditingController();
  final githubController = TextEditingController();

  final meta = AppMeta.empty.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final isParsing = false.obs;
  final errorMessage = RxnString();
  final alreadyCompleted = false.obs;

  final currentStep = 0.obs;
  final gender = RxnString();
  final experienceLevel = RxnString();
  final provinceId = RxnInt();
  final cityId = RxnInt();
  final dateOfBirth = Rxn<DateTime>();

  bool get isLastStep => currentStep.value == stepCount - 1;

  List<CityModel> get cities => meta.value.citiesIn(provinceId.value);

  List<String> get skills => skillsController.text
      .split(',')
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList();

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    errorMessage.value = null;

    await Future.wait([_loadOnboarding(), _loadMeta()]);

    isLoading.value = false;
  }

  Future<void> _loadOnboarding() async {
    try {
      final result = await _repository.onboarding();
      alreadyCompleted.value = result.completed;
      _fill(result.profile);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
    }
  }

  Future<void> _loadMeta() async {
    try {
      meta.value = await _catalog.meta();
    } on ApiException catch (_) {
      meta.value = AppMeta.empty;
    }
  }

  /// Resumes from whatever the profile already holds, so a partially filled
  /// account does not start from scratch.
  void _fill(EmployeeProfileModel profile) {
    headlineController.text = profile.headline ?? '';
    aboutController.text = profile.about ?? '';
    positionController.text = profile.currentPosition ?? '';
    linkedinController.text = profile.linkedinUrl ?? '';
    portfolioController.text = profile.portfolioUrl ?? '';
    githubController.text = profile.githubUrl ?? '';
    skillsController.text = profile.skills.join(', ');

    gender.value = profile.gender;
    experienceLevel.value = profile.experienceLevel;
    provinceId.value = profile.provinceId;
    cityId.value = profile.cityId;
    dateOfBirth.value = profile.dateOfBirth == null
        ? null
        : DateTime.tryParse(profile.dateOfBirth!);
  }

  void selectProvince(int? id) {
    if (provinceId.value == id) return;

    provinceId.value = id;
    // The old city belongs to the old province, so it cannot stay selected.
    cityId.value = null;
  }

  /// Uploads a CV and prefills the wizard from what the parser extracted.
  ///
  /// Costs an AI call server-side (throttled to 10/min), and a 422 means the
  /// extraction produced nothing — that is a prompt to fill the form manually,
  /// not a failure to report as an error.
  Future<void> parseCv() async {
    if (isParsing.value) return;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx'],
      withData: false,
    );

    final file = picked?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) return;

    // Server rule here is 10 MB, unlike the 5 MB on the CV upload endpoint.
    if (file.size > 10 * 1024 * 1024) {
      AppToast.error('Ukuran file maksimal 10 MB.');
      return;
    }

    isParsing.value = true;

    try {
      final parsed = await _repository.parseCv(
        filePath: path,
        fileName: file.name,
        label: 'CV Onboarding',
      );

      _applyParsed(parsed);
      AppToast.success('Data dari CV terisi. Periksa dan lengkapi.');
    } on ApiException catch (error) {
      AppToast.warning(error.message);
    } finally {
      isParsing.value = false;
    }
  }

  /// Only fills fields the user has not already typed into — a re-parse must
  /// not overwrite manual edits.
  void _applyParsed(Map<String, dynamic> parsed) {
    void fillIfEmpty(TextEditingController controller, Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && controller.text.trim().isEmpty) {
        controller.text = text;
      }
    }

    fillIfEmpty(headlineController, parsed['headline']);
    fillIfEmpty(aboutController, parsed['about']);
    fillIfEmpty(phoneController, parsed['phone']);
    fillIfEmpty(positionController, parsed['current_position']);

    final province = (parsed['province_id'] as num?)?.toInt();
    final city = (parsed['city_id'] as num?)?.toInt();

    if (province != null && provinceId.value == null) {
      provinceId.value = province;
      cityId.value = city;
    }
  }

  void next() {
    if (isLastStep) {
      submit();
      return;
    }

    final problem = _validateStep(currentStep.value);
    if (problem != null) {
      AppToast.warning(problem);
      return;
    }

    currentStep.value += 1;
  }

  void back() {
    if (currentStep.value == 0) {
      Get.back<void>();
      return;
    }

    currentStep.value -= 1;
  }

  /// Mirrors `OnboardingStoreRequest`, so a miss is caught before the round
  /// trip rather than as a 422 on the last step.
  String? _validateStep(int step) {
    if (step == 0) {
      if (headlineController.text.trim().isEmpty) {
        return 'Headline wajib diisi.';
      }
      if (aboutController.text.trim().isEmpty) {
        return 'Tentang kamu wajib diisi.';
      }
      if (dateOfBirth.value == null) return 'Tanggal lahir wajib diisi.';
      if (gender.value == null) return 'Jenis kelamin wajib dipilih.';
      if (provinceId.value == null) return 'Provinsi wajib dipilih.';
      if (cityId.value == null) return 'Kota wajib dipilih.';
      return null;
    }

    if (step == 1) {
      if (experienceLevel.value == null) {
        return 'Level pengalaman wajib dipilih.';
      }
      if (skills.isEmpty) return 'Isi minimal satu keahlian.';
      if (skills.length > 30) return 'Maksimal 30 keahlian.';
      return null;
    }

    return null;
  }

  Future<void> submit() async {
    if (isSubmitting.value) return;

    for (var step = 0; step < stepCount; step++) {
      final problem = _validateStep(step);
      if (problem != null) {
        AppToast.warning(problem);
        return;
      }
    }

    isSubmitting.value = true;

    try {
      final phone = phoneController.text.trim();
      final position = positionController.text.trim();
      final linkedin = linkedinController.text.trim();
      final portfolio = portfolioController.text.trim();
      final github = githubController.text.trim();
      final birth = dateOfBirth.value!;

      await _repository.completeOnboarding({
        'headline': headlineController.text.trim(),
        'about': aboutController.text.trim(),
        'date_of_birth': '${birth.year.toString().padLeft(4, '0')}-'
            '${birth.month.toString().padLeft(2, '0')}-'
            '${birth.day.toString().padLeft(2, '0')}',
        'gender': gender.value,
        'province_id': provinceId.value,
        'city_id': cityId.value,
        'experience_level': experienceLevel.value,
        'skills': skills,
        if (phone.isNotEmpty) 'phone': phone,
        if (position.isNotEmpty) 'current_position': position,
        if (linkedin.isNotEmpty) 'linkedin_url': linkedin,
        if (portfolio.isNotEmpty) 'portfolio_url': portfolio,
        if (github.isNotEmpty) 'github_url': github,
      });

      AppToast.success('Profil selesai dilengkapi.');

      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().load();
      }

      Get.back<void>();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    headlineController.dispose();
    aboutController.dispose();
    phoneController.dispose();
    positionController.dispose();
    skillsController.dispose();
    linkedinController.dispose();
    portfolioController.dispose();
    githubController.dispose();
    super.onClose();
  }
}
