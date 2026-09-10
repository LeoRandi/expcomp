import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';

abstract final class FalobrisAssets {
  static const tileAtlas =
      'assets/pixel_ui/showcase/sheets_16grid/04_mar_costas/'
      '16x16_tileset_water_grass_and_sand/'
      'voda_pesok_trava_revision_2.png.png';
}

/// Bright shallows, sand, and island grass used by Falobris items.
abstract final class FalobrisUi {
  static final atlas = PixelAtlasDefinition(
    assetPath: FalobrisAssets.tileAtlas,
    regions: const {
      'top_left': PixelAtlasRegion(column: 3, row: 0),
      'top': PixelAtlasRegion(column: 4, row: 0),
      'top_right': PixelAtlasRegion(column: 5, row: 0),
      'left': PixelAtlasRegion(column: 3, row: 1),
      'grass': PixelAtlasRegion(column: 4, row: 1),
      'right': PixelAtlasRegion(column: 5, row: 1),
      'bottom_left': PixelAtlasRegion(column: 3, row: 2),
      'bottom': PixelAtlasRegion(column: 4, row: 2),
      'bottom_right': PixelAtlasRegion(column: 5, row: 2),
    },
  );

  static final panel = PixelPanelRecipe(
    topLeft: atlas.region('top_left'),
    top: PixelTileVariants.single(atlas.region('top')),
    topRight: atlas.region('top_right'),
    left: PixelTileVariants.single(atlas.region('left')),
    fill: PixelTileVariants.single(atlas.region('grass')),
    right: PixelTileVariants.single(atlas.region('right')),
    bottomLeft: atlas.region('bottom_left'),
    bottom: PixelTileVariants.single(atlas.region('bottom')),
    bottomRight: atlas.region('bottom_right'),
    solidFillColor: const Color(0xFF347F65),
  );

  static final mediumPanel = PixelPanelRecipe.ninePatch(
    0,
    3,
    const Color(0xFF347F65),
  );

  static final theme = PixelUiThemeData(
    atlas: atlas,
    palette: const PixelUiPalette(
      canvas: Color(0xFF082E48),
      surfaceFallback: Color(0xFF347F65),
      ink: Color(0xFFFFF3C4),
      mutedInk: Color(0xFFB8E4D2),
      accent: Color(0xFFFFD96D),
      energy: Color(0xFF62DAE8),
      health: Color(0xFF80D45B),
      damage: Color(0xFFF06B52),
      gold: Color(0xFFFFC94A),
    ),
    surfaces: {
      PixelSurfaceRole.panel: panel,
      PixelSurfaceRole.inset: mediumPanel,
      PixelSurfaceRole.button: panel,
      PixelSurfaceRole.dialog: panel,
    },
  );
}
