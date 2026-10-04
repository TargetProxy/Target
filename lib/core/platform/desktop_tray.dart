import 'dart:async';

import 'package:flutter_alone/flutter_alone.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

final class DesktopTray with WindowListener {
  late final TrayIcon _icon;
  late final Image _image;
  late final Menu _menu;
  late final MenuItem _showItem;
  late final MenuItem _exitItem;

  Future<void> Function()? onExit;

  Future<void> initialize(String tooltip, {required bool chinese}) async {
    await windowManager.ensureInitialized();
    await windowManager.setTitle(tooltip);
    _icon = TrayIcon.create()!;
    _image = ImageAsset.fromAsset('assets/TargetAppIcon.png')!;
    _showItem = MenuItem.createWithLabelAndType(
      chinese ? '显示窗口' : 'Show window',
      MenuItemType.normal,
    )!;
    _exitItem = MenuItem.createWithLabelAndType(
      chinese ? '退出' : 'Quit',
      MenuItemType.normal,
    )!;
    _menu = Menu.create()!
      ..addItem(_showItem)
      ..addItem(_exitItem);
    _menu.addListener((event) {
      if (event is! MenuItemClickedEvent) return;
      if (event.itemId == _showItem.id) unawaited(show());
      if (event.itemId == _exitItem.id) unawaited(onExit?.call());
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
        unawaited(show());
      }
    });
    windowManager.addListener(this);
    await windowManager.setPreventClose(true);
  }

  @override
  void onWindowClose() => unawaited(windowManager.hide());

  Future<void> show() async {
    if (await windowManager.isMinimized()) await windowManager.restore();
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> quit() async {
    windowManager.removeListener(this);
    _icon.setVisible(false);
    _icon.dispose();
    _menu.dispose();
    _showItem.dispose();
    _exitItem.dispose();
    _image.dispose();
    await FlutterAlone.instance.dispose();
    await windowManager.destroy();
  }
}
