import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';

abstract final class SunderedKeepAssets {
  static const tileAtlas = 'assets/sundered_keep/tiles/castle_tileset.png';
  static const iconDirectory = 'assets/sundered_keep/icons';
  static const monsterDirectory = 'assets/monsters';
}

/// Basic style for grasslands, plains, hills and such.
abstract final class SunderedKeepUi {
  static final atlas = PixelAtlasDefinition(
    assetPath: SunderedKeepAssets.tileAtlas,
    regions: const {
      // The two diagonal beam joints immediately right of the chair sprites.
      // Their occupied edges identify which side of the frame they belong to.
      'timber_diagonal_a': PixelAtlasRegion(column: 7, row: 8),
      'timber_diagonal_b': PixelAtlasRegion(column: 6, row: 8),
      // The horizontal and vertical three-cell beams highlighted in the atlas.
      'timber_horizontal_start': PixelAtlasRegion(column: 5, row: 7),
      'timber_horizontal_middle': PixelAtlasRegion(column: 6, row: 7),
      'timber_horizontal_end': PixelAtlasRegion(column: 7, row: 7),
      'timber_vertical_start': PixelAtlasRegion(column: 7, row: 4),
      'timber_vertical_middle': PixelAtlasRegion(column: 7, row: 5),
      'timber_vertical_end': PixelAtlasRegion(column: 7, row: 6),
      'brick_corner': PixelAtlasRegion(column: 0, row: 0),
      'brick_fill': PixelAtlasRegion(column: 1, row: 1),
      'stone_fill': PixelAtlasRegion(column: 4, row: 1),
    },
  );

  static final _horizontalBeam = PixelTileVariants.sequence([
    atlas.region('timber_horizontal_start'),
    atlas.region('timber_horizontal_middle'),
    atlas.region('timber_horizontal_end'),
  ], sequenceAxis: PixelTileSequenceAxis.horizontal);

  static final _verticalBeam = PixelTileVariants.sequence([
    atlas.region('timber_vertical_start'),
    atlas.region('timber_vertical_middle'),
    atlas.region('timber_vertical_end'),
  ], sequenceAxis: PixelTileSequenceAxis.vertical);

  static final woodPanel = PixelPanelRecipe(
    topLeft: atlas.region('timber_diagonal_b'),
    top: _horizontalBeam,
    topRight: atlas.region('timber_diagonal_a'),
    left: _verticalBeam,
    fill: PixelTileVariants.single(atlas.region('brick_fill')),
    right: _verticalBeam,
    bottomLeft: atlas.region('timber_diagonal_b'),
    bottom: _horizontalBeam,
    bottomRight: atlas.region('timber_diagonal_a'),
    topLeftTransform: const PixelTileTransform(flipVertically: true),
    topRightTransform: const PixelTileTransform(flipVertically: true),
    rightTransform: const PixelTileTransform(flipHorizontally: true),
    bottomTransform: const PixelTileTransform(flipVertically: true),
    solidFillColor: const Color(0xFF2B2224),
  );

  static final stoneInset = PixelPanelRecipe(
    topLeft: atlas.region('timber_diagonal_b'),
    top: _horizontalBeam,
    topRight: atlas.region('timber_diagonal_a'),
    left: _verticalBeam,
    fill: PixelTileVariants.single(atlas.region('stone_fill')),
    right: _verticalBeam,
    bottomLeft: atlas.region('timber_diagonal_b'),
    bottom: _horizontalBeam,
    bottomRight: atlas.region('timber_diagonal_a'),
    topLeftTransform: const PixelTileTransform(flipVertically: true),
    topRightTransform: const PixelTileTransform(flipVertically: true),
    rightTransform: const PixelTileTransform(flipHorizontally: true),
    bottomTransform: const PixelTileTransform(flipVertically: true),
    solidFillColor: const Color(0xFF684536),
  );

  static final brickJointPanel = PixelPanelRecipe(
    topLeft: atlas.region('brick_corner'),
    top: _horizontalBeam,
    topRight: atlas.region('brick_corner'),
    left: _verticalBeam,
    fill: PixelTileVariants.single(atlas.region('brick_fill')),
    right: _verticalBeam,
    bottomLeft: atlas.region('brick_corner'),
    bottom: _horizontalBeam,
    bottomRight: atlas.region('brick_corner'),
    rightTransform: const PixelTileTransform(flipHorizontally: true),
    bottomTransform: const PixelTileTransform(flipVertically: true),
    solidFillColor: const Color(0xFF35272A),
  );

  static final mediumPanel = PixelPanelRecipe.ninePatch(
    3,
    0,
    const Color(0xFF2B2224),
  );

  static final theme = PixelUiThemeData(
    atlas: atlas,
    palette: const PixelUiPalette(
      canvas: Color(0xFF171315),
      surfaceFallback: Color(0xFF5B342D),
      ink: Color(0xFFFFE0A6),
      mutedInk: Color(0xFFC79A72),
      accent: Color(0xFF76A8D8),
      energy: Color(0xFF8D78D4),
      health: Color(0xFF62B85B),
      damage: Color(0xFFD95043),
      gold: Color(0xFFF5BE45),
    ),
    surfaces: {
      PixelSurfaceRole.panel: woodPanel,
      PixelSurfaceRole.inset: mediumPanel,
      PixelSurfaceRole.button: woodPanel,
      PixelSurfaceRole.dialog: stoneInset,
    },
  );
}
