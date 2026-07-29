import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/job_detail_model.dart';
import '../../../data/models/job_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/employee_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class JobDetailController extends GetxController {
  JobDetailController({
    CatalogRepository? catalog,
    EmployeeRepository? employee,
  })  : _catalog = catalog ?? CatalogRepository(),
        _employee = employee ?? EmployeeRepository();

  final CatalogRepository _catalog;
  final EmployeeRepository _employee;
  final AuthService _auth = Get.find<AuthService>();

  /// The slug arrives as a route argument rather than a path parameter, so a
  /// caller can push the screen straight from a list row it already holds.
  late final String slug = Get.arguments as String? ?? '';

  final detail = Rxn<JobDetailModel>();
  final isLoading = true.obs;
  final isApplying = false.obs;
  final errorMessage = RxnString();

  final isSaved = false.obs;
  final hasApplied = false.obs;

  /// Save state for the "Lowongan serupa" cards, which are *other* postings.
  /// Kept apart from [isSaved]: that one belongs to the job on screen, and
  /// wiring a similar card's bookmark to it saved the wrong posting.
  final savedSimilarSlugs = <String>{}.obs;

  // Apply-form state.
  final coverLetterController = TextEditingController();
  final expectedSalaryController = TextEditingController();

  /// Screening answers, keyed by question id. A multi-choice answer is stored
  /// as a `List<String>`; everything else as a `String`.
  final answers = <int, dynamic>{}.obs;

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    if (slug.isEmpty) {
      errorMessage.value = 'Lowongan tidak ditemukan.';
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _catalog.job(slug);
      detail.value = result;

      // These only arrive when the request carried a token; for a guest they
      // stay null and the buttons fall back to their signed-out state.
      isSaved.value = result.isSaved ?? false;
      hasApplied.value = result.hasApplied ?? false;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleSave() async {
    if (!isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final wasSaved = isSaved.value;
    isSaved.value = !wasSaved;

    try {
      if (wasSaved) {
        await _employee.unsaveJob(slug);
      } else {
        await _employee.saveJob(slug);
      }
    } on ApiException catch (error) {
      isSaved.value = wasSaved;
      AppToast.error(error.message);
    }
  }

  /// Bookmark on a "Lowongan serupa" card. Same optimistic flip as
  /// [toggleSave], but keyed by that posting's own slug.
  Future<void> toggleSaveSimilar(JobModel job) async {
    if (!isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return;
    }

    final wasSaved = savedSimilarSlugs.contains(job.slug);

    if (wasSaved) {
      savedSimilarSlugs.remove(job.slug);
    } else {
      savedSimilarSlugs.add(job.slug);
    }

    try {
      if (wasSaved) {
        await _employee.unsaveJob(job.slug);
        AppToast.info('Lowongan dihapus dari simpanan.');
      } else {
        await _employee.saveJob(job.slug);
        AppToast.success('Lowongan disimpan.');
      }
    } on ApiException catch (error) {
      if (wasSaved) {
        savedSimilarSlugs.add(job.slug);
      } else {
        savedSimilarSlugs.remove(job.slug);
      }
      AppToast.error(error.message);
    }
  }

  void setAnswer(int questionId, dynamic value) =>
      answers[questionId] = value;

  void toggleMultiAnswer(int questionId, String option) {
    final current = (answers[questionId] as List?)?.cast<String>() ?? <String>[];

    answers[questionId] = current.contains(option)
        ? (current.where((item) => item != option).toList())
        : ([...current, option]);
  }

  /// Client-side check for the required screening questions only. Every other
  /// guard — published, duplicate, own company, 60% profile completion — lives
  /// in `SubmitApplicationAction`, so its message is what the user sees.
  String? _missingRequiredAnswer() {
    final questions = detail.value?.screeningQuestions ?? const [];

    for (final question in questions) {
      if (!question.isRequired) continue;

      final answer = answers[question.id];
      final isEmpty = answer == null ||
          (answer is String && answer.trim().isEmpty) ||
          (answer is List && answer.isEmpty);

      if (isEmpty) return question.question;
    }

    return null;
  }

  Future<bool> submit() async {
    if (!isLoggedIn) {
      Get.toNamed(Routes.LOGIN);
      return false;
    }

    if (isApplying.value) return false;

    final missing = _missingRequiredAnswer();
    if (missing != null) {
      AppToast.warning('Pertanyaan wajib belum dijawab: $missing');
      return false;
    }

    isApplying.value = true;

    try {
      final coverLetter = coverLetterController.text.trim();
      final salary = int.tryParse(
        expectedSalaryController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      await _employee.apply(
        slug: slug,
        coverLetter: coverLetter.isEmpty ? null : coverLetter,
        expectedSalary: salary,
        answers: answers.entries
            .map((entry) => {
                  'question_id': entry.key,
                  'answer': entry.value,
                })
            .toList(),
      );

      hasApplied.value = true;
      AppToast.success('Lamaran terkirim.');
      return true;
    } on ApiException catch (error) {
      AppToast.error(error.message);
      return false;
    } finally {
      isApplying.value = false;
    }
  }

  void openSimilar(JobModel job) =>
      Get.toNamed(Routes.JOB_DETAIL, arguments: job.slug);

  @override
  void onClose() {
    coverLetterController.dispose();
    expectedSalaryController.dispose();
    super.onClose();
  }
}
