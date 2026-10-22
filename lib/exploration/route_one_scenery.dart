import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'world_layers.dart';
import 'world_map.dart';
import 'stock_prop_sprite.dart';

const routeOneCaveAsset = 'assets/pixel_ui/showcase/cave_tileset.png';
const routeOneSandAsset =
    'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
    '16x16_Overworld_Tiles/tiles__sand1.png.png';
const routeOneGrassAsset =
    'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
    '16x16_Overworld_Tiles/tiles__grass1.png.png';
const routeOneChestAsset = 'assets/sundered_keep/tiles/castle_tileset.png';
const routeOneArtAssets = [
  routeOneCaveAsset,
  routeOneSandAsset,
  routeOneGrassAsset,
  routeOneChestAsset,
  ...stockRockAssets,
];

/// Tile art overlays the shared granite floor; coordinates match the text map.
class RouteOneTerrain extends StatelessWidget {
  const RouteOneTerrain({super.key, required this.map});
  final ExplorationMap map;

  @override
  Widget build(BuildContext context) => PixelAtlasBuilder(
    atlas: PixelAtlasDefinition(assetPath: routeOneCaveAsset),
    builder: (context, cave, error) => PixelAtlasBuilder(
      atlas: PixelAtlasDefinition(assetPath: routeOneSandAsset),
      builder: (context, sand, error) => PixelAtlasBuilder(
        atlas: PixelAtlasDefinition(assetPath: routeOneGrassAsset),
        builder: (context, grass, error) =>
            CustomPaint(painter: _RouteTerrainPainter(map, cave, sand, grass)),
      ),
    ),
  );
}

class _RouteTerrainPainter extends CustomPainter {
  const _RouteTerrainPainter(this.map, this.cave, this.sand, this.grass);
  final ExplorationMap map;
  final ui.Image? cave;
  final ui.Image? sand;
  final ui.Image? grass;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / map.columns;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        final symbol = map.tileAt(x, y);
        final dest = Rect.fromLTWH(x * tile, y * tile, tile, tile);
        if (map.floorAt(x, y) == '.' && sand != null) {
          canvas.drawImageRect(
            sand!,
            const Rect.fromLTWH(0, 0, 16, 16),
            dest,
            paint,
          );
        }
        final image = switch (symbol) {
          'X' => cave,
          'g' => grass,
          _ => null,
        };
        if (image == null) continue;
        if (symbol == 'X') {
          canvas.drawRect(dest, Paint()..color = const Color(0xFF30282D));
        }
        canvas.drawImageRect(
          image,
          symbol == 'X'
              ? const Rect.fromLTWH(16, 32, 16, 16)
              : const Rect.fromLTWH(0, 0, 16, 16),
          dest,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RouteTerrainPainter old) =>
      map != old.map ||
      cave != old.cave ||
      sand != old.sand ||
      grass != old.grass;
}

/// Grass cover shares the sprite's moving bounds, including between grass cells.
class GrassCoveredSprite extends StatelessWidget {
  const GrassCoveredSprite({
    super.key,
    required this.covered,
    required this.child,
  });
  final bool covered;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      child,
      if (covered)
        Positioned.fill(
          key: const ValueKey('player-grass-cover'),
          child: IgnorePointer(
            child: PixelAtlasBuilder(
              atlas: PixelAtlasDefinition(assetPath: routeOneGrassAsset),
              builder: (context, image, error) =>
                  CustomPaint(painter: _GrassCoverPainter(image)),
            ),
          ),
        ),
    ],
  );
}

class _GrassCoverPainter extends CustomPainter {
  const _GrassCoverPainter(this.image);
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final grass = image;
    if (grass == null) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    canvas.drawImageRect(
      grass,
      const Rect.fromLTWH(0, 8, 16, 8),
      Rect.fromLTWH(0, size.height / 2, size.width, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(_GrassCoverPainter old) => image != old.image;
}

List<WorldEntry> routeOneSceneryEntries(
  ExplorationMap map,
  double tile, {
  bool Function(String)? isChestOpen,
  void Function(MapProp)? onOpenChest,
}) => [
  for (final prop in map.props)
    WorldEntry(
      z: WorldZ.actor,
      depth: prop.position.dy + 1,
      child: Positioned(
        key: ValueKey(
          'route-prop-${prop.kind.name}-${prop.position.dx.toInt()}-${prop.position.dy.toInt()}',
        ),
        left: prop.position.dx * tile,
        top: (prop.position.dy - (prop.kind == PropKind.rock ? .25 : 0)) * tile,
        width: tile,
        height: tile * (prop.kind == PropKind.rock ? 1.25 : 1),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: prop.chest == null ? null : () => onOpenChest?.call(prop),
          child: Semantics(
            label: prop.kind == PropKind.chest
                ? (isChestOpen?.call(prop.chest?.id ?? '') == true
                      ? 'Open chest'
                      : 'Closed chest')
                : 'Rock',
            button: prop.chest != null,
            image: prop.chest == null,
            child: prop.kind == PropKind.rock
                ? StockPropSprite(
                    kind: PropKind.rock,
                    variant:
                        (prop.position.dx.toInt() * 13 +
                            prop.position.dy.toInt() * 7) %
                        stockRockAssets.length,
                  )
                : PixelAtlasBuilder(
                    atlas: PixelAtlasDefinition(assetPath: routeOneChestAsset),
                    builder: (context, image, error) => CustomPaint(
                      painter: _RouteChestPainter(
                        image,
                        isChestOpen?.call(prop.chest?.id ?? '') == true,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ),
];

class _RouteChestPainter extends CustomPainter {
  const _RouteChestPainter(this.image, this.opened);
  final ui.Image? image;
  final bool opened;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = image;
    if (texture == null) return;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (opened) {
      // Recompose the existing sprite into an upright lid, dark cavity and base.
      canvas.drawImageRect(
        texture,
        const Rect.fromLTWH(102, 55, 20, 9),
        Rect.fromLTWH(0, size.height * .45, size.width, size.height * .55),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * .08,
          size.height * .32,
          size.width * .84,
          size.height * .25,
        ),
        Paint()..color = const Color(0xFF241C22),
      );
      canvas.drawImageRect(
        texture,
        const Rect.fromLTWH(102, 48, 20, 7),
        Rect.fromLTWH(0, 0, size.width, size.height * .32),
        paint,
      );
      return;
    }
    canvas.drawImageRect(
      texture,
      const Rect.fromLTWH(102, 48, 20, 16),
      Offset.zero & size,
      Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(_RouteChestPainter old) =>
      image != old.image || opened != old.opened;
}
