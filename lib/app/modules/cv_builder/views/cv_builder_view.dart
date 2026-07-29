import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/cv_model.dart';
import '../controllers/cv_builder_controller.dart';
import 'widgets/entry_sheets.dart';

/// `api/v1/cv-builder` — fills in structured data and the server renders a PDF
/// that lands in the CV list. Separate from uploading a file.
class CvBuilderView extends GetView<CvBuilderController> {
  const CvBuilderView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CV Builder'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 10.h),
          child: Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value ? null : controller.build,
              child: controller.isSaving.value
                  ? SizedBox(
                      width: 18.w,
                      height: 18.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Buat CV'),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) return const SectionLoader();

        final error = controller.errorMessage.value;
        if (error != null) {
          return ListView(
            padding: EdgeInsets.all(18.w),
            children: [ErrorState(message: error, onRetry: controller.load)],
          );
        }

        return ListView(
          padding: EdgeInsets.fromLTRB(18.w, 12.h, 18.w, 20.h),
          children: [
            LabeledField(
              label: 'Nama file CV',
              controller: controller.labelController,
              hint: 'Misal: CV Frontend 2026',
            ),
            _SectionTitle('Data diri'),
            LabeledField(
              label: 'Nama lengkap',
              controller: controller.fullNameController,
              hint: 'Nama sesuai identitas',
            ),
            LabeledField(
              label: 'Headline',
              controller: controller.headlineController,
              hint: 'Misal: Frontend Developer',
            ),
            LabeledField(
              label: 'Email',
              controller: controller.emailController,
              hint: 'nama@email.com',
              keyboardType: TextInputType.emailAddress,
            ),
            LabeledField(
              label: 'Telepon',
              controller: controller.phoneController,
              hint: '08xxxxxxxxxx',
              keyboardType: TextInputType.phone,
            ),
            LabeledField(
              label: 'Lokasi',
              controller: controller.locationController,
              hint: 'Kota, Provinsi',
            ),
            LabeledField(
              label: 'Website / portofolio',
              controller: controller.websiteController,
              hint: 'https://…',
              keyboardType: TextInputType.url,
            ),
            _SectionTitle('Ringkasan'),
            LabeledField(
              label: 'Tentang kamu',
              controller: controller.summaryController,
              hint: 'Dua sampai tiga kalimat tentang pengalaman dan tujuanmu',
              maxLines: 5,
            ),
            _SectionTitle('Keahlian'),
            LabeledField(
              label: 'Pisahkan dengan koma',
              controller: controller.skillsController,
              hint: 'Flutter, Dart, REST API',
              maxLines: 2,
            ),
            _EntryList<CvBuilderExperience>(
              title: 'Pengalaman kerja',
              items: controller.experiences,
              titleOf: (row) => row.position,
              subtitleOf: (row) => [
                row.company,
                if (row.period != null && row.period!.isNotEmpty) row.period!,
              ].join(' · '),
              onAdd: () => ExperienceSheet.show(context, controller),
              onRemove: controller.removeExperience,
            ),
            _EntryList<CvBuilderEducation>(
              title: 'Pendidikan',
              items: controller.educations,
              titleOf: (row) => row.institution,
              subtitleOf: (row) => [
                if (row.major != null && row.major!.isNotEmpty) row.major!,
                if (row.period != null && row.period!.isNotEmpty) row.period!,
                if (row.gpa != null && row.gpa!.isNotEmpty) 'IPK ${row.gpa}',
              ].join(' · '),
              onAdd: () => EducationEntrySheet.show(context, controller),
              onRemove: controller.removeEducation,
            ),
            _EntryList<CvBuilderCertification>(
              title: 'Sertifikat',
              items: controller.certifications,
              titleOf: (row) => row.name,
              subtitleOf: (row) => [
                if (row.issuer != null && row.issuer!.isNotEmpty) row.issuer!,
                if (row.year != null && row.year!.isNotEmpty) row.year!,
              ].join(' · '),
              onAdd: () => CertificationEntrySheet.show(context, controller),
              onRemove: controller.removeCertification,
            ),
          ],
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.brandNavy,
        ),
      ),
    );
  }
}

/// Repeating block with an add button and a remove action per row.
class _EntryList<T> extends StatelessWidget {
  const _EntryList({
    required this.title,
    required this.items,
    required this.titleOf,
    required this.subtitleOf,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final RxList<T> items;
  final String Function(T) titleOf;
  final String Function(T) subtitleOf;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8.h, bottom: 10.h),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandNavy,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: Icon(Iconsax.add, size: 15.sp),
                label: Text(
                  'Tambah',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        Obx(() {
          if (items.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Text(
                'Belum ada data.',
                style: GoogleFonts.poppins(
                  fontSize: 11.5.sp,
                  color: AppColors.mutedForeground,
                ),
              ),
            );
          }

          return Column(
            children: List.generate(items.length, (index) {
              final row = items[index];

              return Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.fromLTRB(14.w, 12.h, 6.w, 12.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSoft,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleOf(row),
                            style: GoogleFonts.poppins(
                              fontSize: 12.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandNavy,
                            ),
                          ),
                          Text(
                            subtitleOf(row),
                            style: GoogleFonts.poppins(
                              fontSize: 11.sp,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: Icon(
                        Iconsax.trash,
                        size: 16.sp,
                        color: AppColors.destructive,
                      ),
                    ),
                  ],
                ),
              );
            }),
          );
        }),
      ],
    );
  }
}
