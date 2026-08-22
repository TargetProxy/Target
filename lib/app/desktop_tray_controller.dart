import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart' as window;

import '../core/logging/app_logger.dart';
import '../core/runtime/core_notifier.dart';
import 'app_identity.dart';

class DesktopTrayController with tray.TrayListener, window.WindowListener {
  DesktopTrayController({
    required this.onToggleConnection,
    required this.onExit,
  });

  static const _showWindowKey = 'show_window';
  static const _toggleConnectionKey = 'toggle_connection';
  static const _exitKey = 'exit';

  final Future<void> Function() onToggleConnection;
  final Future<void> Function() onExit;

  bool _initialized = false;
  bool _exiting = false;
  bool _running = false;
  bool _busy = false;
  bool _available = false;
  bool? _windowVisible;

  Future<void> initialize(CoreState core) async {
    if (!_isDesktop || _initialized) return;

    tray.trayManager.addListener(this);
    window.windowManager.addListener(this);
    try {
      await window.windowManager.ensureInitialized();
      await window.windowManager.setPreventClose(true);
      await tray.trayManager.setIcon(
        Platform.isWindows
            ? 'windows/runner/resources/app_icon.ico'
            : 'macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_32.png',
      );
      await tray.trayManager.setToolTip(AppIdentity.displayName);
      _initialized = true;
      await updateCoreState(core, force: true);
    } on Object catch (error, stackTrace) {
      tray.trayManager.removeListener(this);
      window.windowManager.removeListener(this);
      AppLogger.warning(
        'Desktop tray initialization failed',
        source: 'tray',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> updateCoreState(CoreState core, {bool force = false}) async {
    final changed =
        _running != core.running ||
        _busy != core.busy ||
        _available != core.available;
    _running = core.running;
    _busy = core.busy;
    _available = core.available;
    if (_initialized && (force || changed)) {
      await _updateMenu();
    }
  }

  void dispose() {
    if (!_isDesktop) return;
    tray.trayManager.removeListener(this);
    window.windowManager.removeListener(this);
  }

  @override
  void onWindowClose() {
    if (!_exiting) {
      unawaited(_hideWindow());
    }
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(_showWindow());
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) {
      unawaited(tray.trayManager.popUpContextMenu());
    }
  }

  Future<void> _updateMenu() async {
    final visible = await _isWindowVisible();
    final menu = tray.Menu(
      items: [
        tray.MenuItem(
          key: _showWindowKey,
          label: visible
              ? 'Hide ${AppIdentity.displayName}'
              : 'Show ${AppIdentity.displayName}',
          onClick: (_) => unawaited(visible ? _hideWindow() : _showWindow()),
        ),
        tray.MenuItem(
          key: _toggleConnectionKey,
          label: _running ? 'Disconnect' : 'Connect',
          disabled: _busy || !_available,
          onClick: (_) => unawaited(_toggleConnection()),
        ),
        tray.MenuItem.separator(),
        tray.MenuItem(
          key: _exitKey,
          label: 'Exit',
          onClick: (_) => unawaited(_exit()),
        ),
      ],
    );
    await tray.trayManager.setContextMenu(menu);
  }

  Future<void> _toggleConnection() async {
    if (_busy || !_available) return;
    await onToggleConnection();
  }

  Future<void> _showWindow() async {
    await window.windowManager.show();
    await window.windowManager.focus();
    _windowVisible = true;
    if (_initialized) await _updateMenu();
  }

  Future<void> _hideWindow() async {
    await window.windowManager.hide();
    _windowVisible = false;
    if (_initialized) await _updateMenu();
  }

  Future<bool> _isWindowVisible() async {
    try {
      return _windowVisible ?? await window.windowManager.isVisible();
    } on Object {
      return _windowVisible ?? true;
    }
  }

  Future<void> _exit() async {
    if (_exiting) return;
    _exiting = true;
    try {
      await onExit();
      await window.windowManager.setPreventClose(false);
      await tray.trayManager.destroy();
      await window.windowManager.destroy();
    } on Object catch (error, stackTrace) {
      _exiting = false;
      AppLogger.error(
        'Desktop exit failed',
        source: 'tray',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}
