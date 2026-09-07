import 'dart:ui';

import 'package:flutter/material.dart';

import 'pixel_atlas.dart';
import 'pixel_grid.dart';
import 'pixel_panel_recipe.dart';

enum PixelSurfaceRole { panel, inset, button, dialog }

@immutable
class PixelUiPalette {
  const PixelUiPalette({
    required this.canvas,
    required this.surfaceFallback,
    required this.ink,
    required this.mutedInk,
    required this.accent,
    required this.energy,
    required this.health,
    required this.damage,
    required this.gold,
  });

  final Color canvas;
  final Color surfaceFallback;
  final Color ink;
  final Color mutedInk;
  final Color accent;
  final Color energy;
  final Color health;
  final Color damage;
  final Color gold;

  static PixelUiPalette lerp(
    PixelUiPalette first,
    PixelUiPalette second,
    double t,
  ) {
    return PixelUiPalette(
      canvas: Color.lerp(first.canvas, second.canvas, t)!,
      surfaceFallback: Color.lerp(
        first.surfaceFallback,
        second.surfaceFallback,
        t,
      )!,
      ink: Color.lerp(first.ink, second.ink, t)!,
      mutedInk: Color.lerp(first.mutedInk, second.mutedInk, t)!,
      accent: Color.lerp(first.accent, second.accent, t)!,
      energy: Color.lerp(first.energy, second.energy, t)!,
      health: Color.lerp(first.health, second.health, t)!,
      damage: Color.lerp(first.damage, second.damage, t)!,
      gold: Color.lerp(first.gold, second.gold, t)!,
    );
  }
}

@immutable
class PixelUiThemeData extends ThemeExtension<PixelUiThemeData> {
  PixelUiThemeData({
    required this.atlas,
    required this.palette,
    required Map<PixelSurfaceRole, PixelPanelRecipe> surfaces,
    this.tileExtent = PixelGrid.defaultTileExtent,
  }) : assert(tileExtent > 0),
       surfaces = Map.unmodifiable(surfaces);

  final PixelAtlasDefinition atlas;
  final PixelUiPalette palette;
  final Map<PixelSurfaceRole, PixelPanelRecipe> surfaces;
  final double tileExtent;

  static PixelUiThemeData? maybeOf(BuildContext context) {
    return Theme.of(context).extension<PixelUiThemeData>();
  }

  static PixelUiThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    assert(theme != null, 'No PixelUiThemeData is installed in ThemeData.');
    return theme!;
  }

  PixelPanelRecipe surface(PixelSurfaceRole role) {
    final recipe = surfaces[role];
    if (recipe == null) {
      throw StateError('No pixel surface recipe is registered for $role.');
    }
    return recipe;
  }

  @override
  PixelUiThemeData copyWith({
    PixelAtlasDefinition? atlas,
    PixelUiPalette? palette,
    Map<PixelSurfaceRole, PixelPanelRecipe>? surfaces,
    double? tileExtent,
  }) {
    return PixelUiThemeData(
      atlas: atlas ?? this.atlas,
      palette: palette ?? this.palette,
      surfaces: surfaces ?? this.surfaces,
      tileExtent: tileExtent ?? this.tileExtent,
    );
  }

  @override
  PixelUiThemeData lerp(
    covariant ThemeExtension<PixelUiThemeData>? other,
    double t,
  ) {
    if (other is! PixelUiThemeData) {
      return this;
    }

    return PixelUiThemeData(
      atlas: t < 0.5 ? atlas : other.atlas,
      palette: PixelUiPalette.lerp(palette, other.palette, t),
      surfaces: t < 0.5 ? surfaces : other.surfaces,
      tileExtent: lerpDouble(tileExtent, other.tileExtent, t)!,
    );
  }
}
