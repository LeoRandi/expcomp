import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'stock_prop_sprite.dart';
import 'world_map.dart';

const indoorWoodAsset =
    'assets/pixel_ui/showcase/tiles_16x16/07_overworld_mixto/'
    '16x16_Puny_World_Tileset/punyworld-overworld-tileset_0/tile_y027_x022.png';
const indoorWallAsset = 'assets/sundered_keep/tiles/castle_tileset.png';
const indoorArtAssets = [
  indoorWoodAsset,
  indoorWallAsset,
  ...stockSceneryAssets,
];

/// Existing wood and masonry art, with no ground outside the authored rooms.
class IndoorTerrain extends StatelessWidget {
  const IndoorTerrain({super.key, required this.map});
  final ExplorationMap map;

  @override
  Widget build(BuildContext context) => PixelAtlasBuilder(
    atlas: PixelAtlasDefinition(assetPath: indoorWoodAsset),
    builder: (context, wood, error) => PixelAtlasBuilder(
      atlas: PixelAtlasDefinition(assetPath: indoorWallAsset),
      builder: (context, wall, error) =>
          CustomPaint(painter: _IndoorPainter(map, wood, wall)),
    ),
  );
}

class _IndoorPainter extends CustomPainter {
  const _IndoorPainter(this.map, this.wood, this.wall);
  final ExplorationMap map;
  final ui.Image? wood;
  final ui.Image? wall;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final tile = size.width / map.columns;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        final image = map.tileAt(x, y) == 'x'
            ? wall
            : map.floorAt(x, y) == 'W'
            ? wood
            : null;
        if (image == null) continue;
        canvas.drawImageRect(
          image,
          const Rect.fromLTWH(0, 0, 16, 16),
          Rect.fromLTWH(x * tile, y * tile, tile, tile),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_IndoorPainter old) =>
      map != old.map || wood != old.wood || wall != old.wall;
}
