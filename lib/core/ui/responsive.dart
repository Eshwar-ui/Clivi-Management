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
  bool get useRail => w >= 900;

  double get maxContentWidth {
    if (w >= 1440) return 1280;
    if (isDesktop) return 1180;
    return w;
  }

  double get gap {
    if (isDesktop) return 24;
    if (isTablet) return 20;
    return 16;
  }

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

  int columns({int mobile = 1, int tablet = 2, int desktop = 3}) {
    if (isDesktop) return desktop;
    if (isTablet) return tablet;
    return mobile;
  }
}

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final r = R(Size(constraints.maxWidth, constraints.maxHeight));
        return Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth ?? r.maxContentWidth,
            ),
            child: Padding(padding: padding ?? r.pad, child: child),
          ),
        );
      },
    );
  }
}
