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
import '../../../data/models/coach_model.dart';
import '../controllers/career_coach_controller.dart';

/// `api/v1/career-coach` — the AI coach chat.
///
/// One view, two surfaces: a session list and a chat thread, toggled by
/// `controller.inChat` the same way the Pesan tab swaps list and thread.
class CareerCoachView extends GetView<CareerCoachController> {
  const CareerCoachView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Obx(() {
        if (!controller.isLoggedIn) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: SafeArea(
              child: AuthRequiredState(
                title: 'Masuk untuk mengobrol dengan coach',
                message:
                    'Career coach AI membantu soal interview, skill, dan langkah kariermu.',
                icon: Iconsax.messages_2,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            ),
          );
        }

        final inChat = controller.inChat;

        return PopScope(
          canPop: !inChat,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) controller.closeChat();
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            floatingActionButton: inChat
                ? null
                : FloatingActionButton.extended(
                    onPressed: controller.startNew,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    icon: const Icon(Iconsax.add),
                    label: Text(
                      'Chat baru',
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
            body: Column(
              children: [
                GradientHeaderBar(
                  title: inChat
                      ? (controller.openSession.value?.title ?? 'Chat baru')
                      : 'Career Coach',
                  subtitle: inChat ? null : 'Pendamping AI untuk kariermu',
                  onBack: inChat
                      ? controller.closeChat
                      : () => Navigator.of(context).maybePop(),
                ),
                Expanded(child: inChat ? const _Chat() : const _SessionList()),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ---- Session list ---------------------------------------------------------

class _SessionList extends GetView<CareerCoachController> {
  const _SessionList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: controller.load,
      color: AppColors.primary,
      child: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final gutter = EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
          AppSpacing.gutter.w,
          90.h,
        );

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: gutter,
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        final sessions = controller.sessions.toList();
        if (sessions.isEmpty) {
          return ListView(
            padding: gutter,
            children: [
              const _CoachIntro(),
              SizedBox(height: AppSpacing.xl.h),
              EmptyState(
                icon: Iconsax.messages_2,
                message:
                    'Belum ada percakapan. Mulai chat baru untuk bertanya apa saja soal karier.',
                action: ElevatedButton.icon(
                  onPressed: controller.startNew,
                  icon: Icon(Iconsax.add, size: 16.sp),
                  label: Text(
                    'Chat baru',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.separated(
          padding: gutter,
          itemCount: sessions.length,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
          itemBuilder: (context, index) => _SessionTile(session: sessions[index]),
        );
      }),
    );
  }
}

class _SessionTile extends GetView<CareerCoachController> {
  const _SessionTile({required this.session});

  final CoachSession session;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(session.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => controller.archive(session),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: AppSpacing.gutter.w),
        decoration: BoxDecoration(
          color: AppColors.mutedForeground,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Icon(Iconsax.archive_1, size: 18.sp, color: Colors.white),
      ),
      child: Material(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: () => controller.open(session),
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg.w),
            child: Row(
              children: [
                const _CoachAvatar(),
                SizedBox(width: AppSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5.sp,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        session.lastMessageAt == null
                            ? 'Percakapan baru'
                            : Formatters.relative(session.lastMessageAt),
                        style: GoogleFonts.poppins(
                          fontSize: 11.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16.sp,
                  color: AppColors.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Chat -----------------------------------------------------------------

class _Chat extends GetView<CareerCoachController> {
  const _Chat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Obx(() {
            if (controller.isThreadLoading.value) {
              return const SectionLoader();
            }

            final messages = controller.messages.toList();
            final typing = controller.isSending.value;

            // Fresh chat with nothing sent yet: a welcome hero + starter chips.
            if (messages.isEmpty && !typing) return const _Welcome();

            return ListView.separated(
              controller: controller.threadScrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.gutter.w,
                AppSpacing.xl.h,
                AppSpacing.gutter.w,
                AppSpacing.lg.h,
              ),
              itemCount: messages.length + (typing ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
              itemBuilder: (context, index) {
                if (index >= messages.length) return const _TypingBubble();
                return _Bubble(message: messages[index]);
              },
            );
          }),
        ),
        const _Composer(),
      ],
    );
  }
}

class _Welcome extends GetView<CareerCoachController> {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.gutter.w,
        AppSpacing.section.h,
        AppSpacing.gutter.w,
        AppSpacing.lg.h,
      ),
      children: [
        Center(
          child: Container(
            width: 64.w,
            height: 64.w,
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.magicpen, size: 28.sp, color: Colors.white),
          ),
        ),
        SizedBox(height: AppSpacing.lg.h),
        Text(
          'Halo! Aku career coach-mu.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
            letterSpacing: -0.3,
          ),
        ),
        SizedBox(height: AppSpacing.xs.h),
        Text(
          'Tanya apa saja soal interview, skill, atau langkah kariermu. '
          'Pilih salah satu untuk mulai:',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            height: 1.5,
            color: AppColors.mutedForeground,
          ),
        ),
        SizedBox(height: AppSpacing.xl.h),
        ...CareerCoachController.starters.map(
          (prompt) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md.h),
            child: _StarterCard(
              prompt: prompt,
              onTap: () => controller.useStarter(prompt),
            ),
          ),
        ),
      ],
    );
  }
}

