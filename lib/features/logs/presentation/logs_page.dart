import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../application/logs_notifier.dart';
import 'widgets/log_line_tile.dart';
import 'widgets/log_toolbar.dart';

class LogsPage extends ConsumerStatefulWidget {
  const LogsPage({super.key});

  @override
  ConsumerState<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends ConsumerState<LogsPage> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(logsProvider);
    final notifier = ref.read(logsProvider.notifier);
    final entries = state.filteredEntries;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TargetPageLayout.maxWidth,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: TargetPageHeader(
                      title: 'Logs',
                      subtitle: 'Runtime events and diagnostics.',
                    ),
                  ),
                  IconButton(
                    onPressed: _copyVisible,
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy visible',
                  ),
                  IconButton(
                    onPressed: _export,
                    icon: const Icon(Icons.share),
                    tooltip: 'Export',
                  ),
                  IconButton(
                    onPressed: notifier.clear,
                    icon: const Icon(Icons.delete_sweep),
                    tooltip: 'Clear',
                  ),
                ],
              ),
            ),
          ),
          LogToolbar(
            paused: state.paused,
            levelFilter: state.levelFilter,
            onPauseToggle: notifier.togglePause,
            onLevelChanged: notifier.setLevelFilter,
            onSearchChanged: notifier.setSearchQuery,
          ),
          Expanded(
            child: entries.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No logs',
                    description: 'Logs will appear here in real time.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      return LogLineTile(entry: entries[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _copyVisible() {
    final text = ref.read(logsProvider.notifier).exportLogs();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logs copied to clipboard')));
  }

  void _export() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Export logs'),
        content: const Text('Sanitize sensitive data (URLs, IPs, tokens)?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _doExport(sanitize: false);
            },
            child: const Text('Raw'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _doExport(sanitize: true);
            },
            child: const Text('Sanitized'),
          ),
        ],
      ),
    );
  }

  void _doExport({required bool sanitize}) {
    final text = ref
        .read(logsProvider.notifier)
        .exportLogs(sanitize: sanitize);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sanitize
              ? 'Sanitized logs copied to clipboard'
              : 'Logs copied to clipboard',
        ),
      ),
    );
  }
}
