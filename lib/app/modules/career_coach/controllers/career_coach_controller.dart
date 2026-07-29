import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/coach_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/career_coach_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

class CareerCoachController extends GetxController {
  CareerCoachController({CareerCoachRepository? repository})
      : _repository = repository ?? CareerCoachRepository();

  /// Tapping one drops it into the composer so a first-time user has somewhere
  /// to start rather than a blank field.
  static const List<String> starters = [
    'Bagaimana cara menonjol saat interview kerja pertama?',
    'Skill apa yang perlu kupelajari untuk jadi data analyst?',
    'Tolong review ringkas rencana kariermu untuk 1 tahun.',
    'Bantu aku menjawab pertanyaan "kelemahan terbesarmu".',
  ];

  final CareerCoachRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final composerController = TextEditingController();
  final threadScrollController = ScrollController();

  final sessions = <CoachSession>[].obs;

  /// The session on screen. `null` while the list is showing.
  final openSession = Rxn<CoachSession>();

  /// The live thread for [openSession] — kept apart from the model so an
  /// optimistic user bubble and the coach's reply can be appended in place.
  final messages = <CoachMessage>[].obs;

  /// True when the user tapped "New chat" but has not sent the first message
  /// yet, so no session exists server-side.
  final composingNew = false.obs;

  final isLoading = false.obs;
  final isThreadLoading = false.obs;
  final isSending = false.obs;
  final errorMessage = RxnString();

  bool get isLoggedIn => _auth.isLoggedIn;

  /// True whenever a chat surface is showing (a session or a fresh compose),
  /// so the view can swap the header and the back button.
  bool get inChat => openSession.value != null || composingNew.value;

  int _tempId = -1;

  @override
  void onInit() {
    super.onInit();
    if (isLoggedIn) load();
    ever(_auth.user, (_) => isLoggedIn ? load() : sessions.clear());
  }

  Future<void> load() async {
    if (!isLoggedIn) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      sessions.assignAll(await _repository.sessions());
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      sessions.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Open an existing session and load its thread.
  Future<void> open(CoachSession session) async {
    composingNew.value = false;
    openSession.value = session;
    messages.clear();
    isThreadLoading.value = true;

    try {
      final full = await _repository.session(session.id);
      openSession.value = full;
      messages.assignAll(full.messages);
      _scrollToBottom();
    } on ApiException catch (error) {
      AppToast.error(error.message);
      openSession.value = null;
    } finally {
      isThreadLoading.value = false;
    }
  }

  /// Start a fresh chat: no server session yet, just the compose surface.
  void startNew() {
    openSession.value = null;
    messages.clear();
    composingNew.value = true;
  }

  void closeChat() {
    openSession.value = null;
    composingNew.value = false;
    messages.clear();
    composerController.clear();
  }

  void useStarter(String prompt) {
    composerController.text = prompt;
    composerController.selection = TextSelection.collapsed(
      offset: prompt.length,
    );
  }

  Future<void> send() async {
    final text = composerController.text.trim();
    if (text.isEmpty || isSending.value) return;

    // Optimistic user bubble; the coach reply lands under the typing dots.
    messages.add(CoachMessage(id: _tempId--, role: 'user', content: text));
    composerController.clear();
    isSending.value = true;
    _scrollToBottom();

    try {
      if (openSession.value == null) {
        // First message opens the session; the reply is already stored, so
        // re-fetch to get the populated thread and keep server ids.
        final id = await _repository.start(text);
        final full = await _repository.session(id);
        openSession.value = full;
        composingNew.value = false;
        messages.assignAll(full.messages);
        await load();
      } else {
        final reply = await _repository.reply(openSession.value!.id, text);
        messages.add(reply);
      }
      _scrollToBottom();
    } on ApiException catch (error) {
      // Roll the optimistic bubble back so the failed line does not linger.
      if (messages.isNotEmpty && messages.last.id < 0) messages.removeLast();
      composerController.text = text;
      AppToast.error(error.message);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> archive(CoachSession session) async {
    try {
      await _repository.archive(session.id);
      sessions.removeWhere((item) => item.id == session.id);
      if (openSession.value?.id == session.id) closeChat();
      AppToast.info('Sesi diarsipkan.');
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!threadScrollController.hasClients) return;
      threadScrollController.animateTo(
        threadScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);

  @override
  void onClose() {
    composerController.dispose();
    threadScrollController.dispose();
    super.onClose();
  }
}
