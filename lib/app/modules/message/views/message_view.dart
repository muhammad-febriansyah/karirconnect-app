import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/conversation_model.dart';
import '../controllers/message_controller.dart';

/// `api/v1/conversations`. The list and the thread share one route: opening a
/// thread swaps the body rather than pushing, so the back button closes the
/// thread first and only then leaves the screen.
class MessageView extends GetView<MessageController> {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final thread = controller.openThread.value;

      return PopScope(
        canPop: thread == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) controller.closeThread();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(thread?.title ?? 'Pesan'),
            backgroundColor: AppColors.background,
            surfaceTintColor: Colors.transparent,
            leading: thread == null
                ? null
                : IconButton(
                    onPressed: controller.closeThread,
                    icon: const Icon(Iconsax.arrow_left_2),
                  ),
          ),
          body: thread == null ? const _ConversationList() : _Thread(thread: thread),
        ),
      );
    });
  }
}

class _ConversationList extends GetView<MessageController> {
  const _ConversationList();

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

        final conversations = controller.conversations.toList();
        if (conversations.isEmpty) {
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: const [
              EmptyState(
                icon: Iconsax.messages_2,
                message:
                    'Belum ada percakapan. Perekrut akan menghubungimu di sini setelah kamu melamar.',
              ),
            ],
          );
        }

        return ListView.separated(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 24.h),
          itemCount: conversations.length,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (context, index) {
            final conversation = conversations[index];

            return _ConversationTile(
              conversation: conversation,
              onTap: () => controller.open(conversation),
            );
          },
        );
      }),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final ConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final counterpart = conversation.counterpart;

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Row(
            children: [
              Container(
                width: 44.w,
                height: 44.w,
                decoration: const BoxDecoration(
                  color: AppColors.muted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  Formatters.initials(counterpart?.name ?? conversation.title),
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    if (counterpart?.name != null) ...[
                      SizedBox(height: 2.h),
                      Text(
                        counterpart!.name!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                Formatters.relative(
                  conversation.lastMessageAt ?? conversation.updatedAt,
                ),
                style: GoogleFonts.poppins(
                  fontSize: 10.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thread extends GetView<MessageController> {
  const _Thread({required this.thread});

  final ConversationModel thread;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isThreadLoading.value) return const SectionLoader();

            final messages = thread.messages;
            if (messages.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(18.w),
                children: const [
                  EmptyState(
                    icon: Iconsax.messages_2,
                    message: 'Belum ada pesan di percakapan ini.',
                  ),
                ],
              );
            }

            return ListView.separated(
              controller: controller.threadScrollController,
              padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 12.h),
              itemCount: messages.length,
              separatorBuilder: (_, _) => SizedBox(height: 8.h),
              itemBuilder: (context, index) =>
                  _Bubble(message: messages[index]),
            );
          }),
        ),
        const _Composer(),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final MessageModel message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        padding: EdgeInsets.symmetric(horizontal: 13.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.muted,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.card),
            topRight: Radius.circular(AppRadius.card),
            bottomLeft: Radius.circular(mine ? AppRadius.card : 4),
            bottomRight: Radius.circular(mine ? 4 : AppRadius.card),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.body,
              style: GoogleFonts.poppins(
                fontSize: 12.5.sp,
                height: 1.4,
                color: mine ? Colors.white : AppColors.foreground,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              Formatters.relative(message.createdAt),
              style: GoogleFonts.poppins(
                fontSize: 9.5.sp,
                color: mine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.mutedForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends GetView<MessageController> {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
        // Tonal fill instead of a top rule, the same way the job detail's
        // apply bar separates itself from the thread above.
        decoration: const BoxDecoration(color: AppColors.surfaceSoft),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller.composerController,
                minLines: 1,
                maxLines: 4,
                maxLength: 5000,
                textInputAction: TextInputAction.newline,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: AppColors.foreground,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  fillColor: AppColors.muted,
                  hintText: 'Tulis pesan…',
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 11.h,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Obx(
              () => Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: controller.isSending.value ? null : controller.send,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(11.w),
                    child: controller.isSending.value
                        ? SizedBox(
                            width: 18.sp,
                            height: 18.sp,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(Iconsax.send_1, size: 18.sp, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
