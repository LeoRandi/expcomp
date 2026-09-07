import 'package:flutter/material.dart';

import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_ui_theme.dart';
import 'pixel_control_tone.dart';

enum PixelItemTileState { idle, selected, dragging, disabled }

class PixelItemTile extends StatelessWidget {
  const PixelItemTile({
    super.key,
    required this.label,
    required this.art,
    this.gridSize = const PixelGridSize(columns: 4, rows: 4),
    this.state = PixelItemTileState.idle,
    this.tone = PixelControlTone.accent,
    this.quantity,
    this.onTap,
    this.seed = 0,
  }) : assert(quantity == null || quantity > 0);

  final String label;
  final Widget art;
  final PixelGridSize gridSize;
  final PixelItemTileState state;
  final PixelControlTone tone;
  final int? quantity;
  final VoidCallback? onTap;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final disabled = state == PixelItemTileState.disabled;
    final selected = state == PixelItemTileState.selected;
    final dragging = state == PixelItemTileState.dragging;

    Widget result = PixelPanel(
      gridSize: gridSize,
      role: PixelSurfaceRole.inset,
      seed: seed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: Opacity(
              opacity: disabled
                  ? 0.28
                  : dragging
                  ? 0.58
                  : 1,
              child: Center(child: art),
            ),
          ),
          PixelStateOverlay(
            tone: tone,
            emphasized: selected || dragging,
            pressed: dragging,
            disabled: disabled,
          ),
          if (quantity case final quantity?)
            Positioned(
              right: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.canvas,
                  border: Border.all(color: palette.ink),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 1,
                  ),
                  child: Text(
                    '×$quantity',
                    style: TextStyle(
                      color: palette.ink,
                      fontFamily: 'monospace',
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (onTap != null && !disabled) {
      result = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: result,
      );
    }

    return Semantics(
      container: true,
      button: onTap != null && !disabled,
      enabled: !disabled,
      selected: selected,
      label: label,
      value: quantity == null ? null : 'Quantity $quantity',
      onTap: onTap != null && !disabled ? onTap : null,
      excludeSemantics: true,
      child: result,
    );
  }
}
