import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/values/app_assets.dart';
import '../../../core/values/app_colors.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingView extends GetView<OnboardingController> {
  const OnboardingView({super.key});

  /// Share of the screen reserved for the action bar. It also decides how much
  /// of each slide gets cropped — see [_Slide].
  static const double _actionBarFactor = 0.19;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: controller.pageController,
                    onPageChanged: controller.onPageChanged,
                    itemCount: controller.pageCount,
                    itemBuilder: (context, index) =>
                        _Slide(asset: AppAssets.onboarding[index]),
                  ),
                ),
                SizedBox(
                  height: _actionBarFactor * 1.sh,
                  child: const _ActionBar(),
                ),
              ],
            ),
            const Positioned(
              top: 0,
              right: 0,
              child: SafeArea(child: _SkipButton()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The artwork already carries its own headline and page dots, and the dot row
/// sits at roughly 95% of the image height in all three files.
///
/// A plain `BoxFit.cover` would not reliably hide it: the slides do not share an
/// aspect ratio (916x1717 vs 941x1672), so how much `cover` trims depends on
/// which slide and which screen. Instead the image is laid out into a box
/// [_bottomTrim] taller than the visible area and clipped back down, which
/// removes the same bottom fraction every time. The only indicator on screen is
/// then the one [_ActionBar] draws.
class _Slide extends StatelessWidget {
  const _Slide({required this.asset});

  /// Fraction of the rendered slide hidden below the clip.
  static const double _bottomTrim = 0.08;

  final String asset;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final overflowHeight = constraints.maxHeight / (1 - _bottomTrim);

            return ClipRect(
              child: OverflowBox(
                alignment: Alignment.topCenter,
                minWidth: constraints.maxWidth,
                maxWidth: constraints.maxWidth,
                minHeight: overflowHeight,
                maxHeight: overflowHeight,
                child: Image.asset(
                  asset,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            );
          },
        ),
        // Softens the crop line where the image meets the action bar.
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 72.h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withValues(alpha: 0),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return Obx(
      () => AnimatedOpacity(
        opacity: controller.isLastPage ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: IgnorePointer(
          ignoring: controller.isLastPage,
          child: Padding(
            padding: EdgeInsets.only(top: 8.h, right: 12.w),
            child: TextButton(
              onPressed: controller.skip,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              ),
              child: Text(
                'Lewati',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OnboardingController>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 12.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  controller.pageCount,
                  (index) => _Dot(active: controller.currentPage.value == index),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: Obx(
                () => ElevatedButton(
                  onPressed: controller.next,
                  child: Text(
                    controller.isLastPage ? 'Mulai Sekarang' : 'Lanjut',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      width: active ? 22.w : 8.w,
      height: 8.w,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4.r),
      ),
    );
  }
}
