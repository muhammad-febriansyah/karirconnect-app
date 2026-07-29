import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/notification_model.dart';
import '../controllers/notification_controller.dart';

/// `api/v1/notifications` — the in-app inbox. No push, so nothing here touches
/// Firebase or `device-tokens`.
class NotificationView extends GetView<NotificationController> {
  const NotificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Obx(() {
          if (!controller.isLoggedIn) {
            return SafeArea(
              child: AuthRequiredState(
                title: 'Masuk untuk melihat notifikasi',
                message:
                    'Kabar soal lamaran, undangan interview, dan pesan perekrut muncul di sini.',
                icon: Iconsax.notification,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            );
          }

          return Column(
            children: [
              GradientHeaderBar(
                title: 'Notifikasi',
                subtitle: controller.unreadCount.value > 0
                    ? '${controller.unreadCount.value} belum dibaca'
                    : 'Semua sudah dibaca',
                actions: [
                  if (controller.unreadCount.value > 0)
                    HeaderCircleButton(
                      icon: Iconsax.tick_circle,
                      label: 'Baca semua',
                      onTap: controller.markAllRead,
                    ),
                ],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.gutter.w,
                  AppSpacing.lg.h,
                  AppSpacing.gutter.w,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _UnreadChip(
                    active: controller.unreadOnly.value,
                    count: controller.unreadCount.value,
                    onTap: controller.toggleUnreadOnly,
                  ),
                ),
              ),
              Expanded(child: _Body()),
            ],
          );
        }),
      ),
    );
  }
}

class _UnreadChip extends StatelessWidget {
  const _UnreadChip({
    required this.active,
    required this.count,
    required this.onTap,
  });

  final bool active;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceSoft,
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
          child: Text(
            count > 0 ? 'Belum dibaca ($count)' : 'Belum dibaca',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}

class _Body extends GetView<NotificationController> {
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        final items = controller.items.toList();
        if (items.isEmpty) {
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: [
              EmptyState(
                icon: Iconsax.notification,
                message: controller.unreadOnly.value
                    ? 'Tidak ada notifikasi yang belum dibaca.'
                    : 'Belum ada notifikasi.',
              ),
            ],
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(18.w, 4.h, 18.w, 24.h),
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final item = items[index];

            return _NotificationCard(
              notification: item,
              onTap: () => controller.open(item),
              onDelete: () => controller.remove(item),
            );
          },
        );
      }),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// `data.icon` is a short server-side hint, not an icon font name.
  static const Map<String, IconData> _icons = {
    'bell': Iconsax.notification,
    'briefcase': Iconsax.briefcase,
    'calendar': Iconsax.calendar_2,
    'message': Iconsax.messages_2,
    'check': Iconsax.tick_circle,
    'star': Iconsax.star1,
    'document': Iconsax.document_text,
  };

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 18.w),
        decoration: BoxDecoration(
          color: AppColors.destructive,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(Iconsax.trash, size: 18.sp, color: Colors.white),
      ),
      child: Material(
        // An unread row is tinted so the list is scannable without a badge.
        // Read rows drop to the ordinary card surface — the two tints carry
        // the distinction, so the stroke the read state used to wear is gone.
        color: unread ? AppColors.accent : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38.w,
                  height: 38.w,
                  decoration: BoxDecoration(
                    color: unread ? Colors.white : AppColors.muted,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(
                    _icons[notification.icon] ?? Iconsax.notification,
                    size: 17.sp,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          height: 1.3,
                          fontWeight:
                              unread ? FontWeight.w700 : FontWeight.w600,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      if (notification.body.isNotEmpty) ...[
                        SizedBox(height: 3.h),
                        Text(
                          notification.body,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5.sp,
                            height: 1.45,
                            color: AppColors.foreground.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                      SizedBox(height: 6.h),
                      Text(
                        Formatters.relative(notification.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unread)
                  Container(
                    width: 8.w,
                    height: 8.w,
                    margin: EdgeInsets.only(top: 4.h, left: 6.w),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
