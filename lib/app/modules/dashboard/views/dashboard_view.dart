import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/values/app_colors.dart';
import '../../ai_career/views/ai_career_view.dart';
import '../../applications/views/applications_view.dart';
import '../../home/views/home_view.dart';
import '../../jobs/views/jobs_view.dart';
import '../../profile/views/profile_view.dart';
import '../controllers/dashboard_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return PersistentTabView(
      controller: controller.tabController,
      onTabChanged: controller.onTabChanged,
      backgroundColor: AppColors.background,
      navBarOverlap: const NavBarOverlap.none(),
      tabs: _tabs(),
      // Style 13 lifts the middle item into a floating circle, which is why
      // AI Karier sits at index 2. It asserts an odd item count, so `_tabs()`
      // must always stay at 3, 5, 7, ...
      navBarBuilder: (navBarConfig) => Style13BottomNavBar(
        navBarConfig: navBarConfig,
        height: 64.h,
        middleItemSize: 56.w,
        // Tonal fill, no shadow: the bar separates from the white page the
        // same way every card does. Note Style13 reuses `boxShadow` for the
        // floating middle circle too, so dropping it flattens both.
        navBarDecoration: NavBarDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card.r)),
        ),
      ),
    );
  }

  List<PersistentTabConfig> _tabs() => [
        _tab(
          screen: const HomeView(),
          icon: Iconsax.home_15,
          inactiveIcon: Iconsax.home,
          title: 'Beranda',
        ),
        _tab(
          screen: const JobsView(),
          icon: Iconsax.briefcase,
          title: 'Lowongan',
        ),
        _tab(
          screen: const AiCareerView(),
          icon: Iconsax.magicpen,
          title: 'AI Karier',
          // Style13 paints the middle circle with `activeForegroundColor` but
          // its glyph with `inactiveForegroundColor`, so the icon came out
          // slate-on-blue at 1.67:1. Overriding `inactiveForegroundColor`
          // would fix the glyph and erase the label — the same value colours
          // "AI Karier" whenever the tab is not selected, and the nav bar is
          // white. Colouring the Icon itself hits only the glyph.
          iconColor: Colors.white,
        ),
        _tab(
          screen: const ApplicationsView(),
          icon: Iconsax.document_text,
          title: 'Lamaran',
        ),
        _tab(
          screen: const ProfileView(),
          icon: Iconsax.user,
          title: 'Profil',
        ),
      ];

  /// [iconColor] pins the glyph regardless of selection, for the floating
  /// middle item whose circle already supplies the contrast. Leave it null on
  /// the flat tabs so they keep taking their colour from the active/inactive
  /// pair like a normal tab.
  PersistentTabConfig _tab({
    required Widget screen,
    required IconData icon,
    required String title,
    IconData? inactiveIcon,
    Color? iconColor,
  }) =>
      PersistentTabConfig(
        screen: screen,
        item: ItemConfig(
          icon: Icon(icon, color: iconColor),
          inactiveIcon: Icon(inactiveIcon ?? icon, color: iconColor),
          title: title,
          iconSize: 24.sp,
          activeForegroundColor: AppColors.primary,
          inactiveForegroundColor: AppColors.mutedForeground,
          textStyle: GoogleFonts.poppins(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
