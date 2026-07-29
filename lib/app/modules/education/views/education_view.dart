import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/widgets/record_list_scaffold.dart';
import '../controllers/education_controller.dart';
import 'widgets/education_form_sheet.dart';

/// `api/v1/profile/educations`.
class EducationView extends GetView<EducationController> {
  const EducationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.records.toList();

      return RecordListScaffold(
        title: 'Pendidikan',
        addLabel: 'Tambah',
        emptyIcon: Iconsax.teacher,
        emptyMessage:
            'Belum ada riwayat pendidikan. Menambahkannya menaikkan kelengkapan profilmu.',
        isLoading: controller.isLoading.value,
        errorMessage: controller.errorMessage.value,
        itemCount: records.length,
        onRetry: controller.load,
        onAdd: () => EducationFormSheet.show(context, controller),
        itemBuilder: (context, index) {
          final record = records[index];

          final level = EducationController.levels
              .firstWhere(
                (option) => option.value == record.level,
                orElse: () => (value: record.level, label: record.level),
              )
              .label;

          return RecordCard(
            title: record.institution,
            subtitle: [
              level,
              if (record.major != null && record.major!.isNotEmpty)
                record.major!,
            ].join(' · '),
            details: [
              '${record.startYear} – ${record.endYear ?? 'sekarang'}',
              if (record.gpa != null) 'IPK ${record.gpa}',
            ],
            description: record.description,
            onEdit: () => EducationFormSheet.show(
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
}
