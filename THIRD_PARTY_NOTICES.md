# Third-party UI code

`prism_ui` is consumed from pub.dev as a hosted dependency.
Its GPL-3.0 license and third-party notices are included in the published package.

The dashboard primitives (`lib/features/home/presentation/dashboard/card.dart`,
`layout.dart`, `style.dart`, `traffic.dart`, `outbound_mode.dart`,
`network_takeover.dart`, `start_toggle.dart`, `edit.dart`, `connections_table.dart`,
`proxy_groups.dart`, `usage_progress.dart`), empty-state illustrations
(`lib/core/ui/null_status_illustration.dart`), page scaffold (`lib/core/ui/scaffold/`), selected
application glyphs (`lib/core/ui/app_glyphs.dart`), subscription and proxy cards
(`lib/features/profiles/presentation/widgets/subscription_card.dart`,
`lib/features/proxies/presentation/widgets/proxy_card.dart`), record containers
(`lib/core/ui/record.dart`), title chips (`lib/core/ui/chip_title.dart`),
and navigation layout are
copied or adapted from the sibling FlClash checkout, licensed under GPL-3.0.
Target-specific data bindings replace FlClash's application dependencies.
The FlClash license is preserved in `licenses/FlClash-GPL-3.0.txt`.

Upstream: https://github.com/chen08209/FlClash
UI library: https://github.com/chen08209/prism_ui
