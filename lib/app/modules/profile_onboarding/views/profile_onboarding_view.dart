import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/states.dart';
import '../controllers/profile_onboarding_controller.dart';

/// Three-step wizard over `POST api/v1/onboarding`. Shares
/// `CompleteOnboardingAction` with the web, so the required set is identical.
class ProfileOnboardingView extends GetView<ProfileOnboardingController> {
  const ProfileOnboardingView({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: const _Footer(),
        body: Column(
          children: [
            GradientHeaderBar(
              title: 'Lengkapi Profil',
              subtitle: 'Tiga langkah agar siap melamar',
              onBack: controller.back,
            ),
            Expanded(child: _Body()),
          ],
        ),
      ),
    );
  }
}

class _Body extends GetView<ProfileOnboardingController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const SectionLoader();

      final error = controller.errorMessage.value;
      if (error != null) {
        return ListView(
          padding: EdgeInsets.all(AppSpacing.gutter.w),
          children: [ErrorState(message: error, onRetry: controller.onInit)],
        );
      }

      return Column(
        children: [
          SizedBox(height: AppSpacing.lg.h),
          const _StepBar(),
          Expanded(
              // IndexedStack, not PageView: steps validate in order so swiping
              // is not wanted anyway, and a PageView pinned with
              // NeverScrollableScrollPhysics swallows the pointer-scroll events
              // its own children need — the step content could not be scrolled
              // at all, which hid the province and city pickers.
            child: IndexedStack(
              index: controller.currentStep.value,
              children: const [_StepIdentity(), _StepCareer(), _StepReview()],
            ),
          ),
        ],
      );
    });
  }
}

class _StepBar extends GetView<ProfileOnboardingController> {
  const _StepBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 14.h),
      child: Obx(
        () => Row(
          children: List.generate(
            ProfileOnboardingController.stepCount,
            (index) => Expanded(
              child: Container(
                height: 4.h,
                margin: EdgeInsets.only(right: index == 2 ? 0 : 6.w),
                decoration: BoxDecoration(
                  color: index <= controller.currentStep.value
                      ? AppColors.primary
                      : AppColors.border,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepIdentity extends GetView<ProfileOnboardingController> {
  const _StepIdentity();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 20.h),
      children: [
        const _ParseCvCard(),
        SizedBox(height: 18.h),
        LabeledField(
          label: 'Headline',
          controller: controller.headlineController,
          hint: 'Misal: Frontend Developer · React',
        ),
        LabeledField(
          label: 'Tentang kamu',
          controller: controller.aboutController,
          hint: 'Ceritakan pengalaman, keahlian, dan tujuan kariermu',
          maxLines: 5,
        ),
        LabeledField(
          label: 'Nomor telepon',
          controller: controller.phoneController,
          hint: '08xxxxxxxxxx',
          keyboardType: TextInputType.phone,
        ),
        Obx(
          () => _DateField(
            label: 'Tanggal lahir',
            value: controller.dateOfBirth.value,
            onTap: () => _pickBirthDate(context),
          ),
        ),
        Obx(
          () => ChipPicker(
            label: 'Jenis kelamin',
            options: ProfileOnboardingController.genders,
            selected: controller.gender.value,
            allowClear: false,
            onSelected: (value) => controller.gender.value = value,
          ),
        ),
        Obx(
          () => ChipPicker(
            label: 'Provinsi',
            options: controller.meta.value.provinces
                .map((province) =>
                    (value: '${province.id}', label: province.name))
                .toList(),
            selected: controller.provinceId.value?.toString(),
            allowClear: false,
            onSelected: (value) => controller.selectProvince(
              value == null ? null : int.tryParse(value),
            ),
          ),
        ),
        Obx(() {
          final cities = controller.cities;

          if (cities.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Text(
                'Pilih provinsi dulu untuk memilih kota.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            );
          }

          return ChipPicker(
            label: 'Kota',
            options: cities
                .map((city) => (value: '${city.id}', label: city.name))
                .toList(),
            selected: controller.cityId.value?.toString(),
            allowClear: false,
            onSelected: (value) => controller.cityId.value =
                value == null ? null : int.tryParse(value),
          );
        }),
      ],
    );
  }

  Future<void> _pickBirthDate(BuildContext context) async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: controller.dateOfBirth.value ?? DateTime(now.year - 22),
      firstDate: DateTime(1940),
      // Server rule is `before:today`.
      lastDate: now.subtract(const Duration(days: 1)),
    );

    if (picked != null) controller.dateOfBirth.value = picked;
  }
}

class _ParseCvCard extends GetView<ProfileOnboardingController> {
  const _ParseCvCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.magicpen, size: 15.sp, color: AppColors.brandCyan),
              SizedBox(width: 7.w),
              Text(
                'Isi otomatis dari CV',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            'Unggah CV dan AI akan mengisi sebagian form ini. '
            'Kolom yang sudah kamu isi tidak akan ditimpa.',
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 14.h),
          Obx(
            () => ElevatedButton.icon(
              onPressed:
                  controller.isParsing.value ? null : controller.parseCv,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.brandNavy,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
              ),
              icon: controller.isParsing.value
                  ? SizedBox(
                      width: 15.w,
                      height: 15.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.brandNavy),
                      ),
                    )
                  : Icon(Iconsax.document_upload, size: 16.sp),
              label: Text(
                controller.isParsing.value ? 'Membaca CV…' : 'Unggah CV',
                style: GoogleFonts.poppins(
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCareer extends GetView<ProfileOnboardingController> {
  const _StepCareer();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 20.h),
      children: [
        LabeledField(
          label: 'Posisi saat ini',
          controller: controller.positionController,
          hint: 'Misal: Junior Developer',
        ),
        Obx(
          () => ChipPicker(
            label: 'Level pengalaman',
            options: controller.meta.value.experienceLevels
                .map((option) => (value: option.value, label: option.label))
                .toList(),
            selected: controller.experienceLevel.value,
            allowClear: false,
            onSelected: (value) => controller.experienceLevel.value = value,
          ),
        ),
        LabeledField(
          label: 'Keahlian (pisahkan dengan koma)',
          controller: controller.skillsController,
          hint: 'Flutter, Dart, REST API',
          maxLines: 3,
        ),
        LabeledField(
          label: 'LinkedIn',
          controller: controller.linkedinController,
          hint: 'https://linkedin.com/in/…',
          keyboardType: TextInputType.url,
        ),
        LabeledField(
          label: 'Portofolio',
          controller: controller.portfolioController,
          hint: 'https://…',
          keyboardType: TextInputType.url,
        ),
        LabeledField(
          label: 'GitHub',
          controller: controller.githubController,
          hint: 'https://github.com/…',
          keyboardType: TextInputType.url,
        ),
      ],
    );
  }
}

