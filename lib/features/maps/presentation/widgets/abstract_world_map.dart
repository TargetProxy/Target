import 'package:material_ui/material_ui.dart';

/// 抽象世界地图 — 模仿截图的暗色剪影 + 国旗节点风格
/// 不依赖瓦片服务，纯 CustomPainter + 定位节点，可直接用于首页或 Profiles 选择国家
class AbstractWorldMap extends StatelessWidget {
  const AbstractWorldMap({
    super.key,
    this.selectedId = 'AR',
    this.onSelect,
    this.height = 360,
  });

  final String selectedId;
  final ValueChanged<String>? onSelect;
  final double height;

  @override
  Widget build(BuildContext context) {
    // 固定 10 国家，对应截图 “国家·10”，AR 为当前选中（蓝色双环）
    final nodes = [
      _CountryNode(id: 'US', flag: '🇺🇸', pos: const Offset(0.185, 0.42)),
      _CountryNode(id: 'GB', flag: '🇬🇧', pos: const Offset(0.485, 0.37)),
      _CountryNode(id: 'TR', flag: '🇹🇷', pos: const Offset(0.585, 0.44)),
      _CountryNode(id: 'JP', flag: '🇯🇵', pos: const Offset(0.855, 0.46)),
      _CountryNode(id: 'HK', flag: '🇭🇰', pos: const Offset(0.805, 0.54)),
      _CountryNode(id: 'TW', flag: '🇹🇼', pos: const Offset(0.825, 0.585)),
      _CountryNode(id: 'MY', flag: '🇲🇾', pos: const Offset(0.765, 0.60)),
      _CountryNode(id: 'SG', flag: '🇸🇬', pos: const Offset(0.795, 0.625)),
      _CountryNode(id: 'AU', flag: '🇦🇺', pos: const Offset(0.82, 0.705)),
      _CountryNode(id: 'AR', flag: '🇦🇷', pos: const Offset(0.305, 0.74)),
    ];

    // 亚洲集群连线（细线网络）
    final links = [
      ('JP', 'HK'),
      ('HK', 'TW'),
      ('HK', 'MY'),
      ('TW', 'MY'),
      ('MY', 'SG'),
      ('TW', 'SG'),
    ];

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          Offset toPx(Offset frac) => Offset(frac.dx * w, frac.dy * h);
          Map<String, Offset> posMap = {
            for (final n in nodes) n.id: toPx(n.pos)
          };

          return Stack(
            children: [
              // 大陆剪影
              Positioned.fill(
                child: CustomPaint(painter: _WorldSilhouettePainter()),
              ),
              // 连线
              Positioned.fill(
                child: CustomPaint(
                  painter: _LinkPainter(
                    links: links
                        .map((e) => (posMap[e.$1]!, posMap[e.$2]!))
                        .toList(),
                  ),
                ),
              ),
              // 节点
              for (final n in nodes)
                Positioned(
                  left: toPx(n.pos).dx - 16,
                  top: toPx(n.pos).dy - 16,
                  child: _FlagNode(
                    flag: n.flag,
                    selected: n.id == selectedId,
                    onTap: onSelect == null ? null : () => onSelect!(n.id),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CountryNode {
  const _CountryNode({required this.id, required this.flag, required this.pos});

  final String id;
  final String flag;
  final Offset pos; // 0..1 fractional
}

class _FlagNode extends StatelessWidget {
  const _FlagNode({required this.flag, required this.selected, this.onTap});

  final String flag;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // 选中：蓝色双环（外发光 + 内实心蓝），未选中：暗环 + 半透白边
    final outer = selected ? const Color(0xFF0A84FF) : const Color(0x22FFFFFF);
    final innerBg = selected ? const Color(0xFF0A84FF) : const Color(
        0xFF1F1F1F);
    final border = selected ? const Color(0xFF0A84FF) : const Color(0x33FFFFFF);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: selected ? 40 : 32,
        height: selected ? 40 : 32,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: selected ? 40 : 32,
              height: selected ? 40 : 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: outer, width: selected ? 2 : 1),
                color: Colors.transparent,
              ),
            ),
            if (selected)
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 1),
                ),
              ),
            Container(
              width: selected ? 28 : 26,
              height: selected ? 28 : 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: innerBg,
                border: Border.all(color: border, width: 1),
                boxShadow: selected
                    ? [
                  BoxShadow(color: const Color(0x550A84FF),
                      blurRadius: 8,
                      spreadRadius: 1)
                ]
                    : null,
              ),
              child: Text(flag, style: TextStyle(fontSize: selected ? 14 : 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldSilhouettePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF262626)
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // 归一化坐标转像素
    Path scaled(Path Function(double w, double h) builder) => builder(w, h);

    // 北美 — 简化多边形 + 圆角
    final na = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.04, h * 0.34)
      ..lineTo(w * 0.14, h * 0.30)..lineTo(w * 0.28, h * 0.31)..lineTo(
        w * 0.30, h * 0.38)..lineTo(w * 0.26, h * 0.48)..lineTo(
        w * 0.18, h * 0.56)..lineTo(w * 0.08, h * 0.52)..lineTo(
        w * 0.02, h * 0.42)
      ..close());

    // 南美
    final sa = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.21, h * 0.60)
      ..lineTo(w * 0.33, h * 0.60)..lineTo(w * 0.31, h * 0.78)
      ..quadraticBezierTo(w * 0.26, h * 0.82, w * 0.20, h * 0.72)
      ..close());

    // 欧洲
    final eu = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.44, h * 0.30)
      ..lineTo(w * 0.56, h * 0.29)..lineTo(w * 0.58, h * 0.36)..lineTo(
        w * 0.50, h * 0.40)..lineTo(w * 0.43, h * 0.36)
      ..close());

    // 非洲
    final af = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.47, h * 0.41)
      ..lineTo(w * 0.57, h * 0.40)..lineTo(w * 0.58, h * 0.55)..lineTo(
        w * 0.52, h * 0.68)..lineTo(w * 0.45, h * 0.64)..lineTo(
        w * 0.43, h * 0.50)
      ..close());

    // 亚洲（大块）
    final asia = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.58, h * 0.28)
      ..lineTo(w * 0.86, h * 0.30)..lineTo(w * 0.88, h * 0.52)..lineTo(
        w * 0.80, h * 0.60)..lineTo(w * 0.62, h * 0.58)..lineTo(
        w * 0.56, h * 0.44)
      ..close());

    // 澳洲
    final au = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.76, h * 0.68)
      ..lineTo(w * 0.86, h * 0.67)
      ..cubicTo(w * 0.88, h * 0.70, w * 0.86, h * 0.77, w * 0.78, h * 0.76)
      ..close());

    // 南极条带
    final antarctica = scaled((w, h) =>
    Path()
      ..moveTo(w * 0.02, h * 0.86)
      ..lineTo(w * 0.98, h * 0.84)..lineTo(w * 0.96, h * 0.90)..lineTo(
        w * 0.03, h * 0.92)
      ..close());

    for (final p in [na, sa, eu, af, asia, au, antarctica]) {
      canvas.drawPath(p, paint);
    }

    // 轻微纹理：格陵兰/细节小块
    final detail = Paint()
      ..color = const Color(0xFF262626);
    canvas.drawCircle(Offset(w * 0.38, h * 0.26), w * 0.012, detail);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LinkPainter extends CustomPainter {
  _LinkPainter({required this.links});

  final List<(Offset, Offset)> links;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final (a, b) in links) {
      canvas.drawLine(a, b, paint);
      // 中间小点
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
      canvas.drawCircle(mid, 1.2, Paint()
        ..color = const Color(0x33FFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant _LinkPainter oldDelegate) => false;
}
