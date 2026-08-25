import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talker/talker.dart';

import '../../../core/logging/app_logger.dart';
import '../../../core/runtime/core_notifier.dart';

/// Immutable snapshot of the logs workspace.
@immutable
class LogsState {
  const LogsState({
    this.entries = const [],
    this.levelFilter,
    this.searchQuery = '',
    this.paused = false,
  });

  final List<TalkerData> entries;
  final LogLevel? levelFilter;
  final String searchQuery;
  final bool paused;

  List<TalkerData> get filteredEntries {
    var list = entries;

    if (levelFilter != null) {
      list = list.where((e) => e.logLevel == levelFilter).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      list = list
          .where(
            (e) =>
                (e.message ?? '').toLowerCase().contains(q) ||
                (e.title ?? '').toLowerCase().contains(q),
          )
          .toList();
    }

    return list;
  }

  LogsState copyWith({
    List<TalkerData>? entries,
    LogLevel? levelFilter,
    String? searchQuery,
    bool? paused,
    bool clearLevelFilter = false,
  }) {
    return LogsState(
      entries: entries ?? this.entries,
      levelFilter: clearLevelFilter ? null : levelFilter ?? this.levelFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      paused: paused ?? this.paused,
    );
  }
}

class LogsNotifier extends Notifier<LogsState> {
  static const _maxEntries = 2000;

  StreamSubscription<TalkerData>? _subscription;

  @override
  LogsState build() {
    _subscription = AppLogger.talker.stream.listen(addEntry);
    ref.onDispose(() {
      unawaited(_subscription?.cancel());
    });
    return LogsState(entries: List.of(AppLogger.talker.history));
  }

  void setLevelFilter(LogLevel? level) {
    state = state.copyWith(levelFilter: level);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void togglePause() {
    final paused = !state.paused;
    final entries = paused ? state.entries : List.of(AppLogger.talker.history);
    state = state.copyWith(paused: paused, entries: entries);
  }

  void clear() {
    AppLogger.clear();
    state = state.copyWith(entries: const []);
    ref.read(coreProvider.notifier).clearLogs();
  }

  void addEntry(TalkerData entry) {
    if (state.paused) return;
    final entries = [...state.entries, entry];
    if (entries.length > _maxEntries) {
      entries.removeRange(0, entries.length - _maxEntries);
    }
    state = state.copyWith(entries: entries);
  }

  String exportLogs({bool sanitize = false}) {
    final buffer = StringBuffer();
    for (final entry in state.filteredEntries) {
      var msg = entry.message ?? '';
      if (sanitize) {
        msg = _sanitize(msg);
      }
      final level = (entry.logLevel?.name ?? 'log').toUpperCase();
      buffer.writeln(
        '${formatLogTime(entry.time)} [$level] ${entry.title ?? ''} $msg',
      );
    }
    return buffer.toString();
  }

  String _sanitize(String text) {
    return text
        .replaceAllMapped(RegExp(r'https?://[^\s]+'), (m) => '[URL]')
        .replaceAllMapped(
          RegExp(r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b'),
          (m) => '[IP]',
        )
        .replaceAllMapped(
          RegExp(r'token=[^\s&]+', caseSensitive: false),
          (m) => 'token=[HIDDEN]',
        );
  }
}

/// Formats a log timestamp as `HH:mm:ss`.
String formatLogTime(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  final s = time.second.toString().padLeft(2, '0');
  return '$h:$m:$s';
}

final logsProvider = NotifierProvider<LogsNotifier, LogsState>(
  LogsNotifier.new,
);