class _StepReview extends GetView<ProfileOnboardingController> {
  const _StepReview();

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final meta = controller.meta.value;

      final province = meta.provinces
          .firstWhereOrNull((row) => row.id == controller.provinceId.value)
          ?.name;
      final city = meta.cities
          .firstWhereOrNull((row) => row.id == controller.cityId.value)
          ?.name;
      final level = meta.experienceLevels
          .firstWhereOrNull((row) => row.value == controller.experienceLevel.value)
          ?.label;
      final genderLabel = ProfileOnboardingController.genders
          .firstWhereOrNull((row) => row.value == controller.gender.value)
          ?.label;
      final birth = controller.dateOfBirth.value;

      return ListView(
        padding: EdgeInsets.fromLTRB(18.w, 0, 18.w, 20.h),
        children: [
          Text(
            'Periksa kembali',
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Setelah dikirim, profilmu bisa diubah lagi kapan saja lewat tab Profil.',
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              height: 1.45,
              color: AppColors.mutedForeground,
            ),
          ),
          SizedBox(height: 16.h),
          _ReviewCard(
            rows: [
              (label: 'Headline', value: controller.headlineController.text),
              (
                label: 'Tanggal lahir',
                value: birth == null
                    ? '-'
                    : '${birth.day.toString().padLeft(2, '0')}/'
                        '${birth.month.toString().padLeft(2, '0')}/${birth.year}',
              ),
              (label: 'Jenis kelamin', value: genderLabel ?? '-'),
              (
                label: 'Lokasi',
                value: [city, province].whereType<String>().join(', '),
              ),
              (label: 'Level', value: level ?? '-'),
              (
                label: 'Keahlian',
                value: '${controller.skills.length} keahlian',
              ),
            ],
          ),
        ],
      );
    });
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.rows});

  final List<({String label, String value})> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: rows
            .map(
              (row) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100.w,
                      child: Text(
                        row.label,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5.sp,
                          color: AppColors.mutedForeground,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value.trim().isEmpty ? '-' : row.value,
                        style: GoogleFonts.poppins(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 6.h),
          InkWell(
            onTap: onTap,
            child: InputDecorator(
              decoration: const InputDecoration(),
              child: Text(
                value == null
                    ? 'Pilih tanggal'
                    : '${value!.day.toString().padLeft(2, '0')}/'
                        '${value!.month.toString().padLeft(2, '0')}/'
                        '${value!.year}',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: value == null
                      ? AppColors.mutedForeground
                      : AppColors.foreground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends GetView<ProfileOnboardingController> {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 10.h),
        child: Obx(
          () => Row(
            children: [
              if (controller.currentStep.value > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.back,
                    child: const Text('Kembali'),
                  ),
                ),
                SizedBox(width: 10.w),
              ],
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed:
                      controller.isSubmitting.value ? null : controller.next,
                  child: controller.isSubmitting.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(controller.isLastStep ? 'Kirim' : 'Lanjut'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
