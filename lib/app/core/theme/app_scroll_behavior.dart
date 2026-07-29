import 'package:flutter/material.dart';

/// Every scrollable in the app, on every platform.
///
/// Set once on `GetMaterialApp.scrollBehavior` rather than per widget: there
/// are ~76 scroll views across the modules, and a physics chosen at each call
/// site is a physics that will be forgotten at the next one.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  /// Bouncing everywhere, including Android and web.
  ///
  /// [AlwaysScrollableScrollPhysics] is the parent so a list shorter than its
  /// viewport still accepts a drag — without it, `RefreshIndicator` on a short
  /// or empty list has nothing to pull.
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  /// No scrollbars. On web and desktop Flutter otherwise paints one over every
  /// short horizontal rail, which is what the per-widget `ScrollConfiguration`
  /// wrappers used to suppress one at a time.
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;

  /// No glow either. The Android overscroll glow is the stretch/glow feedback
  /// for a clamping physics; with bouncing it would double up on the rubber
  /// band that already communicates the edge.
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}
