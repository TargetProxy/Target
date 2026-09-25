import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../data/models/proxy_node.dart';
import '../../../data/models/runtime_settings.dart';
import '../../proxies/application/proxies_notifier.dart';
import '../../subscriptions/application/subscriptions_notifier.dart';
import '../application/smart_connect_notifier.dart';
import '../application/smart_policy_notifier.dart';
import '../domain/smart_connect_models.dart';
import 'smart_policy_editor.dart';

class SmartConnectPage extends ConsumerStatefulWidget {
  const SmartConnectPage({super.key});
  @override
  ConsumerState<SmartConnectPage> createState() => SmartConnectPageState();
}

class SmartConnectPageState extends ConsumerState<SmartConnectPage> {
  String? _groupId;
  SmartPolicy? _draftPolicy;
  SmartSelectionMode? _draftMode;
  String? _draftNode;
  String _query = '';
  String? _region, _source;
  bool _dirty = false, _detailOpen = false, _applying = false;
  String? _error;

  String t(String en, String zh) =>
      Localizations.localeOf(context).languageCode == 'zh' ? zh : en;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(smartConnectProvider.notifier).refresh());
  }

  SmartPolicy? get _savedPolicy => ref
      .read(smartPoliciesProvider)
      .value
      ?.where((p) => p.id == _groupId)
      .firstOrNull;
  SmartPolicy? get _policy => _draftPolicy ?? _savedPolicy;
  String get _title => _policy == null
      ? t('Default', '默认 Default')
      : (_policy!.name.isEmpty ? _policy!.id : _policy!.name);
  SmartSelectionMode get _mode =>
      _draftMode ??
      _policy?.selectionMode ??
      (ref.read(smartConnectProvider).snapshot.defaultNodeId == 'direct'
          ? SmartSelectionMode.direct
          : SmartSelectionMode.manual);
  bool get _busy => _applying || ref.read(smartConnectProvider).busy;

  void _resetDraft() {
    _draftPolicy = null;
    _draftMode = null;
    _draftNode = null;
    _dirty = false;
    _error = null;
  }

  Future<bool> confirmLeave() async {
    if (_busy) return false;
    if (!_dirty) return true;
    final decision = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Unsaved changes to $_title', '$_title 有待应用的更改')),
        content: Text(
          t(
            'Apply this group before leaving, or discard its draft.',
            '离开前可以应用此分组，或放弃草稿。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'stay'),
            child: Text(t('Keep editing', '继续编辑')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'discard'),
            child: Text(t('Discard', '放弃')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'apply'),
            child: Text(t('Apply', '应用')),
          ),
        ],
      ),
    );
    if (!mounted) return false;
    if (decision == 'discard') {
      setState(_resetDraft);
      return true;
    }
    return decision == 'apply' ? _apply() : false;
  }

  Future<void> _selectGroup(String? id) async {
    if (id != _groupId && !await confirmLeave()) return;
    if (!mounted) return;
    setState(() {
      if (id != _groupId) _resetDraft();
      _groupId = id;
      _query = '';
      _region = null;
      _source = null;
      _detailOpen = true;
    });
  }

  Future<bool> _apply() async {
    if (_busy) return false;
    final notifier = ref.read(smartConnectProvider.notifier);
    final policy = _policy?.copyWith(selectionMode: _mode);
    final smart = ref.read(smartConnectProvider);
    final savedNode = policy == null
        ? smart.snapshot.defaultNodeId
        : smart.bindings[policy.id]?.nodeId;
    final nodeId = _mode == SmartSelectionMode.direct
        ? 'direct'
        : _draftNode ?? (savedNode == 'direct' ? null : savedNode);
    if ((policy == null ||
            (policy.enabled && _mode == SmartSelectionMode.manual)) &&
        (nodeId == null || nodeId.isEmpty)) {
      setState(() => _error = t('Choose a node first.', '请先选择节点。'));
      return false;
    }
    if (policy?.enabled == true &&
        policy?.selectionMode == SmartSelectionMode.automatic &&
        (smart.assessments[policy!.id]?.selection.node == null ||
            jsonEncode(smart.assessments[policy.id]?.policy.toJson()) !=
                jsonEncode(policy.toJson()))) {
      setState(
        () => _error = t('Get a usable recommendation first.', '请先获取可用的推荐节点。'),
      );
      return false;
    }
    setState(() {
      _applying = true;
      _error = null;
    });
    try {
      if (policy == null) {
        await notifier.selectDefault(nodeId!);
      } else {
        await notifier.applyRoute(policy, nodeId: nodeId);
      }
      if (!mounted) return false;
      final error = ref.read(smartConnectProvider).error;
      if (error != null) {
        setState(() => _error = error);
        return false;
      }
      setState(_resetDraft);
      return true;
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
      return false;
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _edit({bool create = false}) async {
    if (create && !await confirmLeave()) return;
    if (!mounted) return;
    final result = await showDialog<SmartPolicy>(
      context: context,
      builder: (_) => SmartPolicyEditor(policy: create ? null : _policy),
    );
    if (result == null || !mounted) return;
    if (!create) {
      setState(() {
        _draftPolicy = result;
        _dirty = true;
      });
      return;
    }
    try {
      await ref.read(smartPoliciesProvider.notifier).savePolicy(result);
      if (!mounted) return;
      setState(() {
        _resetDraft();
        _groupId = result.id;
        _detailOpen = true;
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _delete() async {
    final policy = _savedPolicy;
    if (policy == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Delete $_title?', '删除 $_title？')),
        content: Text(
          t(
            'Its service override will be removed. Traffic returns to the base routing rules.',
            '这会移除此分组的独立选路，相关流量将回到基础路由规则。',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Cancel', '取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(t('Delete group', '删除分组')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(smartConnectProvider.notifier).removePolicy(policy.id);
    if (!mounted || ref.read(smartConnectProvider).error != null) return;
    setState(() {
      _resetDraft();
      _groupId = null;
      _detailOpen = false;
    });
  }

  String _modeName(SmartSelectionMode mode) => switch (mode) {
    SmartSelectionMode.followDefault => t('Follow Default', '跟随默认'),
    SmartSelectionMode.manual => t('Manual node', '手动选择'),
    SmartSelectionMode.automatic => t('Recommend node', '推荐节点'),
    SmartSelectionMode.direct => t('Direct', '直连'),
  };

  String _nodeName(String? id) {
    if (id == 'direct') return t('Direct · local network', '直连 · 本机网络');
    if (id == null || id.isEmpty) return t('Not selected', '尚未选择');
    return ref
            .read(smartConnectProvider)
            .snapshot
            .nodes
            .where((n) => n.id == id)
            .firstOrNull
            ?.displayName ??
        '$id · ${t('unavailable', '不可用')}';
  }

  String _routeSummary(SmartPolicy? policy) {
    final smart = ref.read(smartConnectProvider);
    final snapshot = smart.snapshot;
    if (!snapshot.loaded) return t('Runtime not loaded', '尚未读取运行状态');
    final binding = policy == null ? null : snapshot.bindings[policy.id];
    if (binding != null) {
      return '${_nodeName(binding.nodeId)} · ${binding.effective ? t('Effective', '已生效') : t('Not effective', '未生效')}';
    }
    final defaultLabel = _nodeName(snapshot.defaultNodeId);
    if (policy == null) return defaultLabel;
    return '${t('Follow Default', '跟随默认')} → $defaultLabel';
  }

  @override
  Widget build(BuildContext context) {
    final smart = ref.watch(smartConnectProvider);
    final policies = ref.watch(smartPoliciesProvider);
    ref.watch(proxiesProvider);
    ref.watch(subscriptionsProvider);
    final core = ref.watch(coreProvider);
    final theme = Theme.of(context);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 850;
          return Padding(
            padding: EdgeInsets.all(wide ? 24 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('Proxy groups', '代理分组'),
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              'Choose a group, then choose its route.',
                              '先选分组，再决定这组流量怎么走。',
                            ),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: t('Refresh runtime', '刷新运行状态'),
                      onPressed: _busy
                          ? null
                          : () => ref
                                .read(smartConnectProvider.notifier)
                                .refresh(),
                      icon: const Icon(Icons.refresh),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'nodes' &&
                            await confirmLeave() &&
                            context.mounted) {
                          context.go('/node-library');
                        }
                        if (value == 'export') {
                          await Clipboard.setData(
                            ClipboardData(
                              text: const JsonEncoder.withIndent('  ').convert(
                                (policies.value ?? [])
                                    .map((p) => p.toJson())
                                    .toList(),
                              ),
                            ),
                          );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  t('Group configuration copied', '分组配置已复制'),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'nodes',
                          child: Text(t('Node library & map', '节点库与地图')),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Text(t('Copy group configuration', '复制分组配置')),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: Icon(
                        smart.snapshot.running
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        size: 18,
                      ),
                      label: Text(
                        !smart.snapshot.loaded
                            ? t('Status unknown', '状态未知')
                            : smart.snapshot.running
                            ? t('Connected', '已连接')
                            : t('Disconnected', '未连接'),
                      ),
                    ),
                    SizedBox(
                      width: constraints.maxWidth < 400
                          ? constraints.maxWidth - 32
                          : 340,
                      child: DropdownButton<RouteMode>(
                        isExpanded: true,
                        value: core.settings.routeMode,
                        items: [
                          DropdownMenuItem(
                            value: RouteMode.rule,
                            child: Text(
                              t('Group rules + local bypass', '分组规则 · 国内直连'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: RouteMode.all,
                            child: Text(
                              t(
                                'Group rules · no local bypass',
                                '分组规则 · 不启用国内直连',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          DropdownMenuItem(
                            value: RouteMode.direct,
                            child: Text(t('All direct', '全部直连')),
                          ),
                        ],
                        onChanged: core.busy || _busy
                            ? null
                            : (value) {
                                if (value != null) {
                                  ref
                                      .read(coreProvider.notifier)
                                      .updateRuntimeConfig(
                                        core.settings.copyWith(
                                          routeMode: value,
                                        ),
                                      );
                                }
                              },
                      ),
                    ),
                  ],
                ),
                if (core.settings.routeMode == RouteMode.direct)
                  _notice(
                    t(
                      'All traffic uses the local network. Group settings are retained but bypassed.',
                      '当前全部直连；分组配置已保留，暂不参与选路。',
                    ),
                  ),
                if (_error != null || smart.error != null)
                  _notice(_error ?? smart.error!, error: true),
                if (policies.hasError)
                  _notice(
                    '${t('Could not load groups', '无法加载分组')}: ${policies.error}',
                    error: true,
                  ),
                if (policies.isLoading || _busy)
                  const LinearProgressIndicator(),
                const SizedBox(height: 12),
                Expanded(
                  child: wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(
                              width: 250,
                              child: _groups(policies.value ?? []),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: _detail(false)),
                          ],
                        )
                      : _detailOpen
                      ? _detail(true)
                      : _groups(policies.value ?? []),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _notice(String text, {bool error = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Text(
      text,
      style: TextStyle(
        color: error ? Theme.of(context).colorScheme.error : null,
      ),
    ),
  );

  Widget _groups(List<SmartPolicy> policies) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t('Traffic groups', '流量分组'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text('${policies.length + 1}'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            children: [
              _groupTile(null),
              for (final policy in policies) _groupTile(policy),
            ],
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(t('Add group', '添加分组')),
          onTap: _busy ? null : () => _edit(create: true),
        ),
      ],
    ),
  );

  Widget _groupTile(SmartPolicy? policy) => ListTile(
    key: ValueKey('group-${policy?.id ?? 'default'}'),
    selected: _groupId == policy?.id,
    selectedTileColor: Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: .45),
    leading: Icon(policy == null ? Icons.public : Icons.alt_route),
    title: Text(
      policy == null
          ? t('Default', '默认 Default')
          : policy.name.isEmpty
          ? policy.id
          : policy.name,
    ),
    subtitle: Text(
      _routeSummary(policy),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    ),
    onTap: _busy ? null : () => _selectGroup(policy?.id),
  );

  Widget _detail(bool mobile) {
    final smart = ref.read(smartConnectProvider);
    final policy = _policy;
    final binding = smart.bindings[_groupId];
    final theme = Theme.of(context);
    final snapshot = smart.snapshot;
    final actual = policy == null
        ? snapshot.actualDefaultNodeId
        : binding?.effective == true
        ? binding?.nodeId
        : null;
    final follows = policy != null && binding == null && snapshot.loaded;
    final mode = _mode;
    final savedNode = policy == null ? snapshot.defaultNodeId : binding?.nodeId;
    final selectedNode =
        _draftNode ?? (savedNode == 'direct' ? null : savedNode);
    final assessment = policy == null ? null : smart.assessments[policy.id];
    final recommendationCurrent =
        assessment != null &&
        jsonEncode(assessment.policy.toJson()) ==
            jsonEncode(
              policy!
                  .copyWith(selectionMode: SmartSelectionMode.automatic)
                  .toJson(),
            );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (mobile)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                if (await confirmLeave() && mounted) {
                  setState(() => _detailOpen = false);
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text(t('All groups', '全部分组')),
            ),
          ),
        Expanded(
          child: ListView(
            key: ValueKey('detail-${_groupId ?? 'default'}'),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(_title, style: theme.textTheme.headlineSmall),
                  ),
                  if (policy != null) ...[
                    IconButton(
                      tooltip: t(
                        'Edit matching rules & constraints',
                        '编辑规则与候选约束',
                      ),
                      onPressed: _busy ? null : _edit,
                      icon: const Icon(Icons.tune),
                    ),
                    IconButton(
                      tooltip: t('Delete group', '删除分组'),
                      onPressed: _busy ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                policy == null
                    ? t(
                        'Fallback for traffic not matched by service or built-in rules.',
                        '用于未命中服务分组及内置规则的流量。',
                      )
                    : '${t('Matches domains and subdomains', '匹配域名及其子域名')}: ${policy.domains.join(', ')}',
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('CURRENT ROUTE', '当前出口'),
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _routeSummary(_savedPolicy),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      !snapshot.loaded
                          ? t(
                              'Refresh to read the runtime state.',
                              '请刷新以读取运行状态。',
                            )
                          : !snapshot.running
                          ? t(
                              'Configuration saved; active after connecting.',
                              '配置已保存，连接后生效。',
                            )
                          : ref.read(coreProvider).settings.routeMode ==
                                RouteMode.direct
                          ? t('Bypassed by All direct mode.', '当前被全部直连模式覆盖。')
                          : follows
                          ? t(
                              'Uses base routing rules and the current Default. No independent override.',
                              '沿用基础路由规则与当前默认出口，未设置独立出口。',
                            )
                          : actual != null && actual.isNotEmpty
                          ? '${t('Runtime reports', '运行时报告')}: ${_nodeName(actual)}'
                          : t(
                              'Not confirmed effective. The saved choice is not an active-route guarantee.',
                              '尚未确认生效；已保存的选择不等于实际出口。',
                            ),
                    ),
                    if (binding?.needsEvaluation == true)
                      Text(t('Service check needs refreshing.', '服务检测结果需要刷新。')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (policy?.enabled == false)
                _notice(
                  t(
                    'This group is disabled. Applying removes its independent route.',
                    '此分组已停用；应用后会移除其独立出口。',
                  ),
                ),
              Text(
                t('How this group connects', '这个分组怎么走'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final option in [
                    if (policy != null) SmartSelectionMode.followDefault,
                    SmartSelectionMode.manual,
                    if (policy != null) SmartSelectionMode.automatic,
                    SmartSelectionMode.direct,
                  ])
                    ChoiceChip(
                      key: ValueKey('mode-${option.name}'),
                      label: Text(_modeName(option)),
                      selected: mode == option,
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                              _draftMode = option;
                              _dirty = true;
                              _error = null;
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (mode == SmartSelectionMode.followDefault)
                _notice(
                  '${t('Follows Default automatically', '随默认出口一起变化')} → ${_nodeName(snapshot.defaultNodeId)}',
                ),
              if (mode == SmartSelectionMode.direct)
                _notice(
                  t(
                    'This group uses the local network. No proxy node or test is required.',
                    '此分组使用本机网络，不需要代理节点或测速。',
                  ),
                ),
              if (mode == SmartSelectionMode.manual)
                _nodeList(policy, selectedNode),
              if (mode == SmartSelectionMode.automatic && policy != null) ...[
                _notice(
                  t(
                    'Evaluate candidates for this service, then apply a recommendation. The selected node stays fixed until you apply another choice.',
                    '检测此服务的候选节点，再应用推荐结果。应用后保持该节点，直到你再次更改。',
                  ),
                ),
                Text(
                  '${t('Allowed regions', '允许地区')}: ${policy.allowedRegions.isEmpty ? t('Any', '不限') : policy.allowedRegions.join(', ')} · ${t('Preferred', '偏好')}: ${policy.preferredRegions.isEmpty ? t('None', '无') : policy.preferredRegions.join(', ')}',
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _busy
                        ? null
                        : () async {
                            await ref
                                .read(smartConnectProvider.notifier)
                                .evaluate(
                                  policy.copyWith(
                                    selectionMode: SmartSelectionMode.automatic,
                                  ),
                                );
                            if (mounted) setState(() => _dirty = true);
                          },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(t('Get recommendation', '获取推荐')),
                  ),
                ),
                if (recommendationCurrent) ...[
                  _notice(
                    assessment.selection.node == null
                        ? t(
                            'No eligible node. Adjust this group’s constraints and try again.',
                            '没有符合条件的节点，请调整此分组的候选约束后重试。',
                          )
                        : '${t('Recommended', '推荐')}: ${assessment.selection.node!.displayName}\n${assessment.selection.reason}',
                  ),
                  Text(
                    t('Recommendation only · not yet applied', '仅为推荐结果 · 尚未应用'),
                  ),
                  if (assessment.selection.excluded.isNotEmpty)
                    ExpansionTile(
                      title: Text(t('Excluded candidates', '被排除的候选节点')),
                      children: [
                        for (final entry
                            in assessment.selection.excluded.entries)
                          ListTile(
                            title: Text(_nodeName(entry.key)),
                            subtitle: Text(entry.value),
                          ),
                      ],
                    ),
                ],
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _dirty
                    ? '${t('Pending', '待应用')}: $_title → ${mode == SmartSelectionMode.manual ? _nodeName(selectedNode) : _modeName(mode)}'
                    : t(
                        'Choose a mode or node to prepare a change.',
                        '选择方式或节点后，再应用到当前分组。',
                      ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  TextButton(
                    onPressed: !_dirty || _busy
                        ? null
                        : () => setState(_resetDraft),
                    child: Text(t('Cancel', '取消')),
                  ),
                  FilledButton(
                    key: const ValueKey('apply-group'),
                    onPressed:
                        !_dirty ||
                            _busy ||
                            (policy?.enabled != false &&
                                mode == SmartSelectionMode.manual &&
                                selectedNode == null) ||
                            (policy?.enabled != false &&
                                mode == SmartSelectionMode.automatic &&
                                (!recommendationCurrent ||
                                    assessment.selection.node == null))
                        ? null
                        : _apply,
                    child: Text(
                      _busy
                          ? t('Working…', '处理中…')
                          : t('Apply to $_title', '应用到 $_title'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nodeList(SmartPolicy? policy, String? selectedNode) {
    final smart = ref.read(smartConnectProvider);
    final latency = {
      for (final group in ref.read(proxiesProvider).groups)
        for (final node in group.nodes) node.id: node,
    };
    final sources = {
      for (final s in ref.read(subscriptionsProvider).subscriptions)
        s.id: s.name,
    };
    final nodes = smart.snapshot.nodes;
    final regions =
        nodes
            .map((n) => n.effectiveRegion)
            .where((r) => r.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final sourceIds = nodes.map((n) => n.subscriptionId).toSet().toList();
    final visible = nodes
        .where(
          (node) =>
              (_region == null || node.effectiveRegion == _region) &&
              (_source == null || node.subscriptionId == _source) &&
              '${node.displayName} ${node.type} ${sources[node.subscriptionId] ?? ''}'
                  .toLowerCase()
                  .contains(_query.toLowerCase()),
        )
        .toList();
    String? excluded(ProxyNode node) {
      if (!node.isAvailable) return t('Unavailable', '不可用');
      if (policy == null) return null;
      if (!node.enabled ||
          node.excluded ||
          policy.excludedNodes.contains(node.id)) {
        return t('Excluded from this group', '已从候选范围排除');
      }
      if (policy.allowedRegions.isNotEmpty &&
          !policy.allowedRegions.contains(node.effectiveRegion)) {
        return t('Outside allowed regions', '不在允许地区内');
      }
      if (policy.allowedSubscriptions.isNotEmpty &&
          !policy.allowedSubscriptions.contains(node.subscriptionId)) {
        return t('Outside allowed subscriptions', '不在允许订阅内');
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: ValueKey('search-${_groupId ?? 'default'}'),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: t('Search nodes or subscriptions', '搜索节点或订阅'),
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<String>(
              value: regions.contains(_region) ? _region : null,
              hint: Text(t('All regions', '全部地区')),
              items: [
                DropdownMenuItem(
                  value: null,
                  child: Text(t('All regions', '全部地区')),
                ),
                for (final region in regions)
                  DropdownMenuItem(value: region, child: Text(region)),
              ],
              onChanged: (value) => setState(() => _region = value),
            ),
            SizedBox(
              width: 180,
              child: DropdownButton<String>(
                isExpanded: true,
                value: sourceIds.contains(_source) ? _source : null,
                hint: Text(t('All subscriptions', '全部订阅')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(t('All subscriptions', '全部订阅')),
                  ),
                  for (final id in sourceIds)
                    DropdownMenuItem(
                      value: id,
                      child: Text(
                        sources[id] ?? id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) => setState(() => _source = value),
              ),
            ),
            TextButton.icon(
              onPressed: ref.read(proxiesProvider).testing || _busy
                  ? null
                  : () => ref.read(proxiesProvider.notifier).testAllLatency(),
              icon: const Icon(Icons.speed),
              label: Text(t('Test latency', '测速')),
            ),
          ],
        ),
        Text(
          t(
            'Filters only change this list. Group constraints are edited with the settings button.',
            '筛选只影响列表展示；分组的候选约束在右上角设置中编辑。',
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        if (selectedNode != null &&
            selectedNode != 'direct' &&
            !nodes.any((n) => n.id == selectedNode))
          _notice(
            '${t('Selected node is no longer available', '所选节点已不可用')}: $selectedNode',
            error: true,
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              nodes.isEmpty
                  ? t('No nodes. Enable a subscription first.', '暂无节点，请先启用订阅。')
                  : t(
                      'No matching nodes. Clear the search or filters.',
                      '没有匹配节点，请清除搜索或筛选。',
                    ),
            ),
          ),
        for (final node in visible)
          ListTile(
            key: ValueKey('candidate-${node.id}'),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            selected: selectedNode == node.id,
            enabled: excluded(node) == null,
            leading: Icon(
              selectedNode == node.id
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(node.displayName),
            subtitle: Text(
              '${sources[node.subscriptionId] ?? node.subscriptionId} · ${node.effectiveRegion}\n${excluded(node) ?? t('Service availability unverified', '服务可用性未验证')}',
            ),
            trailing: Text(
              latency[node.id]?.latencyTimedOut == true
                  ? t('Timeout', '超时')
                  : latency[node.id]?.latencyMs != null
                  ? '${latency[node.id]!.latencyMs} ms'
                  : '—',
            ),
            onTap: _busy || excluded(node) != null
                ? null
                : () => setState(() {
                    _draftNode = node.id;
                    _dirty = true;
                    _error = null;
                  }),
          ),
      ],
    );
  }
}
