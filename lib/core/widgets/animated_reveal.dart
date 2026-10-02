import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/app_motion.dart';

class AnimatedReveal extends StatelessWidget {
  const AnimatedReveal({
    required this.child,
    this.duration = AppMotion.standard,
    this.delay = Duration.zero,
    this.offset = 10,
    this.beginScale = 0.985,
    this.curve = AppMotion.easeOut,
    this.axis = Axis.vertical,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double offset;
  final double beginScale;
  final Curve curve;
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final total = AppMotion.duration(context, duration + delay);
    final delayFraction = total.inMicroseconds == 0
        ? 0.0
        : math.min(1, delay.inMicroseconds / total.inMicroseconds).toDouble();
    final animationCurve = delayFraction == 0
        ? curve
        : Interval(delayFraction, 1, curve: curve);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: animationCurve,
      builder: (context, value, child) {
        final distance = (1 - value) * offset;
        final translation = axis == Axis.vertical
            ? Offset(0, distance)
            : Offset(distance, 0);
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: translation,
            child: Transform.scale(
              scale: beginScale + (1 - beginScale) * value,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
