import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/widgets/record_list_scaffold.dart';
import '../controllers/certification_controller.dart';
import 'widgets/certification_form_sheet.dart';

/// `api/v1/profile/certifications`.
class CertificationView extends GetView<CertificationController> {
  const CertificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final records = controller.records.toList();

      return RecordListScaffold(
        title: 'Sertifikat',
        addLabel: 'Tambah',
        emptyIcon: Iconsax.medal_star,
        emptyMessage:
            'Belum ada sertifikat. Menambahkannya menaikkan kelengkapan profilmu.',
        isLoading: controller.isLoading.value,
        errorMessage: controller.errorMessage.value,
        itemCount: records.length,
        onRetry: controller.load,
        onAdd: () => CertificationFormSheet.show(context, controller),
        itemBuilder: (context, index) {
          final record = records[index];

          return RecordCard(
            title: record.name,
            subtitle: record.issuer,
            details: [
              if (record.issuedDate != null) 'Terbit ${record.issuedDate}',
              if (record.expiresDate != null) 'Berlaku s/d ${record.expiresDate}',
              if (record.credentialId != null &&
                  record.credentialId!.isNotEmpty)
                'ID ${record.credentialId}',
            ],
            onEdit: () => CertificationFormSheet.show(
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
