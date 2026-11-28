import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart' as prism;

import 'widgets/proxy_card.dart';

import '../../../core/ui/app_glyphs.dart';
import '../../../core/ui/null_status_illustration.dart';
import '../../../core/widgets/error_notice.dart';
import '../../../core/ui/scaffold/scaffold.dart' as ui;
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
  static const _gridGap = 12.0;

  final _search = TextEditingController();
  String? _source;
  String? _country;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _latencyColor(BuildContext context, ProxyNode node) {
    final scheme = prism.Theme.of(context).colorScheme;
    if (node.latencyTimedOut || node.latencyFailed) return scheme.error;
    final latency = node.latencyMs;
    if (latency == null) return scheme.onSurfaceVariant;
    if (latency <= 200) return const Color(0xFF34C759);
    if (latency <= 500) return const Color(0xFFFF9500);
    if (latency <= 1000) return const Color(0xFFFF6B00);
    return const Color(0xFFFF3B30);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        names[node.subscriptionId] ?? l10n.unknownSource;
    final matching = nodes
        .where(
          (node) =>
              (source == null || node.subscriptionId == source) &&
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
    final error = proxies.lastError ?? subscriptions.lastError;

    return ui.Scaffold(
      title: l10n.nodeLibrary,
      primaryAction: proxies.testing
          ? prism.IconButtonData(
              glyph: AppGlyphs.close,
              tooltip: l10n.cancel,
              onPressed: notifier.cancelLatencyTest,
            )
          : prism.IconButtonData(
              glyph: AppGlyphs.bolt,
              tooltip: l10n.testAllLatency,
              onPressed: nodes.any((node) => node.isAvailable)
                  ? notifier.testAllLatency
                  : null,
            ),
      body: Builder(
        builder: (context) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                prism.BuildContextExtension(context).appBarInset,
                16,
                16,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ErrorNotice(message: error),
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
                          prism.Chip(
                            label: l10n.allRegions,
                            selected: country == null,
                            onPressed: () => setState(() => _country = null),
                          ),
                          for (final entry in countries)
                            prism.Chip(
                              key: ValueKey('region-${entry.countryCode}'),
                              label:
                                  '${entry.countryCode} · ${entry.nodeCount}',
                              selected: country == entry.countryCode,
                              onPressed: () => setState(
                                () => _country = country == entry.countryCode
                                    ? null
                                    : entry.countryCode,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      prism.SearchField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        hintText: l10n.searchNodes,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          prism.Chip(
                            label: l10n.allSubscriptions,
                            selected: source == null,
                            onPressed: () => setState(() {
                              _source = null;
                              _country = null;
                            }),
                          ),
                          for (final sub in enabled)
                            prism.Chip(
                              key: ValueKey('source-${sub.id}'),
                              label: sub.name,
                              selected: source == sub.id,
                              onPressed: () => setState(() {
                                _source = source == sub.id ? null : sub.id;
                                _country = null;
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.poolNodeCount(visible.length),
                        style: prism.AppTextStyle.headline.of(context),
                      ),
                    ],
                    if (visible.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: prism.NullStatus(
                          illustration: nodes.isEmpty
                              ? NullStatusIllustration.proxies
                              : prism.Illustration.search,
                          label: nodes.isEmpty
                              ? l10n.emptyPool
                              : l10n.noMatchingNodes,
                          action: prism.FilledButton(
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
                      ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                24 + prism.BuildContextExtension(context).bottomInset,
              ),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) => SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        ((constraints.crossAxisExtent + _gridGap) /
                                (240.ap(context) + _gridGap))
                            .floor()
                            .clamp(1, 4),
                    mainAxisExtent: ProxyCard.extentOf(context),
                    mainAxisSpacing: _gridGap,
                    crossAxisSpacing: _gridGap,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final node = visible[index];
                    return ProxyCard(
                      key: ValueKey('node-${node.id}'),
                      proxy: node,
                      source: sourceName(node),
                      selected:
                          proxies.selectedGroup?.selectedNodeId == node.id,
                      testing: proxies.testingNodeIds.contains(node.id),
                      latencyColor: _latencyColor(context, node),
                      onTestLatency: proxies.testing || !node.isAvailable
                          ? null
                          : () => notifier.testNodeLatency(node),
                      onSelected: () => notifier.selectNode(node.id),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
