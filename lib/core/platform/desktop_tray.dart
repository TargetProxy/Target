import 'dart:async';

import 'package:flutter_alone/flutter_alone.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:tray_manager/tray_manager.dart';

import '../../l10n/app_localizations.dart';

final class DesktopTray {
  late final Window _window;
  late final ListenerId _windowListener;
  late final TrayIcon _icon;
  late final Image _image;
  late final Menu _menu;
  late final MenuItem _showItem;
  late final MenuItem _exitItem;

  Future<void> Function()? onExit;

  void initialize(String tooltip, {required AppLocalizations l10n}) {
    _window = WindowManager.instance.getCurrent()!;
    _window.title = tooltip;
    _icon = TrayIcon.create()!;
    _image = ImageAsset.fromAsset('assets/TargetAppIcon.png')!;
    _showItem = MenuItem.createWithLabelAndType(
      l10n.showWindow,
      MenuItemType.normal,
    )!;
    _exitItem = MenuItem.createWithLabelAndType(
      l10n.quit,
      MenuItemType.normal,
    )!;
    _menu = Menu.create()!
      ..addItem(_showItem)
      ..addItem(_exitItem);
    _showItem.addListener((event) {
      if (event is MenuItemClickedEvent) _show();
    });
    _exitItem.addListener((event) {
      if (event is MenuItemClickedEvent) {
        // Release menu handles after native click dispatch returns.
        Timer.run(() => unawaited(onExit?.call()));
      }
    });
    _icon
      ..icon = _image
      ..setTooltip(tooltip)
      ..setContextMenu(_menu)
      ..setContextMenuTrigger(ContextMenuTrigger.rightClicked)
      ..setVisible(true);
    _icon.addListener((event) {
      if (event is TrayIconClickedEvent ||
          event is TrayIconDoubleClickedEvent) {
        _show();
      }
    });
    _windowListener = _window.addListener((event) {
      if (event is WindowCloseRequestedEvent) {
        event.request.cancel();
        _window.hide();
      }
    });
  }

  void _show() {
    if (_window.isMinimized) _window.restore();
    _window.show();
    _window.focus();
  }

  Future<void> quit() async {
    await FlutterAlone.instance.dispose();
    _icon.setVisible(false);
    _icon.dispose();
    _menu.dispose();
    _showItem.dispose();
    _exitItem.dispose();
    _image.dispose();
    _window.removeListener(_windowListener);
    Application.instance.quit(0);
  }
}
