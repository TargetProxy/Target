import 'package:flutter/widgets.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const standard = Duration(milliseconds: 260);
  static const emphasized = Duration(milliseconds: 420);

  static const easeOut = Curves.easeOutCubic;
  static const easeIn = Curves.easeInCubic;
  static const emphasizedCurve = Curves.easeOutBack;

  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.maybeOf(context)?.disableAnimations == true
      ? Duration.zero
      : value;
}
