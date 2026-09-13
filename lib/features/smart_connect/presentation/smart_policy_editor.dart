import 'package:flutter/material.dart';
import '../domain/smart_connect_models.dart';

class SmartPolicyEditor extends StatefulWidget {
  const SmartPolicyEditor({super.key, this.policy});
  final SmartPolicy? policy;
  @override
  State<SmartPolicyEditor> createState() => _SmartPolicyEditorState();
}

class _SmartPolicyEditorState extends State<SmartPolicyEditor> {
  final _fields = <String, TextEditingController>{};
  late SmartSelectionMode _mode;
  late bool _enabled;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.policy ?? const SmartPolicy(id: '');
    _mode = p.selectionMode;
    _enabled = p.enabled;
    final values = {
      'id': p.id,
      'name': p.name,
      'domains': p.domains.join(', '),
      'regions': p.allowedRegions.join(', '),
      'preferred': p.preferredRegions.join(', '),
      'subscriptions': p.allowedSubscriptions.join(', '),
      'excluded': p.excludedNodes.join(', '),
      'tags': p.requiredTags.join(', '),
      'sticky': '${p.stickyDuration.inMinutes}',
      'validity': '${p.probeValidity.inSeconds}',
      'urls': p.probeTargets.map((t) => t.url).join('\n'),
      'egress': p.probeTargets.firstOrNull?.egressUrl ?? '',
      'status': (p.probeTargets.firstOrNull?.expectedStatus ?? {200}).join(
        ', ',
      ),
      'content': p.probeTargets.firstOrNull?.bodyContains ?? '',
      'countryHeader': p.probeTargets.firstOrNull?.serviceCountryHeader ?? '',
    };
    for (final entry in values.entries) {
      _fields[entry.key] = TextEditingController(text: entry.value);
    }
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  String value(String key) => _fields[key]!.text.trim();
  Set<String> values(String key) =>
      value(key).split(RegExp(r'[,\s]+')).where((v) => v.isNotEmpty).toSet();
  Widget field(String key, String label, {int lines = 1}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _fields[key],
      minLines: lines,
      maxLines: lines == 1 ? 1 : 6,
      readOnly: key == 'id' && widget.policy != null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  void save() {
    try {
      final statuses = values('status').map(int.parse).toSet();
      final targets = [
        for (final url in value(
          'urls',
        ).split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty))
          // Preserve per-target advanced values when editing existing URLs.
          widget.policy?.probeTargets.where((t) => t.url == url).firstOrNull !=
                      null &&
                  value('egress') ==
                      (widget.policy?.probeTargets.firstOrNull?.egressUrl ??
                          '') &&
                  value('content') ==
                      (widget.policy?.probeTargets.firstOrNull?.bodyContains ??
                          '') &&
                  value('status') ==
                      (widget
                                  .policy
                                  ?.probeTargets
                                  .firstOrNull
                                  ?.expectedStatus ??
                              {200})
                          .join(', ') &&
                  value('countryHeader') ==
                      (widget
                              .policy
                              ?.probeTargets
                              .firstOrNull
                              ?.serviceCountryHeader ??
                          '')
              ? widget.policy!.probeTargets.firstWhere((t) => t.url == url)
              : SmartProbeTarget(
                  url: url,
                  expectedStatus: statuses,
                  egressUrl: value('egress'),
                  bodyContains: value('content'),
                  serviceCountryHeader: value('countryHeader'),
                ),
      ];
      final p = SmartPolicy(
        id: value('id'),
        name: value('name'),
        domains: values('domains').map((d) => d.toLowerCase()).toSet(),
        allowedRegions: values('regions').map((r) => r.toUpperCase()).toSet(),
        preferredRegions: values(
          'preferred',
        ).map((r) => r.toUpperCase()).toSet(),
        allowedSubscriptions: values('subscriptions'),
        excludedNodes: values('excluded'),
        requiredTags: values('tags'),
        probeTargets: targets,
        selectionMode: _mode,
        enabled: _enabled,
        stickyDuration: Duration(minutes: int.parse(value('sticky'))),
        probeValidity: Duration(seconds: int.parse(value('validity'))),
      );
      final errors = p.validate();
      if (errors.isNotEmpty) throw FormatException(errors.join('\n'));
      Navigator.of(context).pop(p);
    } on Object catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.policy == null ? 'Add service policy' : 'Edit service policy',
    ),
    content: SizedBox(
      width: 620,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            field('id', 'Stable service ID'),
            field('name', 'Service name'),
            field('domains', 'Domain suffixes (comma separated)'),
            DropdownButtonFormField<SmartSelectionMode>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Selection mode'),
              items: [
                for (final mode in SmartSelectionMode.values)
                  DropdownMenuItem(value: mode, child: Text(mode.name)),
              ],
              onChanged: (mode) => setState(() => _mode = mode!),
            ),
            SwitchListTile(
              title: const Text('Allow evaluation for this policy'),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            field('regions', 'Allowed regions, e.g. SG, JP, US (empty = any)'),
            field('preferred', 'Preferred regions'),
            field('subscriptions', 'Allowed subscription IDs (empty = all)'),
            field('excluded', 'Excluded node IDs'),
            field('tags', 'Required node tags'),
            field('sticky', 'Binding duration (minutes)'),
            field('validity', 'Probe validity (seconds)'),
            if (_mode != SmartSelectionMode.direct) ...[
              field(
                'urls',
                'Service probe URLs (one per line, all must pass)',
                lines: 3,
              ),
              field('status', 'Expected HTTP status codes'),
              field('content', 'Required response text (optional)'),
              field(
                'egress',
                'Exit region JSON URL (optional, returns ip and country)',
              ),
              field(
                'countryHeader',
                'Service country response header (optional)',
              ),
              const Text(
                'An HTTP response alone does not prove regional unlock. Configure response content or a service country header when required.',
              ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: save, child: const Text('Save policy')),
    ],
  );
}
