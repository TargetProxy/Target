import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../core/ui/app_glyphs.dart';
import '../../../core/ui/null_status_illustration.dart';
import '../../../core/widgets/error_notice.dart';
import '../../../core/ui/scaffold/scaffold.dart' as ui;
import 'widgets/subscription_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/format_bytes.dart';
import '../../../data/models/subscription.dart';
import '../../../l10n/app_localizations.dart';
import '../../proxies/application/proxy_catalog.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../../subscriptions/presentation/widgets/add_subscription_sheet.dart';

class ProfilesWorkspacePage extends ConsumerWidget {
  const ProfilesWorkspacePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionsProvider);
    final notifier = ref.read(subscriptionsProvider.notifier);
    final l10n = AppLocalizations.of(context);
    final nodeCount = ref
        .watch(proxyCatalogProvider)
        .groups
        .expand((group) => group.nodes)
        .map((node) => node.id)
        .toSet()
        .length;
    return ui.Scaffold(
      title: l10n.profiles,
      primaryAction: IconButtonData(
        glyph: AppGlyphs.add,
        tooltip: l10n.addSubscription,
        onPressed: () => _addSubscription(context, ref),
      ),
      body: Builder(
        builder: (context) => ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            context.appBarInset,
            16,
            context.bottomInset + 24,
          ),
          children: [
            Text(
              l10n.subscriptionsHint,
              style: AppTextStyle.subheadline.of(context).toLighter,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.poolSummary(
                state.subscriptions.where((sub) => sub.enabled).length,
                nodeCount,
              ),
            ),
            const SizedBox(height: 16),
            if (state.lastError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ErrorNotice(message: state.lastError!),
              ),
            if (state.subscriptions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: NullStatus(
                  illustration: NullStatusIllustration.profile,
                  label: l10n.profiles,
                  description: l10n.noSubscriptionsHint,
                  action: FilledButton(
                    onPressed: () => _addSubscription(context, ref),
                    child: Text(l10n.addSubscription),
                  ),
                ),
              ),
            for (final subscription in state.subscriptions)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SubscriptionCard(
                  key: ValueKey('subscription-${subscription.id}'),
                  profile: subscription,
                  onToggle: () => notifier.toggleSubscription(subscription.id),
                  onUpdate: () => notifier.updateSubscription(subscription.id),
                  onDetails: () => _showDetails(context, subscription),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context, Subscription subscription) {
    final l10n = AppLocalizations.of(context);
    showFormSheet<void>(
      context: context,
      builder: (_) => ui.Scaffold(
        title: l10n.subscriptionDetails,
        body: Builder(
          builder: (context) => SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              24,
              context.appBarInset,
              24,
              context.bottomInset + 24,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _UsageProgress(subscription: subscription),
                _DetailRow(
                  label: l10n.subscriptionAddress,
                  value: subscription.safeUrl,
                  selectable: true,
                ),
                _DetailRow(
                  label: l10n.lastUpdated,
                  value: subscription.lastUpdatedAt == null
                      ? l10n.neverUpdated
                      : DateFormat.yMMMd(l10n.localeName).add_Hm().format(
                          subscription.lastUpdatedAt!.toLocal(),
                        ),
                ),
                _DetailRow(
                  label: l10n.subscriptionNodes,
                  value: '${subscription.nodeCount}',
                ),
                _DetailRow(
                  label: l10n.automaticUpdates,
                  value: subscription.autoUpdate ? l10n.enabled : l10n.disabled,
                ),
                _DetailRow(
                  label: l10n.updateInterval,
                  value: _formatInterval(
                    subscription.updateIntervalSeconds,
                    disabledLabel: l10n.disabled,
                  ),
                ),
                _DetailRow(
                  label: l10n.trafficUsed,
                  value: formatBytes(
                    subscription.uploadBytes + subscription.downloadBytes,
                  ),
                ),
                if (subscription.expiresAt != null)
                  _DetailRow(
                    label: l10n.expires,
                    value: DateFormat.yMMMd(
                      l10n.localeName,
                    ).add_Hm().format(subscription.expiresAt!.toLocal()),
                  ),
                if (subscription.profileTitle?.isNotEmpty == true)
                  _DetailRow(
                    label: l10n.profile,
                    value: subscription.profileTitle!,
                  ),
                if (subscription.webPageUrl?.isNotEmpty == true)
                  _DetailRow(
                    label: l10n.webPage,
                    value: subscription.webPageUrl!,
                    selectable: true,
                  ),
                if (subscription.supportUrl?.isNotEmpty == true)
                  _DetailRow(
                    label: l10n.support,
                    value: subscription.supportUrl!,
                    selectable: true,
                  ),
                if (subscription.lastError?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ErrorNotice(message: subscription.lastError!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addSubscription(BuildContext context, WidgetRef ref) async {
    final result = await showFormSheet<Map<String, String>>(
      context: context,
      builder: (_) => const AddSubscriptionSheet(),
    );
    if (result == null || !context.mounted) return;
    final url = result['url']?.trim();
    if (url == null || url.isEmpty) return;
    await ref
        .read(subscriptionsProvider.notifier)
        .addSubscription(url, name: result['name']);
  }

  static String _formatInterval(int seconds, {required String disabledLabel}) {
    if (seconds <= 0) return disabledLabel;
    final hours = seconds ~/ 3600;
    if (hours > 0 && seconds % 3600 == 0) {
      return '$hours h';
    }
    final minutes = seconds ~/ 60;
    if (minutes > 0 && seconds % 60 == 0) {
      return '$minutes min';
    }
    return '$seconds s';
  }
}

class _UsageProgress extends StatelessWidget {
  const _UsageProgress({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final total = subscription.totalBytes;
    if (total == null || total <= 0) return const SizedBox.shrink();

    final used = subscription.uploadBytes + subscription.downloadBytes;
    final progress = (used / total).clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context).trafficUsed),
              Text('${formatBytes(used)} / ${formatBytes(total)}'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.selectable = false,
  });

  final String label;
  final String value;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyle.footnote.of(context).toLighter;
    final valueWidget = selectable
        ? SelectionArea(
            child: Text(value, maxLines: 2, overflow: TextOverflow.ellipsis),
          )
        : Text(value, softWrap: true);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 132, child: Text(label, style: labelStyle)),
          const SizedBox(width: 12),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }
}
