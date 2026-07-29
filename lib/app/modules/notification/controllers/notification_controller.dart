import 'package:get/get.dart';

import '../../../core/utils/app_toast.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../routes/app_pages.dart';

/// In-app inbox only. Push is not wired: `device-tokens` is never called, so
/// nothing here depends on Firebase.
class NotificationController extends GetxController {
  NotificationController({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  final NotificationRepository _repository;
  final AuthService _auth = Get.find<AuthService>();

  final items = <NotificationModel>[].obs;
  final unreadCount = 0.obs;
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final unreadOnly = false.obs;

  bool get isLoggedIn => _auth.isLoggedIn;

  @override
  void onInit() {
    super.onInit();
    if (isLoggedIn) load();
  }

  Future<void> load() async {
    if (!isLoggedIn) {
      isLoading.value = false;
      return;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final result = await _repository.notifications(
        unreadOnly: unreadOnly.value,
        perPage: 50,
      );
      items.assignAll(result.page.items);
      unreadCount.value = result.unreadCount;
    } on ApiException catch (error) {
      errorMessage.value = error.message;
      items.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void toggleUnreadOnly() {
    unreadOnly.toggle();
    load();
  }

  /// Marks read optimistically and rolls back on failure. The unread counter
  /// moves with it so the badge does not lag the list.
  Future<void> markRead(NotificationModel notification) async {
    if (notification.isRead) return;

    final index = items.indexWhere((row) => row.id == notification.id);
    if (index == -1) return;

    items[index] = NotificationModel(
      id: notification.id,
      type: notification.type,
      title: notification.title,
      body: notification.body,
      actionUrl: notification.actionUrl,
      icon: notification.icon,
      readAt: DateTime.now().toIso8601String(),
      createdAt: notification.createdAt,
    );
    unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);

    try {
      await _repository.markRead(notification.id);
    } on ApiException catch (error) {
      items[index] = notification;
      unreadCount.value += 1;
      AppToast.error(error.message);
    }
  }

  Future<void> markAllRead() async {
    if (unreadCount.value == 0) return;

    try {
      await _repository.markAllRead();
      AppToast.info('Semua notifikasi ditandai dibaca.');
      await load();
    } on ApiException catch (error) {
      AppToast.error(error.message);
    }
  }

  Future<void> remove(NotificationModel notification) async {
    final index = items.indexWhere((row) => row.id == notification.id);
    if (index == -1) return;

    items.removeAt(index);
    if (!notification.isRead) {
      unreadCount.value = (unreadCount.value - 1).clamp(0, 1 << 30);
    }

    try {
      await _repository.destroy(notification.id);
    } on ApiException catch (error) {
      items.insert(index, notification);
      if (!notification.isRead) unreadCount.value += 1;
      AppToast.error(error.message);
    }
  }

  /// `action_url` is a **web** path (`/employee/applications/3`). There is no
  /// mapping to mobile routes yet, so tapping only marks the row read.
  Future<void> open(NotificationModel notification) => markRead(notification);

  void goToLogin() => Get.toNamed(Routes.LOGIN);
  void goToRegister() => Get.toNamed(Routes.REGISTER);
}
