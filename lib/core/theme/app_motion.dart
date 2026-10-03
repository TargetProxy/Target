import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const emphasized = Duration(milliseconds: 420);

  static const easeOut = Curves.easeOutCubic;
  static const easeIn = Curves.easeInCubic;
  static const emphasizedCurve = Curves.easeOutBack;

  static const staggerStep = Duration(milliseconds: 28);
  static const staggerLimit = 8;

  /// `flutter_animate` has no notion of the platform's reduced motion flag, so
  /// every wrapper in this app checks it before handing work to `Animate`.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration stagger(int index, {Duration step = staggerStep}) =>
      step * index.clamp(0, staggerLimit);
}
