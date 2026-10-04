import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../l10n/app_localizations.dart';

class TrafficPage extends ConsumerWidget {
  const TrafficPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider);
    final traffic = core.traffic;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: TargetPageLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TargetPageHeader(
              title: l10n.traffic,
              subtitle: l10n.trafficSubtitle,
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.liveTraffic,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusLabel(running: core.running),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final metrics = [
                          _Metric(
                            title: l10n.uploadRate,
                            value: core.running
                                ? formatSpeed(traffic.uploadBytes)
                                : '--',
                            icon: Icons.arrow_upward,
                            color: colors.tertiary,
                          ),
                          _Metric(
                            title: l10n.downloadRate,
                            value: core.running
                                ? formatSpeed(traffic.downloadBytes)
                                : '--',
                            icon: Icons.arrow_downward,
                            color: colors.primary,
                          ),
                          _Metric(
                            title: l10n.activeConnections,
                            value: core.running
                                ? '${traffic.activeConnections}'
                                : '--',
                            icon: Icons.hub_outlined,
                            color: colors.secondary,
                          ),
                        ];
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              for (
                                var index = 0;
                                index < metrics.length;
                                index++
                              ) ...[
                                metrics[index],
                                if (index < metrics.length - 1)
                                  Divider(color: colors.outlineVariant),
                              ],
                            ],
                          );
                        }
                        return SizedBox(
                          height: 80,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < metrics.length;
                                index++
                              ) ...[
                                Expanded(child: metrics[index]),
                                if (index < metrics.length - 1)
                                  VerticalDivider(color: colors.outlineVariant),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final color = running ? colors.primary : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          running ? Icons.check_circle : Icons.pause_circle_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          running ? l10n.running : l10n.stopped,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
