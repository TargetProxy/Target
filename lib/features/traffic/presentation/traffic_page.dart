import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../core/runtime/core_notifier.dart';
import '../../../core/utils/format_bytes.dart';
import '../../../core/widgets/target_page_layout.dart';
import '../../../l10n/app_localizations.dart';

const _trafficTransition = Duration(milliseconds: 220);

class TrafficPage extends ConsumerStatefulWidget {
  const TrafficPage({super.key});

  @override
  ConsumerState<TrafficPage> createState() => _TrafficPageState();
}

class _TrafficPageState extends ConsumerState<TrafficPage> {
  static const _maxHistoryPoints = 60;

  final _history = <_TrafficPoint>[];
  DateTime? _lastSampledAt;

  @override
  void initState() {
    super.initState();
    ref.listenManual<CoreState>(
      coreProvider,
      (_, next) => _recordTraffic(next),
      fireImmediately: true,
    );
  }

  void _recordTraffic(CoreState core) {
    final traffic = core.traffic;
    final sampledAt = traffic.sampledAt;
    if (!core.running || !traffic.available || sampledAt == null) {
      if (_history.isEmpty && _lastSampledAt == null) return;
      if (mounted) {
        setState(_clearHistory);
      } else {
        _clearHistory();
      }
      return;
    }
    if (_lastSampledAt == sampledAt) return;

    void append() {
      _lastSampledAt = sampledAt;
      _history.add(
        _TrafficPoint(
          time: sampledAt,
          uploadBytes: traffic.uploadBytes,
          downloadBytes: traffic.downloadBytes,
        ),
      );
      if (_history.length > _maxHistoryPoints) {
        _history.removeRange(0, _history.length - _maxHistoryPoints);
      }
    }

    if (mounted) {
      setState(append);
    } else {
      append();
    }
  }

  void _clearHistory() {
    _history.clear();
    _lastSampledAt = null;
  }

  @override
  Widget build(BuildContext context) {
    final core = ref.watch(coreProvider);
    final traffic = core.traffic;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final history = List<_TrafficPoint>.of(_history);
    final animate = !MediaQuery.disableAnimationsOf(context);
    return SafeArea(
      child: TargetPageLayout(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TargetPageHeader(
              title: l10n.traffic,
              subtitle: l10n.trafficSubtitle,
            ),
            const SizedBox(height: 22),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.monitor_heart_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l10n.liveTraffic,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusLabel(running: core.running),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(color: colors.outlineVariant),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final metrics = [
                          _Metric(
                            title: l10n.uploadRate,
                            value: core.running
                                ? formatSpeed(traffic.uploadBytes)
                                : '--',
                            icon: Icons.arrow_upward,
                            color: colors.tertiary,
                          ),
                          _Metric(
                            title: l10n.downloadRate,
                            value: core.running
                                ? formatSpeed(traffic.downloadBytes)
                                : '--',
                            icon: Icons.arrow_downward,
                            color: colors.primary,
                          ),
                          _Metric(
                            title: l10n.activeConnections,
                            value: core.running
                                ? '${traffic.activeConnections}'
                                : '--',
                            icon: Icons.hub_outlined,
                            color: colors.secondary,
                          ),
                        ];
                        if (constraints.maxWidth < 560) {
                          return Column(
                            children: [
                              for (
                                var index = 0;
                                index < metrics.length;
                                index++
                              ) ...[
                                metrics[index],
                                if (index < metrics.length - 1)
                                  Divider(color: colors.outlineVariant),
                              ],
                            ],
                          );
                        }
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (
                                var index = 0;
                                index < metrics.length;
                                index++
                              ) ...[
                                Expanded(child: metrics[index]),
                                if (index < metrics.length - 1)
                                  VerticalDivider(color: colors.outlineVariant),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                    if (history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: SfCartesianChart(
                          margin: EdgeInsets.zero,
                          plotAreaBorderWidth: 0,
                          tooltipBehavior: TooltipBehavior(enable: true),
                          primaryXAxis: DateTimeAxis(
                            dateFormat: DateFormat.Hms(),
                            desiredIntervals: 3,
                            edgeLabelPlacement: EdgeLabelPlacement.shift,
                            labelIntersectAction: AxisLabelIntersectAction.hide,
                            labelStyle: theme.textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.65,
                              ),
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                            majorGridLines: const MajorGridLines(width: 0),
                            majorTickLines: const MajorTickLines(size: 0),
                            axisLine: const AxisLine(width: 0),
                          ),
                          primaryYAxis: NumericAxis(
                            minimum: 0,
                            axisLine: const AxisLine(width: 0),
                            majorTickLines: const MajorTickLines(size: 0),
                            majorGridLines: MajorGridLines(
                              color: colors.outlineVariant.withValues(
                                alpha: 0.4,
                              ),
                              dashArray: const [4, 4],
                            ),
                            axisLabelFormatter: (details) => ChartAxisLabel(
                              formatSpeed(details.value.round()),
                              details.textStyle,
                            ),
                          ),
                          series: <CartesianSeries<_TrafficPoint, DateTime>>[
                            for (final upload in [true, false])
                              SplineAreaSeries<_TrafficPoint, DateTime>(
                                name: upload
                                    ? l10n.uploadRate
                                    : l10n.downloadRate,
                                dataSource: history,
                                xValueMapper: (point, _) => point.time,
                                yValueMapper: (point, _) => upload
                                    ? point.uploadBytes
                                    : point.downloadBytes,
                                splineType: SplineType.monotonic,
                                color: upload
                                    ? colors.tertiary
                                    : colors.primary,
                                animationDuration: animate
                                    ? _trafficTransition.inMilliseconds
                                          .toDouble()
                                    : 0,
                                borderColor: upload
                                    ? colors.tertiary
                                    : colors.primary,
                                borderWidth: 2,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    (upload ? colors.tertiary : colors.primary)
                                        .withValues(alpha: 0.16),
                                    (upload ? colors.tertiary : colors.primary)
                                        .withValues(alpha: 0),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrafficPoint {
  const _TrafficPoint({
    required this.time,
    required this.uploadBytes,
    required this.downloadBytes,
  });

  final DateTime time;
  final int uploadBytes;
  final int downloadBytes;
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: theme.textTheme.labelMedium),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : _trafficTransition,
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previousChildren, ?currentChild],
                  ),
                  child: Text(
                    value,
                    key: ValueKey(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({required this.running});

  final bool running;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final color = running ? colors.primary : colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          running ? Icons.check_circle : Icons.pause_circle_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 6),
        Text(
          running ? l10n.running : l10n.stopped,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
