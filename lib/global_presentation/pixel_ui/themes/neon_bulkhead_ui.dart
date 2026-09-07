import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';

abstract final class NeonBulkheadAssets {
  static const tileAtlas = 'assets/pixel_ui/showcase/sci_fi_tileset.png';
}

/// The sci-fi frame used by items originating in Koredull.
abstract final class NeonBulkheadUi {
  static const itemTileExtent = 4.0;
  static const dialogTileExtent = 16.0;
  static const itemFallback = Color(0xFF21152C);

  static final atlas = PixelAtlasDefinition(
    assetPath: NeonBulkheadAssets.tileAtlas,
    regions: const {
      'top_left': PixelAtlasRegion(column: 0, row: 0),
      'top': PixelAtlasRegion(column: 1, row: 0),
      'top_right': PixelAtlasRegion(column: 2, row: 0),
      'left': PixelAtlasRegion(column: 0, row: 1),
      'fill': PixelAtlasRegion(column: 1, row: 1),
      'right': PixelAtlasRegion(column: 2, row: 1),
      'bottom_left': PixelAtlasRegion(column: 0, row: 2),
      'bottom': PixelAtlasRegion(column: 1, row: 2),
      'bottom_right': PixelAtlasRegion(column: 2, row: 2),
    },
  );

  static final panel = PixelPanelRecipe(
    topLeft: atlas.region('top_left'),
    top: PixelTileVariants.single(atlas.region('top')),
    topRight: atlas.region('top_right'),
    left: PixelTileVariants.single(atlas.region('left')),
    fill: PixelTileVariants.single(atlas.region('fill')),
    right: PixelTileVariants.single(atlas.region('right')),
    bottomLeft: atlas.region('bottom_left'),
    bottom: PixelTileVariants.single(atlas.region('bottom')),
    bottomRight: atlas.region('bottom_right'),
  );

  static final theme = PixelUiThemeData(
    atlas: atlas,
    palette: const PixelUiPalette(
      canvas: Color(0xFF100B16),
      surfaceFallback: itemFallback,
      ink: Color(0xFFFFEAF8),
      mutedInk: Color(0xFFB68BAE),
      accent: Color(0xFFFF68C7),
      energy: Color(0xFF58E7F1),
      health: Color(0xFF65D991),
      damage: Color(0xFFFF5B78),
      gold: Color(0xFFFFD45A),
    ),
    surfaces: {
      PixelSurfaceRole.panel: panel,
      PixelSurfaceRole.inset: panel,
      PixelSurfaceRole.button: panel,
      PixelSurfaceRole.dialog: panel,
    },
  );
}
