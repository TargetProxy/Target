import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart' as tray;
import 'package:window_manager/window_manager.dart' as window;

import '../core/logging/app_logger.dart';
import '../core/runtime/core_notifier.dart';
import 'app_identity.dart';

class DesktopTrayController with window.WindowListener {
  DesktopTrayController({
    required this.onToggleConnection,
    required this.onExit,
  });

  final Future<void> Function() onToggleConnection;
  final Future<void> Function() onExit;

  bool _initialized = false;
  bool _exiting = false;
  bool _running = false;
  bool _busy = false;
  bool _available = false;
  bool? _windowVisible;
  tray.TrayIcon? _trayIcon;

  Future<void> initialize(CoreState core) async {
    if (_initialized) return;

    window.windowManager.addListener(this);
    try {
      await window.windowManager.ensureInitialized();
      await window.windowManager.setPreventClose(true);
      final trayIcon = tray.TrayIcon.create();
      if (trayIcon == null) throw StateError('Unable to create tray icon');
      final icon = tray.ImageAsset.fromAsset(
        Platform.isWindows
            ? 'windows/runner/resources/app_icon.ico'
            : 'assets/TargetAppIcon.png',
      );
      if (icon == null) throw StateError('Unable to load tray icon image');
      trayIcon.icon = icon;
      trayIcon.setTooltip(AppIdentity.displayName);
      trayIcon.setContextMenuTrigger(tray.ContextMenuTrigger.rightClicked);
      trayIcon.addListener((event) {
        if (event is tray.TrayIconClickedEvent) unawaited(_showWindow());
      });
      trayIcon.setVisible(true);
      _trayIcon = trayIcon;
      _initialized = true;
      await updateCoreState(core, force: true);
    } on Object catch (error, stackTrace) {
      _trayIcon?.dispose();
      _trayIcon = null;
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
    _trayIcon?.dispose();
    _trayIcon = null;
    window.windowManager.removeListener(this);
  }

  @override
  void onWindowClose() {
    if (!_exiting) {
      unawaited(_hideWindow());
    }
  }

  Future<void> _updateMenu() async {
    final visible = await _isWindowVisible();
    final menu = tray.Menu.create();
    if (menu == null || _trayIcon == null) return;

    final showItem = tray.MenuItem.createWithLabelAndType(
      visible
          ? 'Hide ${AppIdentity.displayName}'
          : 'Show ${AppIdentity.displayName}',
      tray.MenuItemType.normal,
    );
    final toggleItem = tray.MenuItem.createWithLabelAndType(
      _running ? 'Disconnect' : 'Connect',
      tray.MenuItemType.normal,
    );
    final exitItem = tray.MenuItem.createWithLabelAndType(
      'Exit',
      tray.MenuItemType.normal,
    );
    if (showItem == null || toggleItem == null || exitItem == null) return;
    toggleItem.isEnabled = !_busy && _available;
    showItem.addListener((event) {
      if (event is tray.MenuItemClickedEvent) {
        unawaited(visible ? _hideWindow() : _showWindow());
      }
    });
    toggleItem.addListener((event) {
      if (event is tray.MenuItemClickedEvent) unawaited(_toggleConnection());
    });
    exitItem.addListener((event) {
      if (event is tray.MenuItemClickedEvent) unawaited(_exit());
    });
    menu.addItem(showItem);
    menu.addItem(toggleItem);
    menu.addSeparator();
    menu.addItem(exitItem);
    _trayIcon!.setContextMenu(menu);
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
      _trayIcon?.dispose();
      _trayIcon = null;
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
}
