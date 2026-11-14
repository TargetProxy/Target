import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/widgets.dart';

import 'package:prism_ui/prism_ui.dart';
import '../../../../core/runtime/core_models.dart';
import '../../../../core/runtime/core_notifier.dart';
import '../../../../core/ui/app_glyphs.dart';
import '../../../../core/utils/format_bytes.dart';
import '../../../../l10n/app_localizations.dart';
import 'card.dart';
import 'layout.dart';
import 'style.dart';

final _trafficHistoryProvider = NotifierProvider<_TrafficHistory,
    ({List<TrafficSnapshot> list, int revision})>(_TrafficHistory.new);

class _TrafficHistory extends Notifier<({List<TrafficSnapshot> list, int revision})> {
  @override
  ({List<TrafficSnapshot> list, int revision}) build() {
    ref.listen(coreProvider, (_, next) {
      final traffic = next.traffic;
      if (!next.running || !traffic.available || traffic.sampledAt == null) {
        if (state.list.isNotEmpty) state = (list: [], revision: 0);
        return;
      }
      if (state.list.lastOrNull?.sampledAt == traffic.sampledAt) return;
      final samples = [...state.list, traffic];
      state = (
        list: samples.length > 60 ? samples.sublist(samples.length - 60) : samples,
        revision: state.revision + 1,
      );
    });
    final core = ref.read(coreProvider);
    final traffic = core.traffic;
    final hasSample = core.running && traffic.available && traffic.sampledAt != null;
    return (list: hasSample ? [traffic] : [], revision: hasSample ? 1 : 0);
  }
}

({String value, String unit}) _trafficShow(num bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return (value: size.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), ''), unit: units[unitIndex]);
}


const _minSpeedScale = 8 * 1024.0;

const _chartBleed = 3.0;

enum TrafficDirection {
  upload,
  download;

  num of(TrafficSnapshot traffic) => this == upload ? traffic.uploadBytes : traffic.downloadBytes;

  Glyph get glyph => this == upload ? AppGlyphs.arrowUp : AppGlyphs.arrowDown;

  Color colorOf(BuildContext context) => this == upload
      ? DashboardColors.of(context).series2
      : context.colorScheme.primary;

  Color glyphColorOf(BuildContext context) => this == upload
      ? context.colorScheme.onSurfaceVariant
      : context.colorScheme.primary;

  String labelOf(BuildContext context) => this == upload
      ? AppLocalizations.of(context).upload
      : AppLocalizations.of(context).download;
}

String _speedUnit(({String value, String unit}) show) => '${show.unit}/s';

class _Figure extends StatelessWidget {
  const _Figure({
    required this.show,
    required this.unit,
    required this.style,
    required this.unitStyle,
  });

  final ({String value, String unit}) show;
  final String unit;
  final AppTextStyle style;
  final AppTextStyle unitStyle;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: show.value,
            style: DashboardText.figure(context, style),
          ),
          TextSpan(
            text: ' $unit',
            style: DashboardText.unit(context, unitStyle),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.clip,
    );
  }
}

/// The zero line is the chart's bottom: a card lets the chart bleed past its
/// edge so idle traffic, or none sampled yet, leaves no line.
class _SpeedChart extends StatelessWidget {
  const _SpeedChart({required this.direction, required this.traffics});

  final TrafficDirection direction;
  final ({List<TrafficSnapshot> list, int revision}) traffics;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      values: [
        for (final traffic in traffics.list) direction.of(traffic).toDouble(),
      ],
      revision: traffics.revision,
      capacity: 60,
      minScale: _minSpeedScale,
      baselineRatio: 1,
      color: direction.colorOf(context),
    );
  }
}

/// The upload or the download on its own desktop card.
class SpeedCard extends ConsumerWidget {
  const SpeedCard({super.key, required this.direction});

