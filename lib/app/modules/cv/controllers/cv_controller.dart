import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/cv_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../routes/app_pages.dart';
import '../../profile/controllers/profile_controller.dart';

class CvController extends GetxController {
  CvController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  /// Server rule: `mimes:pdf,doc,docx` and `max:5120` (KB).
  static const List<String> allowedExtensions = ['pdf', 'doc', 'docx'];
  static const int maxSizeBytes = 5 * 1024 * 1024;

  final EmployeeRepository _repository;

  final items = <CandidateCvModel>[].obs;
  final primaryResumeId = RxnInt();
  final isLoading = true.obs;
  final isUploading = false.obs;
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
      final result = await _repository.cvs();
      items.assignAll(result.items);
      primaryResumeId.value = result.primaryResumeId;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Picks a file and uploads it. The size is checked here so an oversized file
  /// fails instantly instead of after a 5 MB round trip.
  Future<void> pickAndUpload() async {
    if (isUploading.value) return;

    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      // The repository uploads from a path, so the bytes are not needed in
      // memory as well.
      withData: false,
    );

    final file = picked?.files.singleOrNull;
    final path = file?.path;

    if (file == null || path == null) return;

    if (file.size > maxSizeBytes) {
      AppToast.error('Ukuran file maksimal 5 MB.');
      return;
    }

    isUploading.value = true;

    try {
      await _repository.uploadCv(
        // The filename doubles as the default label; the user can rename after.
        label: file.name,
        filePath: path,
        fileName: file.name,
      );

      AppToast.success('CV diunggah.');
      await load();
      _refreshProfileTab();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isUploading.value = false;
    }
  }

  /// Marking one active is what makes it the CV attached to new applications.
  /// The server keeps at most one active per profile, so the others flip off on
  /// their own — hence the full reload rather than a local edit.
  Future<void> setActive(CandidateCvModel cv) async {
    if (cv.isActive) return;

    try {
      await _repository.updateCv(id: cv.id, label: cv.label, isActive: true);
      AppToast.success('"${cv.label}" jadi CV utama.');
      await load();
      _refreshProfileTab();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }

  Future<void> rename(CandidateCvModel cv, String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty || trimmed == cv.label) return;

    try {
      await _repository.updateCv(
        id: cv.id,
        label: trimmed,
        // Required server-side, so the current value has to be resent or the
        // rename would clear the active flag.
        isActive: cv.isActive,
      );
      await load();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }

  Future<void> remove(CandidateCvModel cv) async {
    final index = items.indexWhere((row) => row.id == cv.id);
    if (index == -1) return;

    items.removeAt(index);

    try {
      await _repository.deleteCv(cv.id);
      AppToast.info('CV dihapus.');
      _refreshProfileTab();
    } on ApiException catch (error) {
      items.insert(index, cv);
      AppToast.error(error.message);
    }
  }

  void openBuilder() => Get.toNamed(Routes.CV_BUILDER);

  /// Uploading or deleting moves the completion score, which the Profil tab
  /// shows.
  void _refreshProfileTab() {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().load();
    }
  }
}
