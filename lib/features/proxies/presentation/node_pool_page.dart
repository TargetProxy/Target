import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../data/models/proxy_node.dart';
import '../../../l10n/app_localizations.dart';
import '../../maps/application/proxy_country_map.dart';
import '../../maps/presentation/widgets/abstract_world_map.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../application/proxies_notifier.dart';

class NodePoolPage extends ConsumerStatefulWidget {
  const NodePoolPage({super.key});

  @override
  ConsumerState<NodePoolPage> createState() => _NodePoolPageState();
}

class _NodePoolPageState extends ConsumerState<NodePoolPage> {
  final _search = TextEditingController();
  String? _source;
  String? _country;
  bool _selecting = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _selectNode(String id) async {
    if (_selecting) return;
    setState(() => _selecting = true);
    try {
      await ref.read(proxiesProvider.notifier).selectNode(id);
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Color _latencyColor(BuildContext context, ProxyNode node) {
    final scheme = Theme.of(context).colorScheme;
    if (node.latencyTimedOut) return scheme.error;
    final latency = node.latencyMs;
    if (latency == null) return scheme.onSurfaceVariant;
    if (latency <= 200) return Colors.green;
    if (latency <= 500) return Colors.orange.shade700;
    if (latency <= 1000) return Colors.deepOrange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final proxies = ref.watch(proxiesProvider);
    final subscriptions = ref.watch(subscriptionsProvider);
    final notifier = ref.read(proxiesProvider.notifier);
    final enabled = subscriptions.subscriptions.where((sub) => sub.enabled);
    final names = {
      for (final sub in subscriptions.subscriptions) sub.id: sub.name,
    };
    final source = enabled.any((sub) => sub.id == _source) ? _source : null;
    final nodes = proxies.selectedGroup?.nodes ?? const <ProxyNode>[];
    final query = _search.text.trim().toLowerCase();
    String sourceName(ProxyNode node) =>
        names[node.metadata['subscriptionId']] ?? l10n.unknownSource;
    final matching = nodes
        .where(
          (node) =>
              (source == null || node.metadata['subscriptionId'] == source) &&
              (query.isEmpty ||
                  '${node.name} ${node.type} ${proxyNodeCountryCode(node) ?? ''} ${sourceName(node)}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    final countries = proxyCountryMapEntries(matching);
    final country = countries.any((entry) => entry.countryCode == _country)
        ? _country
        : null;
    final visible = matching
        .where(
          (node) => country == null || proxyNodeCountryCode(node) == country,
        )
        .toList();
    final busy =
        _selecting ||
        subscriptions.busy ||
        subscriptions.changingIds.isNotEmpty;
    final error = proxies.lastError ?? subscriptions.lastError;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: TargetPageLayout.maxWidth + 48,
          ),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: TargetPageLayout.padding,
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TargetPageHeader(
                        title: l10n.nodeSelection,
                        subtitle: l10n.nodePoolHint,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: proxies.testing || nodes.isEmpty
                                ? null
                                : notifier.testAllLatency,
                            icon: const Icon(Icons.speed),
                            label: Text(l10n.testLatency),
                          ),
                          Text(
                            proxies.selectedGroup?.selectedNode?.name ??
                                l10n.noNodeSelected,
                          ),
                          if (_selecting || proxies.testing)
                            const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (!ref.watch(coreProvider).running) ...[
                        const SizedBox(height: 8),
                        Text(
                          l10n.selectionSavedForNextCoreStart,
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            error,
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      const SizedBox(height: 16),
                      if (nodes.isNotEmpty) ...[
                        AbstractWorldMap(
                          height: 320,
                          nodes: countries,
                          selectedId: country,
                          onSelect: (value) => setState(() => _country = value),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allRegions),
                              selected: country == null,
                              onSelected: (_) =>
                                  setState(() => _country = null),
                            ),
                            for (final entry in countries)
                              ChoiceChip(
                                key: ValueKey('region-${entry.countryCode}'),
                                label: Text(
                                  '${entry.countryCode} · ${entry.nodeCount}',
                                ),
                                selected: country == entry.countryCode,
                                onSelected: (value) => setState(
                                  () => _country = value
                                      ? entry.countryCode
                                      : null,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.searchNodes,
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.allSubscriptions),
                              selected: source == null,
                              onSelected: (_) => setState(() {
                                _source = null;
                                _country = null;
                              }),
                            ),
                            for (final sub in enabled)
                              ChoiceChip(
                                key: ValueKey('source-${sub.id}'),
                                label: Text(sub.name),
                                selected: source == sub.id,
                                onSelected: (value) => setState(() {
                                  _source = value ? sub.id : null;
                                  _country = null;
                                }),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.poolNodeCount(visible.length),
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                      if (visible.isEmpty) ...[
                        const SizedBox(height: 24),
                        Text(
                          nodes.isEmpty ? l10n.emptyPool : l10n.noMatchingNodes,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: nodes.isEmpty
                                ? () => context.go('/proxies')
                                : () => setState(() {
                                    _search.clear();
                                    _source = null;
                                    _country = null;
                                  }),
                            child: Text(
                              nodes.isEmpty
                                  ? l10n.manageSubscriptions
                                  : l10n.clearFilters,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final node = visible[index];
                    return ListTile(
                      key: ValueKey('node-${node.id}'),
                      dense: true,
                      selected: node.isSelected,
                      leading: Icon(
                        node.isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                      ),
                      title: Text(
                        node.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${sourceName(node)} · ${node.typeLabel}${node.isAvailable ? '' : ' · ${l10n.nodeUnavailable}'}',
                      ),
                      trailing: Text(
                        node.latencyTimedOut
                            ? 'timeout'
                            : (node.latencyMs == null
                                  ? '—'
                                  : '${node.latencyMs} ms'),
                        style: TextStyle(
                          color: _latencyColor(context, node),
                          fontWeight: node.latencyTimedOut
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      enabled: node.isAvailable,
                      onTap: busy || !node.isAvailable
                          ? null
                          : () => _selectNode(node.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