  final TrafficDirection direction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final density = DashboardDensityScope.of(context);
    final compact = density.isCompact;
    final scale = DashboardDensityScope.scaleOf(context);
    final padding = dashboardCardPadding(density);
    final appLocalizations = AppLocalizations.of(context);
    final traffics = ref.watch(_trafficHistoryProvider);
    final total = ref.watch(coreProvider.select((state) => direction == TrafficDirection.upload
        ? state.traffic.uploadTotalBytes : state.traffic.downloadTotalBytes));
    final current = direction.of(traffics.list.lastOrNull ?? TrafficSnapshot.zero);
    final peak = traffics.list.fold<num>(
      0,
      (peak, traffic) => math.max(peak, direction.of(traffic)),
    );
    final speed = _trafficShow(current);
    return DashboardCard(
      padding: EdgeInsets.zero,
      semanticLabel: direction.labelOf(context),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            left: -_chartBleed,
            right: -_chartBleed,
            bottom: -_chartBleed,
            height: compact ? 62 : 88,
            child: RepaintBoundary(
              child: _SpeedChart(direction: direction, traffics: traffics),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 24 * scale,
                  child: Row(
                    spacing: 8,
                    children: [
                      GlyphIcon(
                        direction.glyph,
                        size: 18,
                        color: direction.glyphColorOf(context),
                      ),
                      Text(
                        direction.labelOf(context),
                        maxLines: 1,
                        style: DashboardText.cardTitle(context),
                      ),
                      Expanded(
                        child: Text(
                          formatSpeed(peak.toInt()),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: DashboardText.label(context),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                _Figure(
                  show: speed,
                  unit: _speedUnit(speed),
                  style: compact
                      ? AppTextStyle.largeTitle
                      : AppTextStyle.display,
                  unitStyle: AppTextStyle.subheadline,
                ),
                const SizedBox(height: 2),
                Text(
                  '${appLocalizations.traffic} ${formatBytes(total.toInt())}',
                  maxLines: 1,
                  style: DashboardText.label(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The phone's single card: both directions side by side.
class NetworkSpeedCard extends ConsumerWidget {
  const NetworkSpeedCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final traffics = ref.watch(_trafficHistoryProvider);
    final total = ref.watch(coreProvider.select((state) => state.traffic));
    final latest = traffics.list.lastOrNull ?? TrafficSnapshot.zero;
    return DashboardCard(
      semanticLabel: AppLocalizations.of(context).liveTraffic,
      child: Column(
        children: [
          DashboardCardHeader(
            glyph: AppGlyphs.speed,
            title: AppLocalizations.of(context).liveTraffic,
          ),
          const SizedBox(height: 12),
          Row(
            spacing: 10,
            children: [
              for (final direction in TrafficDirection.values)
                Expanded(
                  child: _SpeedTile(
                    direction: direction,
                    speed: direction.of(latest),
                    total: direction == TrafficDirection.upload ? total.uploadTotalBytes : total.downloadTotalBytes,
                    traffics: traffics,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Keeps one shape at every width, growing only when the text needs more. The
/// chart fills the tile under the title row, behind the figure and the total.
class _SpeedTile extends StatelessWidget {
  const _SpeedTile({
    required this.direction,
    required this.speed,
    required this.total,
    required this.traffics,
  });

  final TrafficDirection direction;
  final num speed;
  final num total;
  final ({List<TrafficSnapshot> list, int revision}) traffics;

  static const _aspectRatio = 1.45;
  static const _padding = EdgeInsets.fromLTRB(16, 14, 16, 12);
  static const _titleGap = 4.0;
  static const _bleed = 2.0;

  @override
  Widget build(BuildContext context) {
    final color = direction.glyphColorOf(context);
    final show = _trafficShow(speed);
    final scale = DashboardDensityScope.scaleOf(context);
    final chartTop =
        _padding.top + _titleGap + AppTextStyle.footnote.leading * scale;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            minHeight: constraints.maxWidth / _aspectRatio,
          ),
          clipBehavior: Clip.antiAlias,
          decoration: ShapeDecoration(
            color: DashboardColors.of(context).tone,
            shape: AppShape.all(DashboardCorner.mobileBlock),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -_bleed,
                right: -_bleed,
                top: chartTop,
                bottom: -_bleed,
                child: RepaintBoundary(
                  child: _SpeedChart(direction: direction, traffics: traffics),
                ),
              ),
              Padding(
                padding: _padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        GlyphIcon(direction.glyph, size: 16, color: color),
                        Flexible(
                          child: Text(
                            direction.labelOf(context),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyle.footnote
                                .of(context, emphasized: true)
                                .copyWith(
                                  color: context.colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: _titleGap),
                    _Figure(
                      show: show,
                      unit: _speedUnit(show),
                      style: AppTextStyle.title1,
                      unitStyle: AppTextStyle.footnote,
                    ),
                    Text(
                      '${AppLocalizations.of(context).traffic} ${formatBytes(total.toInt())}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DashboardText.label(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
