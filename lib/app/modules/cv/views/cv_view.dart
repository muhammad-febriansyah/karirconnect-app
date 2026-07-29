import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/cv_model.dart';
import '../controllers/cv_controller.dart';

/// `api/v1/cvs` — uploaded resumes. The one marked active is what
/// `SubmitApplicationAction` attaches to a new application.
class CvView extends GetView<CvController> {
  const CvView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('CV Saya'),
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: controller.openBuilder,
            tooltip: 'CV Builder',
            icon: Icon(Iconsax.magicpen, size: 20.sp, color: AppColors.primary),
          ),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton.extended(
          onPressed:
              controller.isUploading.value ? null : controller.pickAndUpload,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: controller.isUploading.value
              ? SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Iconsax.document_upload),
          label: Text(
            controller.isUploading.value ? 'Mengunggah…' : 'Unggah CV',
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
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
                const EmptyState(
                  icon: Iconsax.document_text,
                  message:
                      'Belum ada CV. Unggah berkas PDF/DOC/DOCX maksimal 5 MB, atau buat lewat CV Builder.',
                ),
                SizedBox(height: 14.h),
                OutlinedButton.icon(
                  onPressed: controller.openBuilder,
                  icon: Icon(Iconsax.magicpen, size: 17.sp),
                  label: const Text('Buka CV Builder'),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: EdgeInsets.fromLTRB(18.w, 8.h, 18.w, 90.h),
            itemCount: items.length,
            separatorBuilder: (_, _) => SizedBox(height: 12.h),
            itemBuilder: (context, index) => _CvCard(
              cv: items[index],
              controller: controller,
            ),
          );
        }),
      ),
    );
  }
}

class _CvCard extends StatelessWidget {
  const _CvCard({required this.cv, required this.controller});

  final CandidateCvModel cv;
  final CvController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      // The active CV is signalled by a stronger tint, not by a ring. It also
      // carries an "Aktif" badge below, so the stroke was saying it twice.
      decoration: BoxDecoration(
        color: cv.isActive ? AppColors.accent : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(
                  cv.isGenerated ? Iconsax.magicpen : Iconsax.document_text,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cv.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13.sp,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandNavy,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      [
                        cv.isGenerated ? 'Dibuat CV Builder' : 'Unggahan',
                        if (cv.pagesCount != null) '${cv.pagesCount} halaman',
                        Formatters.relative(cv.createdAt),
                      ].where((part) => part.isNotEmpty).join(' · '),
                      style: GoogleFonts.poppins(
                        fontSize: 10.5.sp,
                        color: AppColors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
              if (cv.isActive)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    'Utama',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              if (!cv.isActive)
                Expanded(
                  child: _Action(
                    icon: Iconsax.tick_circle,
                    label: 'Jadikan utama',
                    onTap: () => controller.setActive(cv),
                  ),
                ),
              Expanded(
                child: _Action(
                  icon: Iconsax.edit_2,
                  label: 'Ganti nama',
                  onTap: () => _rename(context),
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Iconsax.trash,
                  label: 'Hapus',
                  destructive: true,
                  onTap: () => controller.remove(cv),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context) async {
    final field = TextEditingController(text: cv.label);

    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Ganti nama CV',
          style: GoogleFonts.poppins(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.brandNavy,
          ),
        ),
        content: TextField(
          controller: field,
          autofocus: true,
          maxLength: 120,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            color: AppColors.foreground,
          ),
          decoration: const InputDecoration(hintText: 'Nama CV'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(field.text),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    field.dispose();

    if (label != null) await controller.rename(cv, label);
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color =
        destructive ? AppColors.destructive : AppColors.mutedForeground;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 6.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14.sp, color: color),
            SizedBox(width: 5.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5.sp,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
