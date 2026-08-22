import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/format_bytes.dart';
import '../../../../data/models/subscription.dart';

class TrafficQuotaBar extends StatelessWidget {
  const TrafficQuotaBar({required this.subscription, super.key});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final total = subscription.totalBytes;
    if (total == null || total <= 0) return const SizedBox.shrink();

    final used = subscription.uploadBytes + subscription.downloadBytes;
    final percent = (used / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upload: ${formatBytes(subscription.uploadBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              'Download: ${formatBytes(subscription.downloadBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatBytes(used)} / ${formatBytes(total)} (${(percent * 100).toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
