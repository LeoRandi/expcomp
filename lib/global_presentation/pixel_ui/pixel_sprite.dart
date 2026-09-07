import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'pixel_atlas.dart';
import 'pixel_grid.dart';
import 'pixel_ui_theme.dart';

class PixelSprite extends StatelessWidget {
  const PixelSprite({
    super.key,
    required this.region,
    this.atlas,
    this.tileExtent,
    this.width,
    this.height,
    this.flipHorizontally = false,
    this.flipVertically = false,
    this.opacity = 1,
    this.tint,
    this.semanticLabel,
    this.placeholder = const SizedBox.shrink(),
  }) : assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(opacity >= 0 && opacity <= 1);

  final PixelAtlasRegion region;
  final PixelAtlasDefinition? atlas;
  final double? tileExtent;
  final double? width;
  final double? height;
  final bool flipHorizontally;
  final bool flipVertically;
  final double opacity;
  final Color? tint;
  final String? semanticLabel;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    final pixelTheme = PixelUiThemeData.maybeOf(context);
    final resolvedAtlas = atlas ?? pixelTheme?.atlas;
    final resolvedTileExtent =
        tileExtent ?? pixelTheme?.tileExtent ?? PixelGrid.defaultTileExtent;
    assert(
      resolvedAtlas != null,
      'PixelSprite needs an atlas or an installed PixelUiThemeData.',
    );

    final resolvedWidth = width ?? region.widthInTiles * resolvedTileExtent;
    final resolvedHeight = height ?? region.heightInTiles * resolvedTileExtent;
    Widget sprite = SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: PixelAtlasBuilder(
        atlas: resolvedAtlas!,
        builder: (context, image, error) {
          if (image == null) {
            return placeholder;
          }
          return RepaintBoundary(
            child: CustomPaint(
              painter: PixelSpritePainter(
                image: image,
                atlas: resolvedAtlas,
                region: region,
                flipHorizontally: flipHorizontally,
                flipVertically: flipVertically,
                opacity: opacity,
                tint: tint,
              ),
            ),
          );
        },
      ),
    );

    if (semanticLabel case final label?) {
      sprite = Semantics(image: true, label: label, child: sprite);
    } else {
      sprite = ExcludeSemantics(child: sprite);
    }
    return sprite;
  }
}

class PixelSpritePainter extends CustomPainter {
  const PixelSpritePainter({
    required this.image,
    required this.atlas,
    required this.region,
    required this.flipHorizontally,
    required this.flipVertically,
    required this.opacity,
    required this.tint,
  });

  final ui.Image image;
  final PixelAtlasDefinition atlas;
  final PixelAtlasRegion region;
  final bool flipHorizontally;
  final bool flipVertically;
  final double opacity;
  final Color? tint;

  @override
  void paint(Canvas canvas, Size size) {
    final destination = Offset.zero & size;
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    if (tint case final color?) {
      paint.colorFilter = ColorFilter.mode(color, BlendMode.srcATop);
    }

    if (flipHorizontally || flipVertically) {
      canvas.save();
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(flipHorizontally ? -1 : 1, flipVertically ? -1 : 1);
      canvas.translate(-size.width / 2, -size.height / 2);
    }

    canvas.drawImageRect(
      image,
      region.sourceRect(atlas.sourceTileExtent),
      destination,
      paint,
    );

    if (flipHorizontally || flipVertically) {
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PixelSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.region != region ||
        oldDelegate.flipHorizontally != flipHorizontally ||
        oldDelegate.flipVertically != flipVertically ||
        oldDelegate.opacity != opacity ||
        oldDelegate.tint != tint;
  }
}
