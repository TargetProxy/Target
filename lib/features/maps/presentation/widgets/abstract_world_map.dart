import 'dart:math' as math;

import 'package:country_flags/country_flags.dart';
import 'package:material_ui/material_ui.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

import '../../../../l10n/app_localizations.dart';
import '../../application/proxy_country_map.dart';

class AbstractWorldMap extends StatefulWidget {
  const AbstractWorldMap({
    super.key,
    this.nodes = const [],
    this.selectedId,
    this.onSelect,
    this.height = 360,
  });

  final List<ProxyCountryMapEntry> nodes;
  final String? selectedId;
  final ValueChanged<String>? onSelect;
  final double height;

  @override
  State<AbstractWorldMap> createState() => _AbstractWorldMapState();
}

class _AbstractWorldMapState extends State<AbstractWorldMap> {
  late final MapShapeSource _source = MapShapeSource.asset(
    'assets/maps/world_map.json',
    shapeDataField: 'name',
  );
  late final MapZoomPanBehavior _zoomPanBehavior;
  late final MapShapeLayerController _mapController = MapShapeLayerController();
  late MapLatLngBounds? _autoBounds;
  late String _nodeSignature;
  late String _markerSignature;

  @override
  void initState() {
    super.initState();
    _nodeSignature = _signatureFor(widget.nodes);
    _markerSignature = _markerSignatureFor(widget.nodes, widget.selectedId);
    _autoBounds = _boundsFor(widget.nodes);
    _zoomPanBehavior = MapZoomPanBehavior(
      latLngBounds: _autoBounds,
      maxZoomLevel: 8,
      enablePanning: true,
      enablePinching: true,
      enableDoubleTapZooming: true,
      enableMouseWheelZooming: false,
      showToolbar: false,
    );
  }

