import 'package:material_ui/material_ui.dart';

class AnimatedReveal extends StatelessWidget {
  const AnimatedReveal({
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.offset = 10,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * offset),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
