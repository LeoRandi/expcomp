import 'package:flutter/material.dart';

import '../pixel_ui_theme.dart';

/// A crisp translucent backdrop for text placed over detailed pixel art.
///
/// Only the backdrop is translucent. The child and its text stay fully opaque.
class PixelTextPlate extends StatelessWidget {
  const PixelTextPlate({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    this.backgroundOpacity = 0.55,
    this.borderOpacity = 0.42,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = true,
    this.textStyle,
    this.semanticLabel,
  }) : assert(backgroundOpacity >= 0 && backgroundOpacity <= 1),
       assert(borderOpacity >= 0 && borderOpacity <= 1);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double backgroundOpacity;
  final double borderOpacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showBorder;
  final TextStyle? textStyle;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    final resolvedBackground = backgroundColor ?? palette.canvas;
    final resolvedBorder = borderColor ?? palette.mutedInk;
    final resolvedTextStyle = TextStyle(
      color: palette.ink,
      fontFamily: 'monospace',
      height: 1.2,
      shadows: const [Shadow(color: Colors.black, offset: Offset(1, 1))],
    ).merge(textStyle);

    Widget plate = DecoratedBox(
      decoration: BoxDecoration(
        color: resolvedBackground.withValues(alpha: backgroundOpacity),
        border: showBorder
            ? Border.all(color: resolvedBorder.withValues(alpha: borderOpacity))
            : null,
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(style: resolvedTextStyle, child: child),
      ),
    );

    if (semanticLabel case final label?) {
      plate = Semantics(
        container: true,
        label: label,
        excludeSemantics: true,
        child: plate,
      );
    }
    return plate;
  }
}
