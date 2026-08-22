import 'package:material_ui/material_ui.dart';

import '../../../../data/models/proxy_node.dart';
import 'proxy_latency_chip.dart';

class ProxyNodeTile extends StatelessWidget {
  const ProxyNodeTile({
    required this.node,
    required this.onTap,
    required this.onLongPress,
    super.key,
  });

  final ProxyNode node;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      leading: ProxyNodeIcon(countryCode: node.countryCode, type: node.type),
      title: Text(node.name, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${node.typeLabel}${node.countryCode != null ? ' · ${node.countryCode}' : ''}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ProxyLatencyChip(latencyMs: node.latencyMs),
          if (node.isSelected) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.check_circle,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ],
        ],
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

class ProxyNodeIcon extends StatelessWidget {
  const ProxyNodeIcon({this.countryCode, required this.type, super.key});

  final String? countryCode;
  final String type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedType = type.trim().toLowerCase();
    final code = _validCountryCode(countryCode);
    final tone = _typeTone(normalizedType, theme.colorScheme);

    return Semantics(
      label: code == null ? '$type proxy' : '$code ${type.toUpperCase()} proxy',
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: code == null
                    ? tone.withValues(alpha: 0.12)
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: code == null
                      ? tone.withValues(alpha: 0.22)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: code == null
                  ? Icon(_typeIcon(normalizedType), size: 21, color: tone)
                  : Text(
                      _flagEmoji(code),
                      style: const TextStyle(fontSize: 23, height: 1),
                    ),
            ),
            if (code != null)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 19,
                  height: 19,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tone,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surface,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _typeIcon(normalizedType),
                    size: 11,
                    color: _onTypeTone(normalizedType, theme.colorScheme),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String? _validCountryCode(String? value) {
    final normalized = value?.trim().toUpperCase();
    if (normalized == null || !RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
      return null;
    }
    return normalized;
  }

  String _flagEmoji(String countryCode) {
    final upper = countryCode.toUpperCase();
    final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  IconData _typeIcon(String type) {
    return switch (type) {
      'ss' || 'ssr' || 'shadowsocks' => Icons.shield_outlined,
      'vmess' || 'vless' => Icons.bolt_outlined,
      'trojan' => Icons.security_outlined,
      'hysteria' || 'hysteria2' || 'hy2' => Icons.speed_rounded,
      'tuic' => Icons.rocket_launch_outlined,
      'wireguard' || 'wg' => Icons.vpn_lock_outlined,
      'shadowtls' => Icons.enhanced_encryption_outlined,
      'naive' => Icons.language_outlined,
      'http' || 'https' || 'http-connect' => Icons.public_outlined,
      'socks' || 'socks5' => Icons.route_outlined,
      'direct' => Icons.near_me_outlined,
      'block' => Icons.block_outlined,
      _ => Icons.dns_outlined,
    };
  }

  Color _typeTone(String type, ColorScheme colors) {
    return switch (type) {
      'direct' => colors.tertiary,
      'block' => colors.error,
      'hysteria' || 'hysteria2' || 'hy2' || 'tuic' => colors.secondary,
      'wireguard' || 'wg' || 'shadowtls' => colors.tertiary,
      _ => colors.primary,
    };
  }

  Color _onTypeTone(String type, ColorScheme colors) {
    return switch (type) {
      'direct' => colors.onTertiary,
      'block' => colors.onError,
      'hysteria' || 'hysteria2' || 'hy2' || 'tuic' => colors.onSecondary,
      'wireguard' || 'wg' || 'shadowtls' => colors.onTertiary,
      _ => colors.onPrimary,
    };
  }
}
