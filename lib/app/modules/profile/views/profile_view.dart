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
import '../controllers/profile_controller.dart';

/// Profil tab. The identity block that used to be a gradient card inside the
/// page is now the header itself, so the tab matches Beranda / Lowongan /
/// Lamaran instead of stacking a second gradient on a white AppBar.
class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

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
                title: 'Masuk ke akunmu',
                message:
                    'Lengkapi profil agar peluang diterima naik dan perekrut bisa menemukanmu.',
                icon: Iconsax.profile_circle,
                onLogin: controller.goToLogin,
                onRegister: controller.goToRegister,
              ),
            );
          }

          return Column(
            children: [
              const _ProfileHeader(),
              Expanded(child: _Body()),
            ],
          );
        }),
      ),
    );
  }
}

class _ProfileHeader extends GetView<ProfileController> {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      child: Row(
        children: [
          Obx(() {
            final user = controller.user;
            final avatar = user?.avatarUrl;

            final initials = Text(
              Formatters.initials(user?.name),
              style: GoogleFonts.poppins(
                fontSize: 19.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            );

            return Container(
              width: 58.w,
              height: 58.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: avatar == null || avatar.isEmpty
                  ? initials
                  : Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      width: 58.w,
                      height: 58.w,
                      errorBuilder: (_, _, _) => initials,
                    ),
            );
          }),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Obx(() {
              final user = controller.user;
              final profile = controller.profile.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.name ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    profile?.headline ??
                        profile?.currentPosition ??
                        user?.email ??
                        '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  if (profile?.city != null) ...[
                    SizedBox(height: 6.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.location5,
                          size: 13.sp,
                          color: AppColors.brandCyan,
                        ),
                        SizedBox(width: 5.w),
                        Flexible(
                          child: Text(
                            profile!.city!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5.sp,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              );
            }),
          ),
          SizedBox(width: AppSpacing.sm.w),
          _EditButton(onTap: controller.openEdit),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  const _EditButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ubah profil',
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: SizedBox(
            width: 44.w,
            height: 44.w,
            child: Icon(Iconsax.edit_2, size: 19.sp, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Body extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const SectionLoader();

      final error = controller.errorMessage.value;
      if (error != null) {
        return ListView(
          padding: EdgeInsets.all(AppSpacing.gutter.w),
          children: [ErrorState(message: error, onRetry: controller.load)],
        );
      }

      return RefreshIndicator(
        onRefresh: controller.load,
        color: AppColors.primary,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.gutter.w,
            AppSpacing.xl.h,
            AppSpacing.gutter.w,
            AppSpacing.section.h,
          ),
          children: [
            _CompletionCard(),
            SizedBox(height: AppSpacing.md.h),
            _StatsCard(),
            SizedBox(height: AppSpacing.lg.h),
            _MenuCard(),
            SizedBox(height: AppSpacing.xl.h),
            OutlinedButton.icon(
              onPressed: controller.logout,
              icon: Icon(
                Iconsax.logout,
                size: 17.sp,
                color: AppColors.destructive,
              ),
              label: Text(
                'Keluar',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.destructive,
                ),
              ),
              // Destructive, so it brings its own tint rather than sitting on
              // the theme's blue `accent` at 4.19:1.
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.destructiveSoft,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _CompletionCard extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profile.value;
      if (profile == null) return const SizedBox.shrink();

      final missing = controller.missingItems.toList();
      final complete = profile.profileCompletion;

      return Container(
        padding: EdgeInsets.all(AppSpacing.lg.w),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Kelengkapan profil',
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brandNavy,
                  ),
                ),
                const Spacer(),
                Text(
                  '$complete%',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color:
                        profile.canApply ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: complete / 100,
                minHeight: 8.h,
                backgroundColor: AppColors.surfaceInset,
                valueColor: AlwaysStoppedAnimation<Color>(
                  profile.canApply ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.md.h),
            Text(
              // The 60% rule lives in SubmitApplicationAction server-side; the
              // apply button is rejected below it, so it is surfaced here.
              profile.canApply
                  ? 'Profilmu sudah cukup lengkap untuk melamar.'
                  : 'Minimal 60% untuk bisa melamar lowongan.',
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                height: 1.4,
                color: AppColors.mutedForeground,
              ),
            ),
            if (!profile.canApply) ...[
              SizedBox(height: AppSpacing.md.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: controller.openOnboarding,
                  icon: Icon(Iconsax.magicpen, size: 16.sp),
                  label: Text(
                    'Lengkapi cepat',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (missing.isNotEmpty) ...[
              SizedBox(height: AppSpacing.md.h),
              Text(
                'Yang masih kurang',
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
              SizedBox(height: AppSpacing.sm.h),
              ...missing.map(
                (item) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 3.h),
                        child: Icon(
                          Iconsax.info_circle,
                          size: 13.sp,
                          color: AppColors.accentForeground,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm.w),
                      Expanded(
                        child: Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 11.sp,
                            height: 1.4,
                            color: AppColors.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _StatsCard extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final profile = controller.profile.value;
      if (profile == null) return const SizedBox.shrink();

      final items = <({IconData icon, String label, int value})>[
        (icon: Iconsax.teacher, label: 'Pendidikan', value: profile.educationCount),
        (
          icon: Iconsax.briefcase,
          label: 'Pengalaman',
          value: profile.workExperienceCount,
        ),
        (
          icon: Iconsax.medal_star,
          label: 'Sertifikat',
          value: profile.certificationCount,
        ),
        (icon: Iconsax.flash_1, label: 'Keahlian', value: profile.skills.length),
      ];

      return Container(
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.lg.h,
          horizontal: AppSpacing.sm.w,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: items
              .map(
                (item) => Expanded(
                  child: Column(
                    children: [
                      Icon(item.icon, size: 19.sp, color: AppColors.primary),
                      SizedBox(height: 6.h),
                      Text(
                        '${item.value}',
                        style: GoogleFonts.poppins(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      Text(
                        item.label,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      );
    });
  }
}

/// Links into the edit form and the three profile sub-resource screens. Each
/// of those calls back into `ProfileController.load()` on save, so the counts
/// above stay in step without a manual refresh.
class _MenuCard extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (icon: Iconsax.teacher, label: 'Pendidikan', onTap: controller.openEducations),
      (
        icon: Iconsax.briefcase,
        label: 'Pengalaman kerja',
        onTap: controller.openWorkExperiences,
      ),
      (
        icon: Iconsax.medal_star,
        label: 'Sertifikat',
        onTap: controller.openCertifications,
      ),
      (icon: Iconsax.document_text, label: 'CV Saya', onTap: controller.openCvs),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            // A hairline rule between list rows — a table rule, not a card
            // outline. The white inset makes the seam read without a stroke.
            if (index > 0)
              Container(height: 1, color: AppColors.surfaceInset),
            InkWell(
              onTap: items[index].onTap,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg.w,
                  vertical: AppSpacing.lg.h,
                ),
                child: Row(
                  children: [
                    Icon(
                      items[index].icon,
                      size: 18.sp,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: AppSpacing.md.w),
                    Expanded(
                      child: Text(
                        items[index].label,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.brandNavy,
                        ),
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
          ],
        ],
      ),
    );
  }
}
