import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/employee_profile_model.dart';
import '../../../data/models/meta_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../profile/controllers/profile_controller.dart';

class ProfileEditController extends GetxController {
  ProfileEditController({
    EmployeeRepository? repository,
    CatalogRepository? catalog,
  })  : _repository = repository ?? EmployeeRepository(),
        _catalog = catalog ?? CatalogRepository();

  /// `ProfileUpdateRequest` accepts exactly these three.
  static const List<({String value, String label})> visibilities = [
    (value: 'public', label: 'Publik'),
    (value: 'recruiter_only', label: 'Perekrut saja'),
    (value: 'private', label: 'Privat'),
  ];

  static const List<({String value, String label})> genders = [
    (value: 'male', label: 'Laki-laki'),
    (value: 'female', label: 'Perempuan'),
  ];

  /// `ProfileUpdateRequest` caps the avatar at 4 MB, jpg/png/webp.
  static const int _avatarMaxBytes = 4 * 1024 * 1024;
  static const List<String> _avatarExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  final EmployeeRepository _repository;
  final CatalogRepository _catalog;
  final AuthService _auth = Get.find<AuthService>();

  /// A newly picked local avatar. [avatarPath] uploads (mobile has a file
  /// path); [avatarBytes] previews (works on every platform, unlike a
  /// `dart:io` File which would break the web build).
  final avatarPath = RxnString();
  final avatarBytes = Rxn<Uint8List>();

  String? get currentAvatarUrl => _auth.user.value?.avatarUrl;
  String? get userName => _auth.user.value?.name;

  final headlineController = TextEditingController();
  final aboutController = TextEditingController();
  final positionController = TextEditingController();
  final portfolioController = TextEditingController();
  final linkedinController = TextEditingController();
  final githubController = TextEditingController();

  final meta = AppMeta.empty.obs;
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();

  final gender = RxnString();
  final experienceLevel = RxnString();
  final provinceId = RxnInt();

  /// Required by the server, so both always carry a value.
  final isOpenToWork = true.obs;
  final visibility = 'public'.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    errorMessage.value = null;

    // Both go out together, but each owns its error handling: losing the meta
    // taxonomy only costs the pickers, while losing the profile means there is
    // nothing to edit.
    await Future.wait([_loadProfile(), _loadMeta()]);

    isLoading.value = false;
  }

  Future<void> _loadProfile() async {
    try {
      final result = await _repository.profile();
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

  /// Every field the update request accepts has to be loaded here.
  /// `ProfileUpdateRequest` replaces the whole record, so anything the form
  /// does not read is silently cleared by the next save.
  void _fill(EmployeeProfileModel profile) {
    headlineController.text = profile.headline ?? '';
    aboutController.text = profile.about ?? '';
    positionController.text = profile.currentPosition ?? '';
    portfolioController.text = profile.portfolioUrl ?? '';
    linkedinController.text = profile.linkedinUrl ?? '';
    githubController.text = profile.githubUrl ?? '';

    gender.value = profile.gender;
    experienceLevel.value = profile.experienceLevel;
    provinceId.value = profile.provinceId;
    isOpenToWork.value = profile.isOpenToWork;
    visibility.value = profile.visibility ?? 'public';

    // Not editable in this form yet, but the update request would drop it, so
    // it is carried through untouched.
    _dateOfBirth = profile.dateOfBirth;
    _cityId = profile.cityId;
  }

  String? _dateOfBirth;
  int? _cityId;

  /// Pick a new avatar. Size is checked here so an oversized image fails
  /// instantly rather than after the whole profile round-trips.
  Future<void> pickAvatar() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _avatarExtensions,
      // Bytes for the cross-platform preview; the path is what actually
      // uploads on mobile.
      withData: true,
    );

    final file = picked?.files.singleOrNull;
    final path = file?.path;
    if (file == null || path == null) {
      if (file != null && file.path == null) {
        AppToast.info('Ganti foto belum didukung di web.');
      }
      return;
    }

    if (file.size > _avatarMaxBytes) {
      AppToast.error('Ukuran foto maksimal 4 MB.');
      return;
    }

    avatarPath.value = path;
    avatarBytes.value = file.bytes;
  }

  Future<void> save() async {
    if (isSaving.value) return;

    isSaving.value = true;

    try {
      final headline = headlineController.text.trim();
      final about = aboutController.text.trim();
      final position = positionController.text.trim();
      final portfolio = portfolioController.text.trim();
      final linkedin = linkedinController.text.trim();
      final github = githubController.text.trim();

      await _repository.updateProfile(
        {
          // Both are `required` in ProfileUpdateRequest.
          'is_open_to_work': isOpenToWork.value,
          'visibility': visibility.value,
          if (headline.isNotEmpty) 'headline': headline,
          if (about.isNotEmpty) 'about': about,
          if (position.isNotEmpty) 'current_position': position,
          if (portfolio.isNotEmpty) 'portfolio_url': portfolio,
          if (linkedin.isNotEmpty) 'linkedin_url': linkedin,
          if (github.isNotEmpty) 'github_url': github,
          'gender': ?gender.value,
          'experience_level': ?experienceLevel.value,
          'province_id': ?provinceId.value,
          'date_of_birth': ?_dateOfBirth,
          'city_id': ?_cityId,
        },
        avatarPath: avatarPath.value,
      );

      AppToast.success('Profil disimpan.');

      // The Profil tab is already alive behind this screen, so it is told to
      // refetch rather than left showing the pre-edit snapshot.
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
    headlineController.dispose();
    aboutController.dispose();
    positionController.dispose();
    portfolioController.dispose();
    linkedinController.dispose();
    githubController.dispose();
    super.onClose();
  }
}
