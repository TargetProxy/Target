import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/app_settings.dart';
import '../data/settings_store.dart';

/// Settings snapshot injected at startup (e.g. loaded from disk in `main()`).
final initialSettingsProvider = Provider<AppSettings>(
      (ref) => const AppSettings(),
);

/// Persistence for [AppSettings]. Override in tests or for file storage.
final settingsStoreProvider = Provider<AppSettingsStore>(
      (ref) => MemorySettingsStore(),
);

/// Immutable snapshot of the settings screen.
@immutable
class SettingsState {
  const SettingsState({
    this.settings = const AppSettings(),
    this.saving = false,
    this.lastError,
  });

  final AppSettings settings;
  final bool saving;
  final Object? lastError;

  SettingsState copyWith({
    AppSettings? settings,
    bool? saving,
    Object? lastError,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      saving: saving ?? this.saving,
      lastError: clearError ? null : lastError ?? this.lastError,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  late final AppSettingsStore _store;
  bool _saveInFlight = false;
  bool _saveAgain = false;

  @override
  SettingsState build() {
    _store = ref.read(settingsStoreProvider);
    return SettingsState(settings: ref.read(initialSettingsProvider));
  }

  void updateSettings(AppSettings Function(AppSettings) updater) {
    state = state.copyWith(settings: updater(state.settings), clearError: true);
    unawaited(_saveLatest());
  }

  void setProxyMode(ProxyMode mode) {
    updateSettings(
          (settings) =>
          settings.copyWith(
            proxyMode: mode,
            // TUN owns the traffic entry point. Keeping the mixed inbound enabled
            // at the same time makes Windows expose two competing proxy paths.
            systemProxy: mode == ProxyMode.tun ? false : settings.systemProxy,
          ),
    );
  }

  Future<void> _saveLatest() async {
    if (_saveInFlight) {
      _saveAgain = true;
      return;
    }

    _saveInFlight = true;
    state = state.copyWith(saving: true);
    do {
      _saveAgain = false;
      final settings = state.settings;
      try {
        await _store.save(settings);
        state = state.copyWith(clearError: true);
      } catch (error) {
        state = state.copyWith(lastError: error);
      }
    } while (_saveAgain);

    _saveInFlight = false;
    state = state.copyWith(saving: false);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
