import 'package:flutter/widgets.dart';

/// Screen-relative sizing helpers.
///
/// Baseline design width is 390 (standard portrait phone). Use [rs] to scale
/// a fixed design dimension with the device, and [wp]/[hp] for fractions of
/// the screen. Scaling uses the shortest side so landscape and tablets don't
/// blow layouts up, and is clamped to a sane range.
extension Responsive on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  /// Device scale factor relative to the 390dp design width.
  double get scale =>
      (screenSize.shortestSide / 390.0).clamp(0.80, 1.30).toDouble();

  /// Responsive size: scales a design dimension with the device.
  double rs(double size) => size * scale;

  /// Fraction of screen width (0.0 – 1.0).
  double wp(double fraction) => screenWidth * fraction;

  /// Fraction of screen height (0.0 – 1.0).
  double hp(double fraction) => screenHeight * fraction;

  bool get isTablet => screenSize.shortestSide >= 600;
}
