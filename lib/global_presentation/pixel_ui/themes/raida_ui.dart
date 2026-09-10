import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';

abstract final class RaidaAssets {
  static const tileAtlas = 'assets/pixel_ui/showcase/raida_palisade_atlas.png';
}

/// Moss-bound war-palisade used by items originating in Raida.
abstract final class RaidaUi {
  static final atlas = PixelAtlasDefinition(
    assetPath: RaidaAssets.tileAtlas,
    regions: const {
      'stake_joint': PixelAtlasRegion(column: 0, row: 0),
      'beam_start': PixelAtlasRegion(column: 1, row: 0),
      'beam_middle': PixelAtlasRegion(column: 2, row: 0),
      'beam_end': PixelAtlasRegion(column: 0, row: 1),
      'earth_a': PixelAtlasRegion(column: 1, row: 1),
      'earth_b': PixelAtlasRegion(column: 2, row: 1),
      'vine_wall': PixelAtlasRegion(column: 0, row: 2),
      'tall_stakes': PixelAtlasRegion(column: 1, row: 2),
      'short_stakes': PixelAtlasRegion(column: 2, row: 2),
    },
  );

  static final _horizontalBeam = PixelTileVariants.sequence([
    atlas.region('beam_start'),
    atlas.region('beam_middle'),
    atlas.region('beam_end'),
  ], sequenceAxis: PixelTileSequenceAxis.horizontal);

  static final _verticalBeam = PixelTileVariants.sequence([
    atlas.region('beam_start'),
    atlas.region('beam_middle'),
    atlas.region('beam_end'),
  ], sequenceAxis: PixelTileSequenceAxis.vertical);

  static final panel = PixelPanelRecipe(
    topLeft: atlas.region('stake_joint'),
    top: _horizontalBeam,
    topRight: atlas.region('stake_joint'),
    left: _verticalBeam,
    fill: PixelTileVariants([atlas.region('earth_a'), atlas.region('earth_b')]),
    right: _verticalBeam,
    bottomLeft: atlas.region('stake_joint'),
    bottom: _horizontalBeam,
    bottomRight: atlas.region('stake_joint'),
    topRightTransform: const PixelTileTransform(flipHorizontally: true),
    leftTransform: const PixelTileTransform(quarterTurns: 1),
    rightTransform: const PixelTileTransform(quarterTurns: 1),
    bottomLeftTransform: const PixelTileTransform(flipVertically: true),
    bottomTransform: const PixelTileTransform(flipVertically: true),
    bottomRightTransform: const PixelTileTransform(
      flipHorizontally: true,
      flipVertically: true,
    ),
    solidFillColor: const Color(0xFF19150D),
  );

  static final mediumPanel = PixelPanelRecipe(
    topLeft: atlas.region('earth_a'),
    topRight: atlas.region('earth_b'),
    bottomLeft: atlas.region('earth_b'),
    bottomRight: atlas.region('earth_a'),
    top: PixelTileVariants.single(atlas.region('short_stakes')),
    bottom: PixelTileVariants.single(atlas.region('short_stakes')),
    left: PixelTileVariants.single(atlas.region('vine_wall')),
    right: PixelTileVariants.single(atlas.region('vine_wall')),
    fill: PixelTileVariants.single(atlas.region('earth_a')),
    bottomTransform: const PixelTileTransform(flipVertically: true),
    solidFillColor: const Color(0xFF19150D),
  );

  static final theme = PixelUiThemeData(
    atlas: atlas,
    palette: const PixelUiPalette(
      canvas: Color(0xFF111008),
      surfaceFallback: Color(0xFF19150D),
      ink: Color(0xFFF3E8BD),
      mutedInk: Color(0xFFA99A69),
      accent: Color(0xFF8DBA3A),
      energy: Color(0xFF72B9A4),
      health: Color(0xFF76C85B),
      damage: Color(0xFFE15D43),
      gold: Color(0xFFE1B74E),
    ),
    surfaces: {
      PixelSurfaceRole.panel: panel,
      PixelSurfaceRole.inset: mediumPanel,
      PixelSurfaceRole.button: panel,
      PixelSurfaceRole.dialog: panel,
    },
  );
}
