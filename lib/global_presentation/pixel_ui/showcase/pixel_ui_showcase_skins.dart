import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_panel_recipe.dart';
import '../themes/falobris_ui.dart';
import '../themes/neon_bulkhead_ui.dart';
import '../themes/raida_ui.dart';
import '../themes/sundered_keep_ui.dart';
import '../themes/undiria_ui.dart';

@immutable
class PixelUiShowcaseSkin {
  const PixelUiShowcaseSkin({
    required this.name,
    required this.concept,
    required this.description,
    required this.atlas,
    required this.recipe,
    required this.accent,
  });

  final String name;
  final String concept;
  final String description;
  final PixelAtlasDefinition atlas;
  final PixelPanelRecipe recipe;
  final Color accent;
}

/// Experimental skins plus promoted skins retained for visual comparison.
abstract final class PixelUiShowcaseSkins {
  static const assetDirectory = 'assets/pixel_ui/showcase';

  static final sciFiAtlas = NeonBulkheadUi.atlas;

  static final sciFiRecipe = NeonBulkheadUi.panel;

  static final raidaAtlas = RaidaUi.atlas;

  static final raidaRecipe = RaidaUi.panel;

  static final caveAtlas = UndiriaUi.atlas;

  static final caveRecipe = UndiriaUi.panel;

  static final skins = <PixelUiShowcaseSkin>[
    PixelUiShowcaseSkin(
      name: 'Neon Bulkhead',
      concept: 'SCI-FI CONSOLE',
      description: 'A true 3×3 magenta frame with a quiet violet center.',
      atlas: sciFiAtlas,
      recipe: sciFiRecipe,
      accent: const Color(0xFFFF68C7),
    ),
    PixelUiShowcaseSkin(
      name: 'Raida War-Palisade',
      concept: 'ORC STRONGHOLD',
      description: 'Mossy stake joints and rough capped beams over dark earth.',
      atlas: raidaAtlas,
      recipe: raidaRecipe,
      accent: const Color(0xFF8DBA3A),
    ),
    PixelUiShowcaseSkin(
      name: 'Cavern Blocks',
      concept: 'LOOT CONTAINER',
      description: 'Warm rock blocks suited to storage and reward panels.',
      atlas: caveAtlas,
      recipe: caveRecipe,
      accent: const Color(0xFFD4867D),
    ),
    PixelUiShowcaseSkin(
      name: 'Falobris Coast',
      concept: 'TIDAL ISLAND',
      description: 'Foamy shallows and sand enclosing a grassy coast.',
      atlas: FalobrisUi.atlas,
      recipe: FalobrisUi.panel,
      accent: const Color(0xFFFFD96D),
    ),
    PixelUiShowcaseSkin(
      name: 'Brick-Joint Timber',
      concept: 'WARNING CARD',
      description: 'The temporary solid-corner treatment kept as an option.',
      atlas: SunderedKeepUi.atlas,
      recipe: SunderedKeepUi.brickJointPanel,
      accent: const Color(0xFFF5BE45),
    ),
  ];
}
