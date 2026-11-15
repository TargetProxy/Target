import 'package:flutter/widgets.dart';

import '../../../../core/ui/app_glyphs.dart';
import '../../../../l10n/app_localizations.dart';

enum DashboardWidget {
  status,
  traffic,
  outboundMode,
  networkTakeover,
  ip,
  profiles,
  service,
  memory,
  connections,
  proxyGroups;

  Glyph get glyph => switch (this) {
    status => AppGlyphs.status,
    traffic => AppGlyphs.speed,
    outboundMode => AppGlyphs.split,
    networkTakeover => AppGlyphs.shuffle,
    ip => AppGlyphs.devices,
    profiles => AppGlyphs.profiles,
    service => AppGlyphs.verified,
    memory => AppGlyphs.memory,
    connections => AppGlyphs.connections,
    proxyGroups => AppGlyphs.layers,
  };

  String label(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (this) {
      status => l10n.dashboardStatus,
      traffic => l10n.liveTraffic,
      outboundMode => l10n.routingMode,
      networkTakeover => l10n.dashboardNetwork,
      ip => l10n.ipInformation,
      profiles => l10n.profiles,
      service => l10n.dashboardService,
      memory => l10n.dashboardMemory,
      connections => l10n.connections,
      proxyGroups => l10n.nodeSelection,
    };
  }

  bool get removable => this != status;
}
