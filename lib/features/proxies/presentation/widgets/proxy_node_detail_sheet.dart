import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/proxy_node.dart';

class ProxyNodeDetailSheet extends StatelessWidget {
  const ProxyNodeDetailSheet({required this.node, super.key});

  final ProxyNode node;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          Text(
            node.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.itemGap),
          _DetailRow(label: 'Type', value: node.typeLabel),
          if (node.countryCode != null)
            _DetailRow(label: 'Region', value: node.countryCode!),
          if (node.latencyMs != null)
            _DetailRow(label: 'Latency', value: '${node.latencyMs} ms'),
          _DetailRow(
            label: 'Status',
            value: node.isAvailable ? 'Available' : 'Unavailable',
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          FilledButton(
            onPressed: () => Navigator.pop(context, node.id),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Select'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
