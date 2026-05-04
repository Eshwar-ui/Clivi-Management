import 'package:flutter/widgets.dart';

/// Lightweight responsive helper for breakpoints and sizing.
class R {
  R(this.size);

  final Size size;

  double get w => size.width;
  double get h => size.height;

  bool get isMobile => w < 600;
  bool get isTablet => w >= 600 && w < 1024;
  bool get isDesktop => w >= 1024;

  EdgeInsets get pad => EdgeInsets.symmetric(
    horizontal: isDesktop
        ? 32
        : isTablet
        ? 24
        : 16,
  );

  double font(double mobile, {double? tablet, double? desktop}) {
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
