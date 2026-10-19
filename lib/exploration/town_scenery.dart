import 'package:flutter/material.dart';

import 'world_layers.dart';
import 'world_map.dart';

/// Small scenery drawn on the same 16px grid as the existing cottage art.
List<WorldEntry> townSceneryEntries(
  ExplorationMap map,
  double tile, {
  void Function(MapProp)? onReadSign,
}) => [
  for (final prop in map.props)
    WorldEntry(
      z: prop.kind == PropKind.flowers || prop.kind == PropKind.garden
          ? WorldZ.road
          : WorldZ.actor,
      depth: prop.position.dy + 1,
      child: Positioned(
        key: ValueKey(
          'prop-${prop.kind.name}-${prop.position.dx}-${prop.position.dy}',
        ),
        left: prop.position.dx * tile,
        top: prop.position.dy * tile,
        width: tile,
        height: tile,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: prop.isReadable ? () => onReadSign?.call(prop) : null,
          child: Tooltip(
            message: prop.label ?? prop.kind.name,
            child: Semantics(
              label: prop.label ?? prop.kind.name,
              image: !prop.isReadable,
              button: prop.isReadable,
              child: CustomPaint(
                painter: _PropPainter(
                  prop.kind,
                  fenceConnections: _fenceConnections(map, prop),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
];

int _fenceConnections(ExplorationMap map, MapProp prop) {
  if (!prop.isFence) return 0;
  const directions = [Offset(0, -1), Offset(1, 0), Offset(0, 1), Offset(-1, 0)];
  var connections = 0;
  for (var i = 0; i < directions.length; i++) {
    if (map.props.any(
      (p) => p.isFence && p.position == prop.position + directions[i],
    )) {
      connections |= 1 << i;
    }
  }
  return connections;
}

class _PropPainter extends CustomPainter {
  const _PropPainter(this.kind, {this.fenceConnections = 0});
  final PropKind kind;
  final int fenceConnections;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 16, size.height / 16);
    final paint = Paint()..isAntiAlias = false;
    void block(double x, double y, double w, double h, int color) {
      paint.color = Color(color);
      canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint);
    }

    const wood = 0xFF78503C;
    const lightWood = 0xFFB08458;
    const shadow = 0xFF292C31;
    switch (kind) {
      case PropKind.fence:
      case PropKind.gate:
        const aged = 0xFF827867;
        const faded = 0xFFAAA08A;
        // Rails meet at tile edges to make the enclosure visibly continuous.
        if (fenceConnections & 1 != 0) {
          block(6, 0, 2, 8, aged);
          block(10, 0, 2, 8, faded);
        }
        if (fenceConnections & 2 != 0) {
          block(8, 7, 8, 2, faded);
          block(8, 11, 8, 2, aged);
        }
        if (fenceConnections & 4 != 0) {
          block(6, 8, 2, 8, aged);
          block(10, 8, 2, 8, faded);
        }
        if (fenceConnections & 8 != 0) {
          block(0, 7, 8, 2, faded);
          block(0, 11, 8, 2, aged);
        }
        block(7, 6, 3, 9, aged);
        block(7, 5, 3, 2, faded);
        block(8, 9, 1, 3, 0xFF544D43);
        if (kind == PropKind.gate) {
          block(6, 4, 6, 1, 0xFF6B5943);
          block(6, 12, 6, 1, 0xFF6B5943);
          block(9, 7, 3, 2, 0xFFC1A276);
        }
      case PropKind.fungus:
        block(7, 7, 3, 8, 0xFFB9ADA0);
        block(9, 8, 1, 7, 0xFF706C70);
        block(2, 5, 12, 4, 0xFF4F5868);
        block(4, 2, 8, 4, 0xFF716B89);
        block(6, 1, 4, 2, 0xFF9385A1);
        block(4, 5, 2, 1, 0xFFC0A6AD);
        block(9, 3, 2, 1, 0xFFC0A6AD);
        block(1, 12, 5, 2, 0xFF6F667A);
        block(3, 14, 1, 2, 0xFFA5968E);
      case PropKind.rubble:
        block(1, 10, 14, 5, shadow);
        block(2, 6, 5, 7, 0xFF5C6066);
        block(7, 3, 5, 10, 0xFF73757C);
        block(10, 8, 5, 6, 0xFF484D58);
        block(3, 6, 3, 1, 0xFF97958E);
        block(8, 3, 3, 2, 0xFFA3A19A);
      case PropKind.flowers:
        for (final x in [3.0, 8.0, 12.0]) {
          block(x, 8, 1, 6, 0xFF60775A);
          block(x - 1, 7, 3, 2, x == 8 ? 0xFFD1B46F : 0xFF9F94B4);
          block(x + 1, 11, 2, 1, 0xFF819468);
        }
      case PropKind.garden:
        block(0, 2, 16, 13, 0xFF4A3830);
        for (final y in [4.0, 8.0, 12.0]) {
          block(1, y, 14, 1, 0xFF72533D);
          for (final x in [3.0, 7.0, 11.0]) {
            block(x, y - 1, 2, 3, 0xFF768365);
            block(x - 1, y, 4, 1, 0xFF9AA37D);
          }
        }
      case PropKind.crates:
        block(2, 4, 12, 11, shadow);
        block(2, 3, 11, 10, wood);
        for (final y in [4.0, 8.0, 12.0]) {
          block(2, y, 11, 1, lightWood);
        }
        block(3, 4, 1, 8, lightWood);
        block(11, 4, 1, 8, lightWood);
        block(7, 5, 1, 6, 0xFF533E34);
      case PropKind.bench:
        block(2, 5, 12, 3, wood);
        block(2, 5, 12, 1, lightWood);
        block(1, 9, 14, 3, lightWood);
        block(2, 12, 2, 3, wood);
        block(12, 12, 2, 3, wood);
        block(2, 11, 12, 1, wood);
      case PropKind.well:
        block(2, 6, 12, 9, shadow);
        block(1, 7, 14, 5, 0xFF94918A);
        block(3, 12, 10, 3, 0xFF676D72);
        block(4, 7, 8, 3, 0xFF1D303C);
        block(5, 8, 4, 1, 0xFF54758A);
        block(2, 2, 1, 10, wood);
        block(13, 2, 1, 10, wood);
        block(1, 1, 14, 2, lightWood);
        block(8, 3, 1, 5, 0xFFC2AD80);
      case PropKind.stall:
        block(2, 5, 1, 10, wood);
        block(13, 5, 1, 10, wood);
        block(1, 10, 14, 4, wood);
        block(1, 10, 14, 1, lightWood);
        block(0, 2, 16, 4, 0xFFB89E75);
        for (final x in [0.0, 6.0, 12.0]) {
          block(x, 2, 3, 4, 0xFF81545A);
        }
        block(3, 8, 3, 2, 0xFFB8A26F);
        block(8, 8, 4, 2, 0xFF859269);
      case PropKind.sign:
        block(7, 7, 2, 9, wood);
        block(1, 2, 14, 7, wood);
        block(2, 3, 12, 5, lightWood);
        block(4, 5, 8, 1, 0xFF493D37);
        block(5, 7, 5, 1, 0xFF493D37);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PropPainter oldDelegate) =>
      kind != oldDelegate.kind ||
      fenceConnections != oldDelegate.fenceConnections;
}

/// Soft warm pools sit below actors; the shared atmosphere still controls sight.
class TorchGlowPainter extends CustomPainter {
  const TorchGlowPainter(this.map, this.tick);
  final ExplorationMap map;
  final int tick;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / map.columns;
    final paint = Paint()..isAntiAlias = false;
    for (final torch in map.torches) {
      final center = (torch + const Offset(.5, .5)) * tile;
      final radius = tile * (tick.isEven ? 1.8 : 1.65);
      paint.shader = RadialGradient(
        colors: [
          const Color(0xFFF1B45D).withValues(alpha: .17),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawRect(Rect.fromCircle(center: center, radius: radius), paint);
    }
  }

  @override
  bool shouldRepaint(TorchGlowPainter oldDelegate) =>
      map != oldDelegate.map || tick != oldDelegate.tick;
}
