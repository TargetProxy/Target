import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_motion.dart';

/// [Animate] wrapper that drops the animation when the platform requests
/// reduced motion; `flutter_animate` itself has no notion of that flag.
///
/// Pass a `key` to replay the effects when the value that drives them changes.
class AppAnimate extends StatelessWidget {
  const AppAnimate({
    required this.child,
    this.effects = const [],
    this.target,
    this.staticChild,
    super.key,
  });

  final Widget child;
  final List<Effect> effects;

  /// Animates towards this position (`0`-`1`) whenever it changes, instead of
  /// playing [effects] once on mount.
  final double? target;

  /// End state to render instead of [child] when motion is reduced. Only
  /// needed by [target]-driven animations, whose start position is blank.
  final Widget? staticChild;

  @override
  Widget build(BuildContext context) => AppMotion.reduced(context)
      ? (staticChild ?? child)
      : Animate(effects: effects, target: target, child: child);
}
