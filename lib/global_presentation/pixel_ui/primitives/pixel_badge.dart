import 'package:flutter/material.dart';

import '../pixel_atlas.dart';
import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';
import 'pixel_control_tone.dart';

class PixelBadge extends StatelessWidget {
  const PixelBadge({
    super.key,
    required this.label,
    this.leading,
    this.columns = 5,
    this.rows = 2,
    this.tone = PixelControlTone.neutral,
    this.semanticLabel,
    this.atlas,
    this.recipe,
  }) : assert(columns >= 2),
       assert(rows >= 2);

  final String label;
  final Widget? leading;
  final int columns;
  final int rows;
  final PixelControlTone tone;
  final String? semanticLabel;
  final PixelAtlasDefinition? atlas;
  final PixelPanelRecipe? recipe;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final toneColor = tone.resolve(palette);

    return Semantics(
      container: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: PixelPanel(
        gridSize: PixelGridSize(columns: columns, rows: rows),
        role: PixelSurfaceRole.inset,
        atlas: atlas,
        recipe: recipe,
        seed: label.hashCode,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PixelPanelInterior(
              child: ColoredBox(color: toneColor.withValues(alpha: 0.16)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading case final leading?) ...[
                    leading,
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        color: toneColor,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        shadows: const [
                          Shadow(color: Colors.black, offset: Offset(1, 1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
