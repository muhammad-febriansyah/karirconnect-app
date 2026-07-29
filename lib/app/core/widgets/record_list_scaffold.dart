import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import '../theme/app_theme.dart';
import '../values/app_colors.dart';
import 'gradient_header.dart';
import 'states.dart';

/// Chrome shared by the three profile sub-resource screens: gradient header,
/// add button, the loading / error / empty states, and a card per record with
/// edit and delete actions.
class RecordListScaffold extends StatelessWidget {
  const RecordListScaffold({
    super.key,
    required this.title,
    required this.addLabel,
    required this.emptyMessage,
    required this.emptyIcon,
    required this.isLoading,
    required this.errorMessage,
    required this.itemCount,
    required this.itemBuilder,
    required this.onRetry,
    required this.onAdd,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final String addLabel;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool isLoading;
  final String? errorMessage;
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final Future<void> Function() onRetry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: onAdd,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Iconsax.add),
          label: Text(
            addLabel,
            style: GoogleFonts.poppins(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: [
            GradientHeaderBar(title: title, subtitle: subtitle),
            Expanded(
              child: RefreshIndicator(
                onRefresh: onRetry,
                color: AppColors.primary,
                child: Builder(
                  builder: (context) {
                    if (isLoading) return const SectionLoader();

                    final gutter = EdgeInsets.fromLTRB(
                      AppSpacing.gutter.w,
                      AppSpacing.xl.h,
                      AppSpacing.gutter.w,
                      90.h,
                    );

                    if (errorMessage != null) {
                      return ListView(
                        padding: gutter,
                        children: [
                          ErrorState(message: errorMessage!, onRetry: onRetry),
                        ],
                      );
                    }

                    if (itemCount == 0) {
                      return ListView(
                        padding: gutter,
                        children: [
                          EmptyState(icon: emptyIcon, message: emptyMessage),
                        ],
                      );
                    }

                    return ListView.separated(
                      padding: gutter,
                      itemCount: itemCount,
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSpacing.md.h),
                      itemBuilder: itemBuilder,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One record: a title/subtitle block, optional detail lines, and the
/// edit/delete row.
class RecordCard extends StatelessWidget {
  const RecordCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
    this.details = const [],
    this.description,
  });

  final String title;
  final String subtitle;
  final List<String> details;
  final String? description;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 13.5.sp,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: AppColors.brandNavy,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 11.5.sp,
              color: AppColors.mutedForeground,
            ),
          ),
          if (details.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              children: details
                  .map(
                    (detail) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 9.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Text(
                        detail,
                        style: GoogleFonts.poppins(
                          fontSize: 10.sp,
                          color: AppColors.foreground.withValues(alpha: 0.75),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (description != null && description!.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              description!,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.5.sp,
                height: 1.45,
                color: AppColors.foreground.withValues(alpha: 0.8),
              ),
            ),
          ],
          const Divider(height: 22, color: AppColors.border),
          Row(
            children: [
              Expanded(
                child: _Action(
                  icon: Iconsax.edit_2,
                  label: 'Ubah',
                  onTap: onEdit,
                ),
              ),
              Expanded(
                child: _Action(
                  icon: Iconsax.trash,
                  label: 'Hapus',
                  destructive: true,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
            SizedBox(width: 6.w),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
