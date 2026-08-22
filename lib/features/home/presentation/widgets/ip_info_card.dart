import 'package:material_ui/material_ui.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/ip_info.dart';
import 'home_info_row.dart';

class IpInfoCard extends StatelessWidget {
  const IpInfoCard({
    required this.ipInfo,
    required this.loading,
    required this.error,
    required this.onRefresh,
    super.key,
  });

  final IpInfo? ipInfo;
  final bool loading;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.public, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'IP Information',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: loading ? null : onRefresh,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.itemGap),
            _IpInfoBody(ipInfo: ipInfo, loading: loading, error: error),
          ],
        ),
      ),
    );
  }
}

class _IpInfoBody extends StatelessWidget {
  const _IpInfoBody({
    required this.ipInfo,
    required this.loading,
    required this.error,
  });

  final IpInfo? ipInfo;
  final bool loading;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final info = ipInfo;
    final theme = Theme.of(context);

    if (loading && info == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (error != null && info == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Failed to load IP info',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      );
    }

    if (info == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        HomeInfoRow(icon: Icons.language, label: 'IP', value: info.ip),
        const SizedBox(height: AppSpacing.smallGap),
        HomeInfoRow(
          icon: Icons.flag_outlined,
          label: 'Country',
          value: '${info.flagEmoji} ${info.country}',
        ),
        const SizedBox(height: AppSpacing.smallGap),
        HomeInfoRow(
          icon: Icons.location_city_outlined,
          label: 'City',
          value: info.city,
        ),
        const SizedBox(height: AppSpacing.smallGap),
        HomeInfoRow(
          icon: Icons.business_outlined,
          label: 'ISP',
          value: info.isp,
        ),
        const SizedBox(height: AppSpacing.smallGap),
        HomeInfoRow(icon: Icons.dns_outlined, label: 'AS', value: info.asName),
      ],
    );
  }
}
