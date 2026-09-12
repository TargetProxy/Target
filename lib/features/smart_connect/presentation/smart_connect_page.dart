import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/runtime/core_notifier.dart';

class SmartConnectPage extends ConsumerStatefulWidget {
  const SmartConnectPage({super.key});
  @override
  ConsumerState<SmartConnectPage> createState() => _SmartConnectPageState();
}

class _SmartConnectPageState extends ConsumerState<SmartConnectPage> {
  Object? _pool;
  Object? _bindings;
  String? _error;
  bool _loading = false;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gateway = ref.read(coreGatewayProvider);
      final results = await Future.wait<Object?>([
        gateway.getNodePool(),
        gateway.listServiceBindings(),
      ]);
      if (mounted) {
        setState(() {
          _pool = results[0];
          _bindings = results[1];
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Smart Connect'),
      actions: [
        IconButton(
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: _error != null
          ? Center(child: Text(_error!, textAlign: TextAlign.center))
          : _pool == null
          ? Center(
              child: FilledButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.hub),
                label: Text(_loading ? 'Loading…' : 'Load node pool'),
              ),
            )
          : ListView(
              children: [
                Text(
                  'Node pool',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(_pool.toString()),
                const SizedBox(height: 24),
                Text(
                  'Service bindings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                SelectableText(_bindings.toString()),
              ],
            ),
    ),
  );
}
