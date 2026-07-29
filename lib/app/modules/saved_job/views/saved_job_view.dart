import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/widgets/job_card.dart';
import '../../../core/widgets/states.dart';
import '../controllers/saved_job_controller.dart';

/// `GET api/v1/saved-jobs` — the destination for the bookmark icon that every
/// job card already shows.
class SavedJobView extends GetView<SavedJobController> {
  const SavedJobView({super.key});

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
            Obx(
              () => GradientHeaderBar(
                title: 'Lowongan Tersimpan',
                subtitle: controller.isLoading.value
                    ? null
                    : '${controller.jobs.length} lowongan disimpan',
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.load,
                color: AppColors.primary,
                child: Obx(() {
                  if (controller.isLoading.value) return const SectionLoader();

                  final gutter = EdgeInsets.fromLTRB(
                    AppSpacing.gutter.w,
                    AppSpacing.xl.h,
                    AppSpacing.gutter.w,
                    AppSpacing.xl.h,
                  );

                  final error = controller.errorMessage.value;
                  if (error != null) {
                    return ListView(
                      padding: gutter,
                      children: [
                        ErrorState(message: error, onRetry: controller.load),
                      ],
                    );
                  }

                  final jobs = controller.jobs.toList();
                  if (jobs.isEmpty) {
                    return ListView(
                      padding: gutter,
                      children: const [
                        EmptyState(
                          icon: Iconsax.archive_add,
                          message:
                              'Belum ada lowongan tersimpan. Tekan ikon bookmark di kartu lowongan untuk menyimpannya.',
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: gutter,
                    itemCount: jobs.length,
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md.h),
                    itemBuilder: (context, index) {
                      final job = jobs[index];

                      return JobCard(
                        job: job,
                        // Everything on this screen is saved by definition.
                        isSaved: true,
                        onTap: () => controller.openJob(job),
                        onSave: () => controller.unsave(job),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
