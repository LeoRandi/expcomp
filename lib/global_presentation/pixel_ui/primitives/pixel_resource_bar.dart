import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_ui_theme.dart';
import 'pixel_control_tone.dart';

class PixelResourceBar extends StatelessWidget {
  const PixelResourceBar({
    super.key,
    required this.value,
    required this.maximum,
    this.label,
    this.columns = 14,
    this.rows = 3,
    this.tone = PixelControlTone.positive,
    this.showValues = true,
    this.semanticLabel,
    this.tileExtent,
    this.previewValue,
  }) : assert(maximum > 0),
       assert(columns != null && columns >= 4),
       assert(rows >= 2);

  const PixelResourceBar.expanded({
    super.key,
    required this.value,
    required this.maximum,
    this.label,
    this.rows = 3,
    this.tone = PixelControlTone.positive,
    this.showValues = true,
    this.semanticLabel,
    this.tileExtent,
    this.previewValue,
  }) : assert(maximum > 0),
       assert(rows >= 2),
       columns = null;

  final double value;
  final double maximum;
  final String? label;
  final int? columns;
  final int rows;
  final PixelControlTone tone;
  final bool showValues;
  final String? semanticLabel;
  final double? tileExtent;

  /// Hypothetical remaining value; the real value is retained until resolution.
  final double? previewValue;

  bool get expanded => columns == null;

  double get fraction => (value / maximum).clamp(0, 1);

  String get valueText =>
      '${_formatValue((previewValue ?? value).clamp(0, maximum))}/${_formatValue(maximum)}';

  static String _formatValue(num value) {
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final fillColor = tone.resolve(palette);
    final spokenLabel = semanticLabel ?? label ?? 'Resource';
    final showReadout = label != null || showValues;

    Widget readout() {
      return Text(
        [
          if (label != null) label!.toUpperCase(),
          if (showValues) valueText,
        ].join('  '),
        overflow: TextOverflow.clip,
        softWrap: false,
        style: TextStyle(
          color: palette.ink,
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          height: 1,
          shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
        ),
      );
    }

    final track = _PixelResourceTrack(
      fraction: fraction,
      previewFraction: previewValue == null
          ? null
          : (previewValue! / maximum).clamp(0, fraction),
      backgroundColor: palette.canvas,
      borderColor: palette.ink,
      fillColor: fillColor,
    );

    if (expanded) {
      final frameTileExtent =
          tileExtent ??
          PixelUiThemeData.maybeOf(context)?.tileExtent ??
          PixelGrid.defaultTileExtent;
      final panel = Stack(
        fit: StackFit.expand,
        children: [
          PixelPanel.expanded(
            role: PixelSurfaceRole.inset,
            tileExtent: frameTileExtent,
            seed: spokenLabel.hashCode,
            child: const SizedBox.shrink(),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final horizontalInset = math.min(
                frameTileExtent,
                constraints.maxWidth / 2,
              );
              final verticalInset = math.min(
                frameTileExtent,
                constraints.maxHeight / 2,
              );
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalInset,
                  vertical: verticalInset,
                ),
                child: track,
              );
            },
          ),
          if (showReadout) Center(child: readout()),
        ],
      );

      return Semantics(
        container: true,
        label: spokenLabel,
        value: valueText,
        excludeSemantics: true,
        child: panel,
      );
    }

    final content = PixelPanelInterior(
      tileExtent: tileExtent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          track,
          if (showReadout) Center(child: readout()),
        ],
      ),
    );
    final panel = PixelPanel(
      gridSize: PixelGridSize(columns: columns!, rows: rows),
      role: PixelSurfaceRole.inset,
      tileExtent: tileExtent,
      seed: spokenLabel.hashCode,
      child: content,
    );

    return Semantics(
      container: true,
      label: spokenLabel,
      value: valueText,
      excludeSemantics: true,
      child: panel,
    );
  }
}

class _PixelResourceTrack extends StatelessWidget {
  const _PixelResourceTrack({
    required this.fraction,
    this.previewFraction,
    required this.backgroundColor,
    required this.borderColor,
    required this.fillColor,
  });

  final double fraction;
  final double? previewFraction;
  final Color backgroundColor;
  final Color borderColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = (constraints.maxWidth * fraction).floorToDouble();
            final remainingWidth =
                (constraints.maxWidth * (previewFraction ?? fraction))
                    .floorToDouble();
            return Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fillWidth,
                  child: ColoredBox(color: fillColor),
                ),
                if (previewFraction != null && remainingWidth < fillWidth)
                  Positioned(
                    left: remainingWidth,
                    top: 0,
                    bottom: 0,
                    width: fillWidth - remainingWidth,
                    child: const PixelDamagePreview(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The segment that would be lost flashes without modifying actual health.
class PixelDamagePreview extends StatefulWidget {
  const PixelDamagePreview({super.key});
  @override
  State<PixelDamagePreview> createState() => _PixelDamagePreviewState();
}

class _PixelDamagePreviewState extends State<PixelDamagePreview>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 0;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => ColoredBox(
      color: Color.lerp(Colors.red, Colors.white, _controller.value)!,
    ),
  );
}
