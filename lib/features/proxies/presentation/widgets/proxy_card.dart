import 'package:flutter/widgets.dart';
import 'package:prism_ui/prism_ui.dart';

import '../../../../data/models/proxy_node.dart';
import '../../../../l10n/app_localizations.dart';

class ProxyCard extends StatelessWidget {
  const ProxyCard({
    required this.proxy,
    required this.source,
    required this.selected,
    required this.busy,
    required this.testing,
    required this.latencyColor,
    required this.onSelected,
    super.key,
  });

  final ProxyNode proxy;
  final String source;
  final bool selected;
  final bool busy;
  final bool testing;
  final Color latencyColor;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final measure = MeasureScope.of(context);
    final proxyNameText = SizedBox(
      height: measure.textHeight(AppTextStyle.subheadline) * 2,
      child: Text(
        proxy.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyle.subheadline.of(context),
      ),
    );
    final details = Row(
      spacing: 8,
      children: [
        Expanded(
          child: Text(
            '$source · ${proxy.typeLabel}${proxy.isAvailable ? '' : ' · ${l10n.nodeUnavailable}'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.footnote.of(context).toLighter,
          ),
        ),
        if (testing)
          const ActivityIndicator(size: 14)
        else
          Text(
            proxy.latencyTimedOut
                ? l10n.timeout
                : proxy.latencyMs == null
                ? '—'
                : '${proxy.latencyMs} ms',
            style: AppTextStyle.caption2
                .of(context, emphasized: true)
                .copyWith(color: latencyColor),
          ),
      ],
    );
    return Card(
      radius: AppCorner.lg,
      enterActionsOnRight: true,
      onPressed: busy || !proxy.isAvailable ? null : onSelected,
      isSelected: selected,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Expanded(child: proxyNameText),
              if (selected) const SelectionBadge(),
            ],
          ),
          const SizedBox(height: 8),
          details,
        ],
      ),
    );
  }
}
