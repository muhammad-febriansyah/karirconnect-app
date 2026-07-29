import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../controllers/profile_edit_controller.dart';

/// `POST api/v1/profile`, now carrying the avatar too — the whole-record
/// replace rides as multipart when a new photo is picked.
class ProfileEditView extends GetView<ProfileEditController> {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            const GradientHeaderBar(
              title: 'Ubah Profil',
              subtitle: 'Perbarui data yang dilihat perekrut',
            ),
            Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _Body extends GetView<ProfileEditController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const SectionLoader();

      final error = controller.errorMessage.value;
      if (error != null) {
        return ListView(
          padding: EdgeInsets.all(AppSpacing.gutter.w),
          children: [
            ErrorState(message: error, onRetry: controller.onInit),
          ],
        );
      }

      final meta = controller.meta.value;

      return ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
          AppSpacing.gutter.w,
          AppSpacing.xl.h,
        ),
        children: [
            const _AvatarPicker(),
            SizedBox(height: AppSpacing.xl.h),
            LabeledField(
              label: 'Headline',
              controller: controller.headlineController,
              hint: 'Misal: Frontend Developer · React',
            ),
            LabeledField(
              label: 'Tentang kamu',
              controller: controller.aboutController,
              hint: 'Ceritakan pengalaman dan minat kariermu',
              maxLines: 5,
            ),
            LabeledField(
              label: 'Posisi saat ini',
              controller: controller.positionController,
              hint: 'Misal: Junior Developer',
            ),
            ChipPicker(
              label: 'Jenis kelamin',
              options: ProfileEditController.genders,
              selected: controller.gender.value,
              onSelected: (value) => controller.gender.value = value,
            ),
            ChipPicker(
              label: 'Level pengalaman',
              options: meta.experienceLevels
                  .map((option) => (value: option.value, label: option.label))
                  .toList(),
              selected: controller.experienceLevel.value,
              onSelected: (value) => controller.experienceLevel.value = value,
            ),
            ChipPicker(
              label: 'Provinsi',
              options: meta.provinces
                  .take(12)
                  .map((province) =>
                      (value: '${province.id}', label: province.name))
                  .toList(),
              selected: controller.provinceId.value?.toString(),
              onSelected: (value) => controller.provinceId.value =
                  value == null ? null : int.tryParse(value),
            ),
            LabeledField(
              label: 'Portofolio',
              controller: controller.portfolioController,
              hint: 'https://…',
              keyboardType: TextInputType.url,
            ),
            LabeledField(
              label: 'LinkedIn',
              controller: controller.linkedinController,
              hint: 'https://linkedin.com/in/…',
              keyboardType: TextInputType.url,
            ),
            LabeledField(
              label: 'GitHub',
              controller: controller.githubController,
              hint: 'https://github.com/…',
              keyboardType: TextInputType.url,
            ),
            ChipPicker(
              label: 'Visibilitas profil',
              options: ProfileEditController.visibilities,
              selected: controller.visibility.value,
              // Required server-side, so it cannot be cleared.
              allowClear: false,
              onSelected: (value) =>
                  controller.visibility.value = value ?? 'public',
            ),
            SwitchListTile.adaptive(
              value: controller.isOpenToWork.value,
              onChanged: (value) => controller.isOpenToWork.value = value,
              contentPadding: EdgeInsets.zero,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              title: Text(
                'Terbuka untuk peluang kerja',
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: controller.isSaving.value ? null : controller.save,
              child: controller.isSaving.value
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Simpan perubahan'),
            ),
          ],
        );
      });
  }
}

class _AvatarPicker extends GetView<ProfileEditController> {
  const _AvatarPicker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Obx(() {
            final bytes = controller.avatarBytes.value;
            final url = controller.currentAvatarUrl;

            return Stack(
              children: [
                Container(
                  width: 96.w,
                  height: 96.w,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover,
                          width: 96.w, height: 96.w)
                      : (url != null && url.isNotEmpty)
                          ? Image.network(url, fit: BoxFit.cover,
                              width: 96.w, height: 96.w,
                              errorBuilder: (_, _, _) => _initials())
                          : _initials(),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: controller.pickAvatar,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: EdgeInsets.all(7.w),
                        child: Icon(Iconsax.camera, size: 15.sp,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
          SizedBox(height: AppSpacing.sm.h),
          TextButton(
            onPressed: controller.pickAvatar,
            child: Text(
              'Ubah foto',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _initials() => Text(
        Formatters.initials(controller.userName),
        style: GoogleFonts.poppins(
          fontSize: 28.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      );
}
