import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';

abstract final class UndiriaAssets {
  static const tileAtlas = 'assets/pixel_ui/showcase/cave_tileset.png';
}

/// Warm cavern blocks used by creatures and items originating in Undiria.
abstract final class UndiriaUi {
  static final atlas = PixelAtlasDefinition(
    assetPath: UndiriaAssets.tileAtlas,
    regions: const {
      'block_a': PixelAtlasRegion(column: 0, row: 8),
      'block_b': PixelAtlasRegion(column: 1, row: 8),
      'block_c': PixelAtlasRegion(column: 2, row: 8),
      'block_d': PixelAtlasRegion(column: 3, row: 8),
    },
  );

  static final panel = PixelPanelRecipe(
    topLeft: atlas.region('block_a'),
    top: PixelTileVariants([atlas.region('block_b'), atlas.region('block_c')]),
    topRight: atlas.region('block_d'),
    left: PixelTileVariants.single(atlas.region('block_a')),
    fill: PixelTileVariants.single(atlas.region('block_b')),
    right: PixelTileVariants.single(atlas.region('block_d')),
    bottomLeft: atlas.region('block_a'),
    bottom: PixelTileVariants([
      atlas.region('block_b'),
      atlas.region('block_c'),
    ]),
    bottomRight: atlas.region('block_d'),
    solidFillColor: const Color(0xFF21191C),
  );

  static final theme = PixelUiThemeData(
    atlas: atlas,
    palette: const PixelUiPalette(
      canvas: Color(0xFF171113),
      surfaceFallback: Color(0xFF21191C),
      ink: Color(0xFFFFE7D2),
      mutedInk: Color(0xFFC29A85),
      accent: Color(0xFFD4867D),
      energy: Color(0xFF7ECAD0),
      health: Color(0xFF75C982),
      damage: Color(0xFFE85D55),
      gold: Color(0xFFE9BC58),
    ),
    surfaces: {
      PixelSurfaceRole.panel: panel,
      PixelSurfaceRole.inset: panel,
      PixelSurfaceRole.button: panel,
      PixelSurfaceRole.dialog: panel,
    },
  );
}
