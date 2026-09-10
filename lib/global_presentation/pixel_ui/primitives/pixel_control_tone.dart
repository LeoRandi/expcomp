import 'package:flutter/material.dart';

import '../pixel_panel.dart';
import '../pixel_ui_theme.dart';

enum PixelControlTone { neutral, accent, positive, danger, energy, gold }

extension PixelControlToneColor on PixelControlTone {
  Color resolve(PixelUiPalette palette) {
    return switch (this) {
      PixelControlTone.neutral => palette.mutedInk,
      PixelControlTone.accent => palette.accent,
      PixelControlTone.positive => palette.health,
      PixelControlTone.danger => palette.damage,
      PixelControlTone.energy => palette.energy,
      PixelControlTone.gold => palette.gold,
    };
  }
}

class PixelStateOverlay extends StatelessWidget {
  const PixelStateOverlay({
    super.key,
    this.tileExtent,
    this.tone = PixelControlTone.neutral,
    this.emphasized = false,
    this.pressed = false,
    this.disabled = false,
  });

  final double? tileExtent;
  final PixelControlTone tone;
  final bool emphasized;
  final bool pressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final stateColor = tone.resolve(palette);
    final borderColor = disabled
        ? palette.mutedInk.withValues(alpha: 0.45)
        : stateColor.withValues(alpha: emphasized ? 1 : 0.72);
    final fillColor = disabled
        ? palette.canvas.withValues(alpha: 0.62)
        : stateColor.withValues(
            alpha: pressed
                ? 0.28
                : emphasized
                ? 0.14
                : 0,
          );

    return IgnorePointer(
      child: PixelPanelInterior(
        tileExtent: tileExtent,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(
              color: borderColor,
              width: emphasized || pressed ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}
