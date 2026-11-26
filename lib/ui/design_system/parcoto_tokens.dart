import 'package:fluent_ui/fluent_ui.dart';

/// Shared layout and visual tokens for the Parcoto UI.
///
/// Keep these values independent from individual screens. New screens should
/// consume this class instead of defining their own spacing and breakpoints.
abstract final class ParcotoTokens {
  // Layout spacing (multiples of 4 logical pixels).
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space7 = 28;
  static const double space8 = 32;
  static const double space10 = 40;
  static const double space12 = 48;

  // Responsive layout thresholds.
  static const double mobileBreakpoint = 640;
  static const double tabletBreakpoint = 960;
  static const double desktopBreakpoint = 1280;

  // Surface geometry.
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 22;

  static const double borderThin = 1;
  static const double contentMaxWidth = 1600;
  static const double sidebarWidth = 220;
  static const double sidebarCollapsedWidth = 68;
  static const double topbarHeight = 72;
  static const double mobileTopbarHeight = 60;

  static const Duration motionFast = Duration(milliseconds: 140);
  static const Duration motionStandard = Duration(milliseconds: 220);
  static const Curve motionCurve = Curves.easeOutCubic;
}

enum ParcotoSurfaceTone {
  canvas,
  elevated,
  subtle,
}
