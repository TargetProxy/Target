import 'package:material_ui/material_ui.dart';

class ProxyLatencyChip extends StatelessWidget {
  const ProxyLatencyChip({this.latencyMs, super.key});

  final int? latencyMs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (latencyMs == null) {
      return Text(
        '--',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    final ms = latencyMs!;
    Color color;
    if (ms < 100) {
      color = const Color(0xff16a34a);
    } else if (ms < 300) {
      color = const Color(0xffd97706);
    } else {
      color = const Color(0xffdc2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${ms}ms',
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
