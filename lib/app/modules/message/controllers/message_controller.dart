import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/conversation_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/messaging_repository.dart';

class MessageController extends GetxController {
  MessageController({MessagingRepository? repository})
      : _repository = repository ?? MessagingRepository();

  final MessagingRepository _repository;

  final conversations = <ConversationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();

  /// Thread state. `null` means the list is showing.
  final openThread = Rxn<ConversationModel>();
  final isThreadLoading = false.obs;
  final isSending = false.obs;

  final composerController = TextEditingController();
  final threadScrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.conversations(perPage: 50);
      conversations.assignAll(result.items);
      unreadCount.value = result.unreadCount;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      conversations.clear();
    } finally {
      isLoading.value = false;
    }
  }

  /// Opening a thread marks it read server-side, so the unread badge is
  /// refreshed from the list on the way back out.
  Future<void> open(ConversationModel conversation) async {
    openThread.value = conversation;
    isThreadLoading.value = true;

    try {
      openThread.value = await _repository.conversation(conversation.id);
      _scrollToBottom();
    } on ApiException catch (error) {
      AppToast.error(error.message);
      openThread.value = null;
    } finally {
      isThreadLoading.value = false;
    }
  }

  void closeThread() {
    openThread.value = null;
    composerController.clear();
    load();
  }

  Future<void> send() async {
    final body = composerController.text.trim();
    final thread = openThread.value;

    if (body.isEmpty || thread == null || isSending.value) return;

    isSending.value = true;

    try {
      final message = await _repository.sendMessage(thread.id, body);

      // Append locally rather than refetching the whole thread.
      openThread.value = ConversationModel(
        id: thread.id,
        type: thread.type,
        subject: thread.subject,
        participants: thread.participants,
        messages: [...thread.messages, message],
        lastMessageAt: message.createdAt,
        updatedAt: message.createdAt,
      );

      composerController.clear();
      _scrollToBottom();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    } finally {
      isSending.value = false;
    }
  }

  void _scrollToBottom() {
    // The list has not been laid out yet at this point, so the jump waits a
    // frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!threadScrollController.hasClients) return;

      threadScrollController.jumpTo(
        threadScrollController.position.maxScrollExtent,
      );
    });
  }

  @override
  void onClose() {
    composerController.dispose();
    threadScrollController.dispose();
    super.onClose();
  }
}
