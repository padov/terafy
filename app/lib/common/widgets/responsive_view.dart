import 'package:flutter/material.dart';

/// A utility widget that renders different layouts based on the screen size.
///
/// Usage:
/// ```dart
/// return ResponsiveView(
///   mobile: MyMobilePage(),
///   tablet: MyTabletPage(), // Optional
///   desktop: MyDesktopPage(), // Optional
/// );
/// ```
class ResponsiveView extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveView({super.key, required this.mobile, this.tablet, this.desktop});

  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < 650;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 650 && MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1100) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= 650) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
