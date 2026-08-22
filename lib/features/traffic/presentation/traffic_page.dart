import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/target_page_layout.dart';

class TrafficPage extends ConsumerWidget {
  const TrafficPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final core = ref.watch(coreProvider);
    final traffic = core.traffic;
    final theme = Theme.of(context);
    return SafeArea(
      child: TargetPageLayout(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TargetPageHeader(
                  title: 'Traffic',
                  subtitle: 'Live throughput and runtime activity.',
                ),
                const SizedBox(height: 22),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 800
                      ? 2
                      : 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3.8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Metric(
                      title: 'Upload rate',
                      value: formatSpeed(traffic.uploadBytes),
                      icon: Icons.arrow_upward,
                      color: Colors.orange,
                    ),
                    _Metric(
                      title: 'Download rate',
                      value: formatSpeed(traffic.downloadBytes),
                      icon: Icons.arrow_downward,
                      color: Colors.blue,
                    ),
                    _Metric(
                      title: 'Uploaded total',
                      value: formatBytes(traffic.uploadBytes),
                      icon: Icons.north_east,
                      color: Colors.orange,
                    ),
                    _Metric(
                      title: 'Downloaded total',
                      value: formatBytes(traffic.downloadBytes),
                      icon: Icons.south_west,
                      color: Colors.blue,
                    ),
                    _Metric(
                      title: 'Active connections',
                      value: '${traffic.activeConnections}',
                      icon: Icons.cable,
                      color: theme.colorScheme.primary,
                    ),
                    _Metric(
                      title: 'Observation state',
                      value: core.running ? 'Available' : 'Stopped',
                      icon: core.running ? Icons.check_circle : Icons.bolt,
                      color: core.running
                          ? Colors.green
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const TargetSectionTitle(
                  icon: Icons.show_chart,
                  title: 'Traffic history',
                ),
                const SizedBox(height: 12),
                Card(
                  child: SizedBox(
                    height: 220,
                    child: Center(
                      child: Text(
                        core.running
                            ? 'Collecting traffic samples…'
                            : 'Start the service to collect traffic history.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
