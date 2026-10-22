import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'world_map.dart';

const _foliage =
    'assets/pixel_ui/showcase/tiles_16x16/01_praderas_campos/'
    'Idylwild_s_Foliage_Pack/foliage_pack/';
const stockRockAssets = [
  '${_foliage}tile_y006_x007.png',
  '${_foliage}tile_y006_x008.png',
];
const stockSceneryAssets = [
  ...stockRockAssets,
  '${_foliage}tile_y006_x013.png',
  '${_foliage}tile_y015_x014.png',
  'assets/sundered_keep/tiles/castle_tileset.png',
  'assets/overworld/cottage/cottage.png',
];

/// Existing imported art only; missing furniture uses an explicit named tile.
class StockPropSprite extends StatelessWidget {
  const StockPropSprite({super.key, required this.kind, this.variant = 0});
  final PropKind kind;
  final int variant;

  @override
  Widget build(BuildContext context) {
    final sprite = switch (kind) {
      PropKind.rock => (
        stockRockAssets[variant % stockRockAssets.length],
        const Rect.fromLTWH(0, 0, 16, 16),
      ),
      PropKind.crates => (
        '${_foliage}tile_y006_x013.png',
        const Rect.fromLTWH(0, 0, 16, 16),
      ),
      PropKind.flowers => (
        '${_foliage}tile_y015_x014.png',
        const Rect.fromLTWH(0, 0, 16, 16),
      ),
      PropKind.bench => (
        'assets/sundered_keep/tiles/castle_tileset.png',
        const Rect.fromLTWH(21, 64, 40, 16),
      ),
      PropKind.door => (
        'assets/overworld/cottage/cottage.png',
        const Rect.fromLTWH(16, 16, 16, 32),
      ),
      _ => null,
    };
    final label = '${kind.name[0].toUpperCase()}${kind.name.substring(1)}';
    if (sprite == null) return NamedPropTile(label: label);
    return PixelAtlasBuilder(
      atlas: PixelAtlasDefinition(assetPath: sprite.$1),
      builder: (context, image, error) => error != null
          ? NamedPropTile(label: label)
          : CustomPaint(painter: _StockSpritePainter(image, sprite.$2)),
    );
  }
}

class NamedPropTile extends StatelessWidget {
  const NamedPropTile({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: ExcludeSemantics(
      child: DecoratedBox(
        key: ValueKey('placeholder-${label.toLowerCase()}'),
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE),
          border: Border.all(color: const Color(0xFF555555)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _StockSpritePainter extends CustomPainter {
  const _StockSpritePainter(this.image, this.region);
  final ui.Image? image;
  final Rect region;

  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    canvas.drawImageRect(
      image!,
      region,
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_StockSpritePainter old) =>
      image != old.image || region != old.region;
}
