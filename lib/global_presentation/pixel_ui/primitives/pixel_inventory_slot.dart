import 'package:flutter/material.dart';

import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_ui_theme.dart';
import 'pixel_control_tone.dart';

enum PixelInventorySlotState {
  empty,
  occupied,
  selected,
  validDrop,
  invalidDrop,
  disabled,
}

class PixelInventorySlot extends StatelessWidget {
  const PixelInventorySlot({
    super.key,
    required this.child,
    this.columns = 4,
    this.rows = 4,
    this.state = PixelInventorySlotState.empty,
    this.onTap,
    this.semanticLabel,
    this.seed = 0,
  }) : assert(columns >= 2),
       assert(rows >= 2);

  final Widget child;
  final int columns;
  final int rows;
  final PixelInventorySlotState state;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final disabled = state == PixelInventorySlotState.disabled;
    final tone = switch (state) {
      PixelInventorySlotState.validDrop => PixelControlTone.positive,
      PixelInventorySlotState.invalidDrop => PixelControlTone.danger,
      PixelInventorySlotState.selected => PixelControlTone.accent,
      _ => PixelControlTone.neutral,
    };
    final emphasized = switch (state) {
      PixelInventorySlotState.selected ||
      PixelInventorySlotState.validDrop ||
      PixelInventorySlotState.invalidDrop => true,
      _ => false,
    };
    final resolvedLabel = semanticLabel ?? 'Inventory slot, ${state.name}';

    Widget result = PixelPanel(
      gridSize: PixelGridSize(columns: columns, rows: rows),
      role: PixelSurfaceRole.inset,
      seed: seed,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(5),
            child: Opacity(opacity: disabled ? 0.35 : 1, child: child),
          ),
          PixelStateOverlay(
            tone: tone,
            emphasized: emphasized,
            disabled: disabled,
          ),
          if (state == PixelInventorySlotState.empty)
            Center(
              child: Text(
                '·',
                style: TextStyle(
                  color: palette.mutedInk.withValues(alpha: 0.6),
                  fontFamily: 'monospace',
                  fontSize: 18,
                  height: 1,
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
      selected: state == PixelInventorySlotState.selected,
      label: resolvedLabel,
      onTap: onTap != null && !disabled ? onTap : null,
      excludeSemantics: true,
      child: result,
    );
  }
}
