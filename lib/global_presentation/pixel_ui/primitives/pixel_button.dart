import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pixel_atlas.dart';
import '../pixel_grid.dart';
import '../pixel_ui_metrics.dart';
import '../pixel_panel.dart';
import '../pixel_panel_recipe.dart';
import '../pixel_ui_theme.dart';
import 'pixel_control_tone.dart';

class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.columns = 8,
    this.rows = 3,
    this.tone = PixelControlTone.neutral,
    this.selected = false,
    this.autofocus = false,
    this.semanticLabel,
    this.atlas,
    this.recipe,
    this.expandToFill = false,
    this.tileExtent = PixelUiMetrics.largeBorder,
    this.fontSize = PixelUiMetrics.body,
    this.role = PixelSurfaceRole.button,
  }) : assert(columns >= 2),
       assert(rows >= 2);

  final double tileExtent;
  final double fontSize;
  final PixelSurfaceRole role;
  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final int columns;
  final int rows;
  final PixelControlTone tone;
  final bool selected;
  final bool autofocus;
  final String? semanticLabel;
  final PixelAtlasDefinition? atlas;
  final PixelPanelRecipe? recipe;

  /// Tile the frame across the space supplied by the parent.
  final bool expandToFill;

  bool get enabled => onPressed != null;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  void _activate() {
    if (widget.enabled) {
      widget.onPressed!();
    }
  }

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final emphasized = widget.selected || _hovered || _focused;
    final labelColor = widget.enabled ? palette.ink : palette.mutedInk;

    final body = Semantics(
      button: true,
      enabled: widget.enabled,
      selected: widget.selected,
      label: widget.semanticLabel ?? widget.label,
      onTap: widget.enabled ? _activate : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        autofocus: widget.autofocus,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _activate : null,
          onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
          onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
          onTapCancel: widget.enabled ? () => _setPressed(false) : null,
          child: PixelPanel(
            gridSize: widget.expandToFill
                ? null
                : PixelGridSize(columns: widget.columns, rows: widget.rows),
            role: widget.role,
            tileExtent: widget.tileExtent,
            atlas: widget.atlas,
            recipe: widget.recipe,
            seed: widget.label.hashCode,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PixelStateOverlay(
                  tone: widget.tone,
                  tileExtent: widget.tileExtent,
                  emphasized: emphasized,
                  pressed: _pressed,
                  disabled: !widget.enabled,
                ),
                Transform.translate(
                  offset: _pressed ? const Offset(0, 2) : Offset.zero,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.tileExtent + 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leading case final leading?) ...[
                          leading,
                          if (widget.label.isNotEmpty) const SizedBox(width: 4),
                        ],
                        if (widget.label.isNotEmpty)
                          Flexible(
                            child: Text(
                              widget.label.toUpperCase(),
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                color: labelColor,
                                fontFamily: 'monospace',
                                fontSize: widget.fontSize,
                                fontWeight: FontWeight.w900,
                                height: 1,
                                letterSpacing: 0.6,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(1, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final unit = widget.tileExtent;
        final desiredWidth = widget.expandToFill && constraints.hasBoundedWidth
            ? constraints.maxWidth
            : widget.columns * unit;
        final desiredHeight =
            widget.expandToFill && constraints.hasBoundedHeight
            ? constraints.maxHeight
            : widget.rows * unit;
        final width = PixelGrid.snapDown(
          desiredWidth.clamp(0, constraints.maxWidth),
          tileExtent: unit,
        );
        final height = PixelGrid.snapDown(
          desiredHeight.clamp(0, constraints.maxHeight),
          tileExtent: unit,
        );
        return Align(
          widthFactor: 1,
          heightFactor: 1,
          child: SizedBox(width: width, height: height, child: body),
        );
      },
    );
  }
}
