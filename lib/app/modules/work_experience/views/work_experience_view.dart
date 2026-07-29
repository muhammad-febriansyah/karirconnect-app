import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/record_list_scaffold.dart';
import '../controllers/work_experience_controller.dart';
import 'widgets/work_experience_form_sheet.dart';

/// `api/v1/profile/work-experiences`.
class WorkExperienceView extends GetView<WorkExperienceController> {
  const WorkExperienceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.records.toList();

      return RecordListScaffold(
        title: 'Pengalaman Kerja',
        addLabel: 'Tambah',
        emptyIcon: Iconsax.briefcase,
        emptyMessage:
            'Belum ada pengalaman kerja. Menambahkannya menaikkan kelengkapan profilmu.',
        isLoading: controller.isLoading.value,
        errorMessage: controller.errorMessage.value,
        itemCount: records.length,
        onRetry: controller.load,
        onAdd: () => WorkExperienceFormSheet.show(context, controller),
        itemBuilder: (context, index) {
          final record = records[index];

          return RecordCard(
            title: record.position,
            subtitle: record.companyName,
            details: [
              '${_month(record.startDate)} – '
                  '${record.isCurrent ? 'sekarang' : _month(record.endDate)}',
              if (record.employmentType != null)
                Formatters.status(record.employmentType),
            ],
            description: record.description,
            onEdit: () => WorkExperienceFormSheet.show(
              context,
              controller,
              existing: record,
            ),
            onDelete: () => controller.remove(record),
          );
        },
      );
    });
  }

  /// The API stores these as full dates but only the month matters here.
  static String _month(String? iso) {
    if (iso == null || iso.isEmpty) return '-';

    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return iso;

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${months[parsed.month - 1]} ${parsed.year}';
  }
}
