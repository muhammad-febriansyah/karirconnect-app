import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/interview_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/employee_repository.dart';

class InterviewController extends GetxController {
  InterviewController({EmployeeRepository? repository})
      : _repository = repository ?? EmployeeRepository();

  final EmployeeRepository _repository;

  final interviews = <InterviewModel>[].obs;
  final isLoading = true.obs;
  final isResponding = false.obs;
  final errorMessage = RxnString();
  final upcomingOnly = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final page = await _repository.interviews(
        upcomingOnly: upcomingOnly.value,
        perPage: 50,
      );
      interviews.assignAll(page.items);
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      interviews.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleUpcoming() {
    upcomingOnly.toggle();
    load();
  }

  /// [answer] is `accepted`, `declined` or `tentative`. The server treats
  /// accepting as the confirmation, and only the first accept sets the
  /// timestamp — re-accepting will not move it.
  Future<void> respond(InterviewModel interview, String answer) async {
    if (isResponding.value) return;

    isResponding.value = true;

    try {
      final updated = await _repository.respondToInterview(
        interview.id,
        answer,
      );

      final index = interviews.indexWhere((row) => row.id == interview.id);
      if (index != -1) interviews[index] = updated;

      AppToast.success(
        switch (answer) {
          'accepted' => 'Undangan interview diterima.',
          'declined' => 'Undangan interview ditolak.',
          _ => 'Jawaban tentatif terkirim.',
        },
      );
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isResponding.value = false;
    }
  }

  /// The API needs 1–5 slots strictly in the future. This proposes three at the
  /// same time of day on the following three days, which is what the reschedule
  /// sheet on the web offers as its default.
  Future<void> requestReschedule(
    InterviewModel interview,
    String reason,
  ) async {
    final base = DateTime.tryParse(interview.scheduledAt ?? '')?.toLocal() ??
        DateTime.now();

    // Anchor to tomorrow when the original slot is already in the past,
    // otherwise every proposed slot would fail the `after:now` rule.
    final anchor = base.isAfter(DateTime.now())
        ? base
        : DateTime.now().add(const Duration(days: 1));

    try {
      await _repository.requestReschedule(
        id: interview.id,
        reason: reason,
        proposedSlots: [
          anchor.add(const Duration(days: 1)),
          anchor.add(const Duration(days: 2)),
          anchor.add(const Duration(days: 3)),
        ],
      );

      AppToast.success('Permintaan jadwal ulang terkirim.');
      await load();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }
}
