import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../app/router.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../connections/application/connections_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import 'card.dart';
import 'layout.dart';
import 'style.dart';

// Adapted from FlClash's dashboard/widgets/connections_table.dart.
class ConnectionsTableCard extends ConsumerWidget {
  const ConnectionsTableCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);
    final l10n = AppLocalizations.of(context);
    final scale = DashboardDensityScope.scaleOf(context);
    final rowHeight =
        (DashboardDensityScope.of(context).isCompact ? 32 : 34) * scale;
    final items = state.filteredConnections.take(100).toList();
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.connections,
            title: l10n.connections,
            leading: [DashboardChip(label: '${state.activeCount}')],
            trailing: [
              DashboardIconButton(
                tooltip: l10n.connections,
                onPressed: () => context.go(AppRoute.connections.path),
                glyph: AppGlyphs.chevronForward,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = [
                  TableColumn('destination', l10n.destinationSort, flex: 2),
                  TableColumn('outbound', l10n.outboundSort, flex: 1.3),
                  if (constraints.maxWidth >= 580)
                    TableColumn('network', l10n.networkSort, flex: 1),
                  TableColumn('download', l10n.download, flex: 1, end: true),
                  TableColumn('upload', l10n.upload, flex: 1, end: true),
                ];
                final widths = tableColumnWidths(columns, constraints.maxWidth);
                final shape = AppShape.all(DashboardCorner.tableHeader);
                final fill = ShapeDecoration(
                  color: DashboardColors.of(context).tone,
                  shape: shape,
                );
                final headerStyle = AppTextStyle.caption1
                    .of(context, emphasized: true)
                    .copyWith(color: context.colorScheme.onSurfaceVariant);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DecoratedBox(
                      decoration: fill,
                      child: TableCells(
                        columns: columns,
                        widths: widths,
                        height: 32 * scale,
                        inset: 8,
                        cells: [
                          for (final column in columns)
                            Text(
                              column.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: headerStyle,
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: items.isEmpty
                          ? Center(
                              child: Text(
                                l10n.noConnections,
                                style: DashboardText.label(context),
                              ),
                            )
                          : DashboardFadeOut(
                              child: PrismListView(
                                padding: const EdgeInsets.only(top: 2),
                                itemExtent: rowHeight,
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final cells = DefaultTextStyle.merge(
                                    style: AppTextStyle.footnote.of(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    child: TableCells(
                                      columns: columns,
                                      widths: widths,
                                      height: rowHeight,
                                      inset: 8,
                                      cells: [
                                        Text(
                                          item.domain.isEmpty
                                              ? item.destination
                                              : item.domain,
                                        ),
                                        Text(item.outbound),
                                        if (constraints.maxWidth >= 580)
                                          Text(item.network.toUpperCase()),
                                        Text(formatBytes(item.downlinkTotal)),
                                        Text(formatBytes(item.uplinkTotal)),
                                      ],
                                    ),
                                  );
                                  return index.isOdd
                                      ? DecoratedBox(
                                          decoration: fill,
                                          child: cells,
                                        )
                                      : cells;
                                },
                              ),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