class _StarterCard extends StatelessWidget {
  const _StarterCard({required this.prompt, required this.onTap});

  final String prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg.w),
          child: Row(
            children: [
              Icon(Iconsax.flash_1, size: 16.sp, color: AppColors.primary),
              SizedBox(width: AppSpacing.md.w),
              Expanded(
                child: Text(
                  prompt,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5.sp,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.isMine;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: 0.72.sw),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md.w,
        vertical: AppSpacing.sm.h + 2,
      ),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : AppColors.surfaceSoft,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.card),
          topRight: Radius.circular(AppRadius.card),
          bottomLeft: Radius.circular(mine ? AppRadius.card : 4),
          bottomRight: Radius.circular(mine ? 4 : AppRadius.card),
        ),
      ),
      child: Text(
        message.content,
        style: GoogleFonts.poppins(
          fontSize: 12.5.sp,
          height: 1.5,
          color: mine ? Colors.white : AppColors.foreground,
        ),
      ),
    );

    if (mine) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    // Coach messages carry the avatar so the two voices are never ambiguous.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CoachAvatar(small: true),
        SizedBox(width: AppSpacing.sm.w),
        Flexible(child: bubble),
      ],
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _CoachAvatar(small: true),
        SizedBox(width: AppSpacing.sm.w),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg.w,
            vertical: AppSpacing.md.h,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceSoft,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppRadius.card),
              topRight: Radius.circular(AppRadius.card),
              bottomLeft: const Radius.circular(4),
              bottomRight: Radius.circular(AppRadius.card),
            ),
          ),
          child: const _TypingDots(),
        ),
      ],
    );
  }
}

/// Three dots that fade in sequence while the coach composes a reply.
class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Each dot leads the next by a third of the cycle.
            final t = (_controller.value - index * 0.2).clamp(0.0, 1.0);
            final opacity = 0.3 + 0.7 * (1 - (2 * t - 1).abs());

            return Padding(
              padding: EdgeInsets.only(right: index == 2 ? 0 : 5.w),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 7.w,
                  height: 7.w,
                  decoration: const BoxDecoration(
                    color: AppColors.mutedForeground,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _Composer extends GetView<CareerCoachController> {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceSoft,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter.w,
            AppSpacing.md.h,
            AppSpacing.gutter.w,
            AppSpacing.md.h,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 120.h),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg.w,
                    vertical: 4.h,
                  ),
                  child: TextField(
                    controller: controller.composerController,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 4000,
                    textInputAction: TextInputAction.newline,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: AppColors.foreground,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      isDense: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                      hintText: 'Tanya coach…',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color: AppColors.mutedForeground.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.sm.w),
              Obx(
                () => _SendButton(
                  busy: controller.isSending.value,
                  onTap: controller.send,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: busy ? null : onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 46.w,
          height: 46.w,
          child: busy
              ? Padding(
                  padding: EdgeInsets.all(13.w),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Icon(Iconsax.send_1, size: 19.sp, color: Colors.white),
        ),
      ),
    );
  }
}

class _CoachIntro extends StatelessWidget {
  const _CoachIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg.w),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Iconsax.magicpen, size: 20.sp, color: Colors.white),
          ),
          SizedBox(width: AppSpacing.md.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendamping karier AI',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Saran interview, skill, dan langkah karier — kapan saja.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachAvatar extends StatelessWidget {
  const _CoachAvatar({this.small = false});

  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 30.w : 44.w;

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Iconsax.magicpen,
        size: small ? 15.sp : 20.sp,
        color: Colors.white,
      ),
    );
  }
}