  @override
  void didUpdateWidget(AbstractWorldMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSignature = _signatureFor(widget.nodes);
    final nextMarkerSignature = _markerSignatureFor(
      widget.nodes,
      widget.selectedId,
    );
    final geographyChanged = nextSignature != _nodeSignature;
    final markersChanged = nextMarkerSignature != _markerSignature;
    _markerSignature = nextMarkerSignature;
    if (!geographyChanged) {
      if (markersChanged) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _mapController.markersCount != widget.nodes.length) {
            return;
          }
          _mapController.updateMarkers(
            List<int>.generate(widget.nodes.length, (index) => index),
          );
        });
      }
      return;
    }

    _nodeSignature = nextSignature;
    _autoBounds = _boundsFor(widget.nodes);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _nodeSignature == nextSignature) _fitNodes();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final background = isDark
        ? colorScheme.surfaceContainerLowest
        : colorScheme.surface;
    final land = isDark
        ? colorScheme.onSurface.withValues(alpha: 0.10)
        : colorScheme.onSurface.withValues(alpha: 0.055);
    final coast = colorScheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.04);

    return Semantics(
      label: l10n.proxyNodeWorldMap,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: SfMaps(
                  layers: [
                    MapShapeLayer(
                      key: ValueKey(_nodeSignature),
                      source: _source,
                      controller: _mapController,
                      color: land,
                      strokeColor: coast,
                      strokeWidth: 0.35,
                      initialMarkersCount: widget.nodes.length,
                      zoomPanBehavior: _zoomPanBehavior,
                      markerBuilder: (context, index) {
                        final node = widget.nodes[index];
                        final selected = node.countryCode == widget.selectedId;
                        return MapMarker(
                          latitude: node.latitude,
                          longitude: node.longitude,
                          size: const Size.square(44),
                          child: _CountryMarker(
                            node: node,
                            selected: selected,
                            onTap: widget.onSelect == null
                                ? null
                                : () => widget.onSelect!(node.countryCode),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: _MapToolbar(
                onZoomIn: _zoomIn,
                onZoomOut: _zoomOut,
                onFit: _fitNodes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _zoomIn() {
    _zoomPanBehavior.zoomLevel = math.min(
      _zoomPanBehavior.zoomLevel + 1,
      _zoomPanBehavior.maxZoomLevel,
    );
  }

  void _zoomOut() {
    _zoomPanBehavior.zoomLevel = math.max(
      _zoomPanBehavior.zoomLevel - 1,
      _zoomPanBehavior.minZoomLevel,
    );
  }

  void _fitNodes() {
    final bounds = _autoBounds;
    if (bounds != null) {
      _zoomPanBehavior.latLngBounds = bounds;
      return;
    }
    _zoomPanBehavior
      ..zoomLevel = _zoomPanBehavior.minZoomLevel
      ..focalLatLng = const MapLatLng(0, 0);
  }
}

class _MapToolbar extends StatelessWidget {
  const _MapToolbar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFit,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.94),
      elevation: 2,
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapToolButton(
              icon: Icons.add,
              tooltip: l10n.zoomIn,
              onPressed: onZoomIn,
            ),
            _MapToolButton(
              icon: Icons.remove,
              tooltip: l10n.zoomOut,
              onPressed: onZoomOut,
            ),
            _MapToolButton(
              icon: Icons.center_focus_strong,
              tooltip: l10n.fitMapToNodes,
              onPressed: onFit,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapToolButton extends StatelessWidget {
  const _MapToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 34,
    child: IconButton(
      padding: EdgeInsets.zero,
      iconSize: 18,
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );
}

class _CountryMarker extends StatelessWidget {
  const _CountryMarker({
    required this.node,
    required this.selected,
    this.onTap,
  });

  final ProxyCountryMapEntry node;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = AppLocalizations.of(
      context,
    ).countryMarkerNodeCount(node.countryCode, node.nodeCount);

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: onTap == null
              ? SystemMouseCursors.basic
              : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: SizedBox.square(
              dimension: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: selected ? 42 : 34,
                    height: selected ? 42 : 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected
                          ? colorScheme.primary.withValues(alpha: 0.12)
                          : colorScheme.surface.withValues(alpha: 0.86),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selected
                              ? colorScheme.primary.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.10),
                          blurRadius: selected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.surface,
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: CountryFlag.fromCountryCode(
                        node.countryCode,
                        key: ValueKey('country-flag-${node.countryCode}'),
                        theme: const ImageTheme(
                          width: 23,
                          height: 23,
                          shape: Circle(),
                        ),
                      ),
                    ),
                  ),
                  if (node.nodeCount > 1)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 16),
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colorScheme.surface),
                        ),
                        child: Text(
                          '${node.nodeCount}',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onPrimary,
                                fontSize: 9,
                                height: 1,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _signatureFor(List<ProxyCountryMapEntry> nodes) {
  return nodes
      .map((node) => '${node.countryCode}:${node.latitude}:${node.longitude}')
      .join('|');
}

String _markerSignatureFor(
  List<ProxyCountryMapEntry> nodes,
  String? selectedId,
) {
  return '${nodes.map((node) => '${node.countryCode}:${node.nodeCount}').join('|')}@$selectedId';
}

MapLatLngBounds? _boundsFor(List<ProxyCountryMapEntry> nodes) {
  if (nodes.isEmpty) return null;

  var minLatitude = nodes.first.latitude;
  var maxLatitude = nodes.first.latitude;
  var minLongitude = nodes.first.longitude;
  var maxLongitude = nodes.first.longitude;
  for (final node in nodes.skip(1)) {
    minLatitude = math.min(minLatitude, node.latitude);
    maxLatitude = math.max(maxLatitude, node.latitude);
    minLongitude = math.min(minLongitude, node.longitude);
    maxLongitude = math.max(maxLongitude, node.longitude);
  }

  final latitudeRange = _paddedRange(
    minLatitude,
    maxLatitude,
    minimumSpan: 12,
    paddingFraction: 0.18,
    minimumPadding: 4,
    lowerLimit: -85,
    upperLimit: 85,
  );
  final longitudeRange = _paddedRange(
    minLongitude,
    maxLongitude,
    minimumSpan: 20,
    paddingFraction: 0.12,
    minimumPadding: 6,
    lowerLimit: -180,
    upperLimit: 180,
  );

  return MapLatLngBounds(
    MapLatLng(latitudeRange.$2, longitudeRange.$2),
    MapLatLng(latitudeRange.$1, longitudeRange.$1),
  );
}

(double, double) _paddedRange(
  double minimum,
  double maximum, {
  required double minimumSpan,
  required double paddingFraction,
  required double minimumPadding,
  required double lowerLimit,
  required double upperLimit,
}) {
  final center = (minimum + maximum) / 2;
  final contentSpan = math.max(maximum - minimum, minimumSpan);
  final padding = math.max(contentSpan * paddingFraction, minimumPadding);
  final desiredSpan = math.min(
    contentSpan + padding * 2,
    upperLimit - lowerLimit,
  );
  var lower = center - desiredSpan / 2;
  var upper = center + desiredSpan / 2;
  if (lower < lowerLimit) {
    upper += lowerLimit - lower;
    lower = lowerLimit;
  }
  if (upper > upperLimit) {
    lower -= upper - upperLimit;
    upper = upperLimit;
  }
  return (lower, upper);
}
