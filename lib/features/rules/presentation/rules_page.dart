import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:targetlib/targetlib.dart' as pb;

import '../../../core/runtime/core_notifier.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../core/widgets/animated_reveal.dart';
import '../../../data/models/runtime_settings.dart' as runtime_models;
import '../../../data/models/proxy_node.dart';
import '../../../features/maps/application/proxy_country_map.dart';
import '../../../features/maps/presentation/widgets/abstract_world_map.dart';
import '../../../features/proxies/application/proxies_notifier.dart';
import '../../../l10n/app_localizations.dart';

class RulesPage extends ConsumerStatefulWidget {
  const RulesPage({super.key});

  @override
  ConsumerState<RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<RulesPage> {
  final _service = TextEditingController();
  final _name = TextEditingController();
  final _domains = TextEditingController();
  String? _selectedNode;
  String? _country;
  List<pb.RouteInfo> _routes = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _service.dispose();
    _name.dispose();
    _domains.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final routes = await ref.read(coreGatewayProvider).listRoutes();
      if (!mounted) return;
      setState(() {
        _routes = routes.routes;
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _saveRule() async {
    final service = _service.text.trim().toLowerCase();
    final domains = _domains.text
        .split(RegExp(r'[,\s]+'))
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.isNotEmpty)
        .toSet();
    if (service.isEmpty || domains.isEmpty || _selectedNode == null) {
      setState(() => _error = '填写服务 ID、域名并拖入一个节点。');
      return;
    }
    try {
      final core = ref.read(coreGatewayProvider);
      final settings = await core.getRuntimeConfig();
      if (settings.routeMode != runtime_models.RouteMode.rule) {
        await core.updateRuntimeConfig(
          settings.copyWith(routeMode: runtime_models.RouteMode.rule),
        );
      }
      await core.upsertRoute(
        pb.UpsertRouteRequest(
          serviceId: service,
          displayName: _name.text.trim().isEmpty ? service : _name.text.trim(),
          domains: domains,
          nodeId: _selectedNode!,
          enabled: true,
        ),
      );
      _service.clear();
      _name.clear();
      _domains.clear();
      setState(() {
        _selectedNode = null;
      });
      await _load();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _deleteRule(String id) async {
    try {
      await ref.read(coreGatewayProvider).deleteRoute(id);
      await _load();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _toggleRule(pb.RouteInfo route, bool enabled) async {
    try {
      await ref
          .read(coreGatewayProvider)
          .upsertRoute(
            pb.UpsertRouteRequest(
              serviceId: route.serviceId,
              displayName: route.displayName,
              domains: route.domains,
              nodeId: route.currentNodeId,
              enabled: enabled,
            ),
          );
      await _load();
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final proxies = ref.watch(proxiesProvider);
    final nodes = proxies.groups.expand((group) => group.nodes).toList();
    final countries = proxyCountryMapEntries(nodes);
    final visible = _country == null
        ? nodes
        : nodes
              .where((node) => proxyNodeCountryCode(node) == _country)
              .toList();
    final selected = proxies.selectedGroup?.selectedNode;

    return SafeArea(
      child: TargetPageLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TargetPageHeader(title: l10n.rules),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/nodes'),
                icon: const Icon(Icons.alt_route),
                label: Text(l10n.selectDefaultNode),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            AnimatedReveal(
              delay: const Duration(milliseconds: 40),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.public),
                        title: Text(l10n.defaultNode),
                        subtitle: Text(
                          selected?.displayName ?? l10n.nodeNotSelected,
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final node in visible.take(12))
                            ChoiceChip(
                              label: Text(node.displayName),
                              selected: node.id == selected?.id,
                              onSelected: (_) => ref
                                  .read(proxiesProvider.notifier)
                                  .selectNode(node.id),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (nodes.isNotEmpty) ...[
              AbstractWorldMap(
                height: 280,
                nodes: countries,
                selectedId: _country,
                onSelect: (value) => setState(() => _country = value),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.allRegions),
                    selected: _country == null,
                    onSelected: (_) => setState(() => _country = null),
                  ),
                  for (final entry in countries)
                    ChoiceChip(
                      label: Text('${entry.countryCode} · ${entry.nodeCount}'),
                      selected: _country == entry.countryCode,
                      onSelected: (_) =>
                          setState(() => _country = entry.countryCode),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            AnimatedReveal(
              delay: const Duration(milliseconds: 80),
              child: _ruleEditor(context, visible),
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            for (var index = 0; index < _routes.length; index++)
              AnimatedReveal(
                key: ValueKey(_routes[index].serviceId),
                delay: Duration(
                  milliseconds: 120 + index.clamp(0, 8).toInt() * 24,
                ),
                child: _routeTile(_routes[index], nodes, l10n),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ruleEditor(BuildContext context, List<ProxyNode> nodes) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.createDomainRule,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _service,
                    decoration: InputDecoration(labelText: l10n.serviceId),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _name,
                    decoration: InputDecoration(labelText: l10n.displayName),
                  ),
                ),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _domains,
                    decoration: InputDecoration(labelText: l10n.domainsHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.dropNodeHint),
            const SizedBox(height: 8),
            DragTarget<ProxyNode>(
              onAcceptWithDetails: (details) =>
                  setState(() => _selectedNode = details.data.id),
              builder: (context, candidates, _) => Container(
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: candidates.isNotEmpty
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _selectedNode == null
                      ? l10n.dropNode
                      : l10n.selectedNode(_selectedNode!),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: nodes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final node = nodes[index];
                  return Draggable<ProxyNode>(
                    data: node,
                    feedback: Material(
                      child: Chip(label: Text(node.displayName)),
                    ),
                    child: Chip(
                      avatar: const Icon(Icons.drag_indicator, size: 16),
                      label: Text(node.displayName),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saveRule,
                icon: const Icon(Icons.add),
                label: Text(l10n.saveRule),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeTile(
    pb.RouteInfo route,
    List<ProxyNode> nodes,
    AppLocalizations l10n,
  ) {
    final node = nodes
        .where((item) => item.id == route.currentNodeId)
        .firstOrNull;
    return DragTarget<ProxyNode>(
      onAcceptWithDetails: (details) async {
        try {
          await ref
              .read(coreGatewayProvider)
              .selectRouteNode(route.serviceId, details.data.id);
          await _load();
        } on Object catch (error) {
          if (mounted) setState(() => _error = error.toString());
        }
      },
      builder: (context, candidates, _) => Card(
        color: candidates.isNotEmpty
            ? Theme.of(context).colorScheme.secondaryContainer
            : null,
        child: ListTile(
          leading: Icon(
            route.enabled ? Icons.alt_route : Icons.pause_circle_outline,
          ),
          title: Text(
            route.displayName.isEmpty ? route.serviceId : route.displayName,
          ),
          subtitle: Text(
            '${route.domains.join(', ')}\n${l10n.routeExit(node?.displayName ?? route.currentNodeName)}',
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: route.enabled,
                onChanged: (value) => _toggleRule(route, value),
              ),
              IconButton(
                tooltip: l10n.deleteRule,
                onPressed: () => _deleteRule(route.serviceId),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
