import 'package:flutter/material.dart';

import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_ui_theme.dart';
import 'pixel_button.dart';
import 'pixel_control_tone.dart';
import 'pixel_text_plate.dart';

class PixelDialogFrame extends StatelessWidget {
  const PixelDialogFrame({
    super.key,
    required this.title,
    required this.child,
    this.gridSize = const PixelGridSize(columns: 30, rows: 18),
    this.actions = const [],
    this.onClose,
    this.closeButtonKey,
    this.semanticLabel,
    this.seed = 0,
  });

  final String title;
  final Widget child;
  final PixelGridSize gridSize;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final Key? closeButtonKey;
  final String? semanticLabel;
  final int seed;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;

    return Semantics(
      container: true,
      scopesRoute: true,
      namesRoute: true,
      label: semanticLabel ?? title,
      explicitChildNodes: true,
      child: PixelPanel(
        gridSize: gridSize,
        role: PixelSurfaceRole.dialog,
        seed: seed,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 32,
              child: Row(
                children: [
                  Expanded(
                    child: PixelTextPlate(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      showBorder: false,
                      child: Text(
                        title.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: palette.ink,
                          fontFamily: 'monospace',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                  if (onClose != null)
                    PixelButton(
                      key: closeButtonKey,
                      label: '×',
                      semanticLabel: 'Close $title',
                      columns: 3,
                      rows: 2,
                      tone: PixelControlTone.danger,
                      onPressed: onClose,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.canvas.withValues(alpha: 0.78),
                  border: Border.all(color: palette.mutedInk, width: 2),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: DefaultTextStyle.merge(
                    style: TextStyle(
                      color: palette.ink,
                      fontFamily: 'monospace',
                      fontSize: 12,
                      height: 1.35,
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var index = 0; index < actions.length; index += 1) ...[
                      if (index > 0) const SizedBox(width: 8),
                      actions[index],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
