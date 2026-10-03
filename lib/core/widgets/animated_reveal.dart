import 'package:flutter_animate/flutter_animate.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_motion.dart';
import 'app_animate.dart';

/// Entrance transition for page sections and list rows.
///
/// The delay is carried by the effects rather than by [Animate.delay] so the
/// controller starts on the first frame instead of waiting on a timer.
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
    final begin = axis == Axis.vertical ? Offset(0, offset) : Offset(offset, 0);
    return AppAnimate(
      effects: [
        FadeEffect(delay: delay, duration: duration, curve: curve),
        MoveEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: begin,
        ),
        ScaleEffect(
          delay: delay,
          duration: duration,
          curve: curve,
          begin: Offset(beginScale, beginScale),
        ),
      ],
      child: child,
    );
  }
}
