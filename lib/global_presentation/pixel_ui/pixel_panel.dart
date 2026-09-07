import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pixel_atlas.dart';
import 'pixel_grid.dart';
import 'pixel_panel_recipe.dart';
import 'pixel_ui_theme.dart';

class PixelPanel extends StatelessWidget {
  const PixelPanel({
    super.key,
    required this.gridSize,
    required this.child,
    this.role = PixelSurfaceRole.panel,
    this.atlas,
    this.recipe,
    this.tileExtent,
    this.padding = EdgeInsets.zero,
    this.seed = 0,
    this.semanticLabel,
    this.fallbackColor,
  });

  const PixelPanel.expanded({
    super.key,
    required this.child,
    this.role = PixelSurfaceRole.panel,
    this.atlas,
    this.recipe,
    this.tileExtent,
    this.padding = EdgeInsets.zero,
    this.seed = 0,
    this.semanticLabel,
    this.fallbackColor,
  }) : gridSize = null;

  final PixelGridSize? gridSize;
  final Widget child;
  final PixelSurfaceRole role;
  final PixelAtlasDefinition? atlas;
  final PixelPanelRecipe? recipe;
  final double? tileExtent;
  final EdgeInsetsGeometry padding;
  final int seed;
  final String? semanticLabel;
  final Color? fallbackColor;

  bool get expanded => gridSize == null;

  @override
  Widget build(BuildContext context) {
    assert(
      expanded || gridSize!.columns >= 2,
      'PixelPanel needs at least two columns.',
    );
    assert(
      expanded || gridSize!.rows >= 2,
      'PixelPanel needs at least two rows.',
    );
    final pixelTheme = PixelUiThemeData.maybeOf(context);
    final resolvedAtlas = atlas ?? pixelTheme?.atlas;
    final resolvedRecipe = recipe ?? pixelTheme?.surface(role);
    final resolvedTileExtent =
        tileExtent ?? pixelTheme?.tileExtent ?? PixelGrid.defaultTileExtent;
    final resolvedFallback =
        fallbackColor ??
        pixelTheme?.palette.surfaceFallback ??
        Colors.transparent;

    assert(
      resolvedAtlas != null,
      'PixelPanel needs an atlas or an installed PixelUiThemeData.',
    );
    assert(
      resolvedRecipe != null,
      'PixelPanel needs a recipe or an installed PixelUiThemeData.',
    );

    final logicalSize = gridSize?.logicalSize(resolvedTileExtent);
    final panelBody = PixelAtlasBuilder(
      atlas: resolvedAtlas!,
      builder: (context, image, error) {
        return Stack(
          fit: StackFit.expand,
          children: [
            PixelPanelInterior(
              tileExtent: resolvedTileExtent,
              child: ColoredBox(color: resolvedFallback),
            ),
            if (image != null)
              RepaintBoundary(
                child: CustomPaint(
                  isComplex: true,
                  willChange: false,
                  painter: expanded
                      ? PixelPanelPainter.expanded(
                          image: image,
                          atlas: resolvedAtlas,
                          recipe: resolvedRecipe!,
                          tileExtent: resolvedTileExtent,
                          seed: seed,
                        )
                      : PixelPanelPainter(
                          image: image,
                          atlas: resolvedAtlas,
                          recipe: resolvedRecipe!,
                          gridSize: gridSize!,
                          tileExtent: resolvedTileExtent,
                          seed: seed,
                        ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        );
      },
    );
    Widget panel = expanded
        ? SizedBox.expand(child: panelBody)
        : SizedBox.fromSize(size: logicalSize, child: panelBody);

    if (semanticLabel case final label?) {
      panel = Semantics(container: true, label: label, child: panel);
    }
    return panel;
  }
}

/// Constrains colored content to the area inside a panel's one-tile frame.
///
/// Text and interactive content can remain full-size while background fills
/// use this layer to avoid showing through transparent corners and edges.
class PixelPanelInterior extends StatelessWidget {
  const PixelPanelInterior({super.key, required this.child, this.tileExtent});

  final Widget child;
  final double? tileExtent;

  @override
  Widget build(BuildContext context) {
    final resolvedTileExtent =
        tileExtent ??
        PixelUiThemeData.maybeOf(context)?.tileExtent ??
        PixelGrid.defaultTileExtent;
    return Padding(padding: EdgeInsets.all(resolvedTileExtent), child: child);
  }
}

class PixelPanelPainter extends CustomPainter {
  const PixelPanelPainter({
    required this.image,
    required this.atlas,
    required this.recipe,
    required this.gridSize,
    required this.tileExtent,
    required this.seed,
  });

  const PixelPanelPainter.expanded({
    required this.image,
    required this.atlas,
    required this.recipe,
    required this.tileExtent,
    required this.seed,
  }) : gridSize = null;

  final ui.Image image;
  final PixelAtlasDefinition atlas;
  final PixelPanelRecipe recipe;
  final PixelGridSize? gridSize;
  final double tileExtent;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final fixedGrid = gridSize;
    if (fixedGrid == null) {
      _paintExpanded(canvas, size);
      return;
    }

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;

    if (recipe.solidFillColor case final fillColor?) {
      paint.color = fillColor;
      final interior = _interiorRect(size);
      if (!interior.isEmpty) {
        canvas.drawRect(interior, paint);
      }
      paint.color = Colors.white;
    } else if (recipe.paintFillUnderFrame) {
      for (var row = 1; row < fixedGrid.rows - 1; row += 1) {
        for (var column = 1; column < fixedGrid.columns - 1; column += 1) {
          _drawRegion(
            canvas: canvas,
            paint: paint,
            region: recipe.fill.select(
              column: column,
              row: row,
              seed: seed,
              salt: 5,
            ),
            destination: Rect.fromLTWH(
              column * tileExtent,
              row * tileExtent,
              tileExtent,
              tileExtent,
            ),
          );
        }
      }
    }

    for (var row = 0; row < fixedGrid.rows; row += 1) {
      for (var column = 0; column < fixedGrid.columns; column += 1) {
        final isInterior =
            row > 0 &&
            row < fixedGrid.rows - 1 &&
            column > 0 &&
            column < fixedGrid.columns - 1;
        if (isInterior &&
            (recipe.paintFillUnderFrame || recipe.solidFillColor != null)) {
          continue;
        }
        final cell = recipe.cellFor(
          column: column,
          row: row,
          columns: fixedGrid.columns,
          rows: fixedGrid.rows,
          seed: seed,
        );
        _drawRegion(
          canvas: canvas,
          paint: paint,
          region: cell.region,
          destination: Rect.fromLTWH(
            column * tileExtent,
            row * tileExtent,
            tileExtent,
            tileExtent,
          ),
          quarterTurns: cell.transform.quarterTurns,
          flipHorizontally: cell.transform.flipHorizontally,
          flipVertically: cell.transform.flipVertically,
        );
      }
    }

    for (final stamp in recipe.stamps) {
      final destination = Rect.fromLTWH(
        stamp.column * tileExtent,
        stamp.row * tileExtent,
        stamp.region.widthInTiles * tileExtent,
        stamp.region.heightInTiles * tileExtent,
      );
      paint.color = Color.fromRGBO(255, 255, 255, stamp.opacity);
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: stamp.region,
        destination: destination,
        quarterTurns: stamp.quarterTurns,
        flipHorizontally: stamp.flipHorizontally,
        flipVertically: stamp.flipVertically,
      );
      paint.color = Colors.white;
    }
  }

  void _paintExpanded(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    final horizontalFrame = math.min(tileExtent, size.width / 2);
    final verticalFrame = math.min(tileExtent, size.height / 2);
    final interior = Rect.fromLTRB(
      horizontalFrame,
      verticalFrame,
      size.width - horizontalFrame,
      size.height - verticalFrame,
    );
    final interiorColumns = math.max(0, (interior.width / tileExtent).ceil());
    final interiorRows = math.max(0, (interior.height / tileExtent).ceil());
    final columns = interiorColumns + 2;
    final rows = interiorRows + 2;

    if (!interior.isEmpty) {
      if (recipe.solidFillColor case final fillColor?) {
        paint.color = fillColor;
        canvas.drawRect(interior, paint);
        paint.color = Colors.white;
      } else {
        canvas.save();
        canvas.clipRect(interior, doAntiAlias: false);
        for (var row = 0; row < interiorRows; row += 1) {
          for (var column = 0; column < interiorColumns; column += 1) {
            _drawRegion(
              canvas: canvas,
              paint: paint,
              region: recipe.fill.select(
                column: column + 1,
                row: row + 1,
                seed: seed,
                salt: 5,
              ),
              destination: Rect.fromLTWH(
                horizontalFrame + column * tileExtent,
                verticalFrame + row * tileExtent,
                tileExtent,
                tileExtent,
              ),
            );
          }
        }
        canvas.restore();
      }
    }

    _paintExpandedHorizontalEdge(
      canvas: canvas,
      paint: paint,
      area: Rect.fromLTWH(horizontalFrame, 0, interior.width, verticalFrame),
      variants: recipe.top,
      transform: recipe.topTransform,
      row: 0,
      salt: 1,
    );
    _paintExpandedHorizontalEdge(
      canvas: canvas,
      paint: paint,
      area: Rect.fromLTWH(
        horizontalFrame,
        size.height - verticalFrame,
        interior.width,
        verticalFrame,
      ),
      variants: recipe.bottom,
      transform: recipe.bottomTransform,
      row: rows - 1,
      salt: 2,
    );
    _paintExpandedVerticalEdge(
      canvas: canvas,
      paint: paint,
      area: Rect.fromLTWH(0, verticalFrame, horizontalFrame, interior.height),
      variants: recipe.left,
      transform: recipe.leftTransform,
      column: 0,
      salt: 3,
    );
    _paintExpandedVerticalEdge(
      canvas: canvas,
      paint: paint,
      area: Rect.fromLTWH(
        size.width - horizontalFrame,
        verticalFrame,
        horizontalFrame,
        interior.height,
      ),
      variants: recipe.right,
      transform: recipe.rightTransform,
      column: columns - 1,
      salt: 4,
    );

    _drawRegion(
      canvas: canvas,
      paint: paint,
      region: recipe.topLeft,
      destination: Rect.fromLTWH(0, 0, horizontalFrame, verticalFrame),
      quarterTurns: recipe.topLeftTransform.quarterTurns,
      flipHorizontally: recipe.topLeftTransform.flipHorizontally,
      flipVertically: recipe.topLeftTransform.flipVertically,
    );
    _drawRegion(
      canvas: canvas,
      paint: paint,
      region: recipe.topRight,
      destination: Rect.fromLTWH(
        size.width - horizontalFrame,
        0,
        horizontalFrame,
        verticalFrame,
      ),
      quarterTurns: recipe.topRightTransform.quarterTurns,
      flipHorizontally: recipe.topRightTransform.flipHorizontally,
      flipVertically: recipe.topRightTransform.flipVertically,
    );
    _drawRegion(
      canvas: canvas,
      paint: paint,
      region: recipe.bottomLeft,
      destination: Rect.fromLTWH(
        0,
        size.height - verticalFrame,
        horizontalFrame,
        verticalFrame,
      ),
      quarterTurns: recipe.bottomLeftTransform.quarterTurns,
      flipHorizontally: recipe.bottomLeftTransform.flipHorizontally,
      flipVertically: recipe.bottomLeftTransform.flipVertically,
    );
    _drawRegion(
      canvas: canvas,
      paint: paint,
      region: recipe.bottomRight,
      destination: Rect.fromLTWH(
        size.width - horizontalFrame,
        size.height - verticalFrame,
        horizontalFrame,
        verticalFrame,
      ),
      quarterTurns: recipe.bottomRightTransform.quarterTurns,
      flipHorizontally: recipe.bottomRightTransform.flipHorizontally,
      flipVertically: recipe.bottomRightTransform.flipVertically,
    );

    for (final stamp in recipe.stamps) {
      paint.color = Color.fromRGBO(255, 255, 255, stamp.opacity);
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: stamp.region,
        destination: Rect.fromLTWH(
          stamp.column * tileExtent,
          stamp.row * tileExtent,
          stamp.region.widthInTiles * tileExtent,
          stamp.region.heightInTiles * tileExtent,
        ),
        quarterTurns: stamp.quarterTurns,
        flipHorizontally: stamp.flipHorizontally,
        flipVertically: stamp.flipVertically,
      );
      paint.color = Colors.white;
    }
  }

  void _paintExpandedHorizontalEdge({
    required Canvas canvas,
    required Paint paint,
    required Rect area,
    required PixelTileVariants variants,
    required PixelTileTransform transform,
    required int row,
    required int salt,
  }) {
    if (area.isEmpty) {
      return;
    }
    canvas.save();
    canvas.clipRect(area, doAntiAlias: false);

    if (area.width < tileExtent * 2) {
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: variants.select(
          column: 1,
          row: row,
          seed: seed,
          salt: salt,
          edgeLength: 1,
        ),
        destination: Rect.fromLTWH(
          area.left,
          area.top,
          tileExtent,
          area.height,
        ),
        quarterTurns: transform.quarterTurns,
        flipHorizontally: transform.flipHorizontally,
        flipVertically: transform.flipVertically,
      );
      canvas.restore();
      return;
    }

    final middleWidth = area.width - tileExtent * 2;
    final fullMiddleCells = (middleWidth / tileExtent).floor();
    final remainder = middleWidth - fullMiddleCells * tileExtent;
    final hasFlexibleCells = remainder > 0.001;
    final edgeCells = fullMiddleCells + 2 + (hasFlexibleCells ? 2 : 0);

    void drawCell(int position, double left) {
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: variants.select(
          column: position,
          row: row,
          seed: seed,
          salt: salt,
          edgeLength: edgeCells,
        ),
        destination: Rect.fromLTWH(left, area.top, tileExtent, area.height),
        quarterTurns: transform.quarterTurns,
        flipHorizontally: transform.flipHorizontally,
        flipVertically: transform.flipVertically,
      );
    }

    drawCell(1, area.left);
    drawCell(edgeCells, area.right - tileExtent);

    var cursor = area.left + tileExtent;
    var middlePosition = 2;
    if (hasFlexibleCells) {
      final leadingWidth = (remainder / 2).floorToDouble();
      _paintClippedHorizontalCell(
        canvas: canvas,
        paintCell: (left) => drawCell(middlePosition, left),
        left: cursor,
        top: area.top,
        visibleWidth: leadingWidth,
        height: area.height,
        alignToTrailingEdge: false,
      );
      cursor += leadingWidth;
      middlePosition += 1;
    }

    for (var index = 0; index < fullMiddleCells; index += 1) {
      drawCell(middlePosition, cursor);
      cursor += tileExtent;
      middlePosition += 1;
    }

    if (hasFlexibleCells) {
      final trailingWidth = area.right - tileExtent - cursor;
      _paintClippedHorizontalCell(
        canvas: canvas,
        paintCell: (left) => drawCell(middlePosition, left),
        left: cursor,
        top: area.top,
        visibleWidth: trailingWidth,
        height: area.height,
        alignToTrailingEdge: true,
      );
    }
    canvas.restore();
  }

  void _paintClippedHorizontalCell({
    required Canvas canvas,
    required void Function(double left) paintCell,
    required double left,
    required double top,
    required double visibleWidth,
    required double height,
    required bool alignToTrailingEdge,
  }) {
    if (visibleWidth <= 0) {
      return;
    }
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(left, top, visibleWidth, height),
      doAntiAlias: false,
    );
    paintCell(alignToTrailingEdge ? left + visibleWidth - tileExtent : left);
    canvas.restore();
  }

  void _paintExpandedVerticalEdge({
    required Canvas canvas,
    required Paint paint,
    required Rect area,
    required PixelTileVariants variants,
    required PixelTileTransform transform,
    required int column,
    required int salt,
  }) {
    if (area.isEmpty) {
      return;
    }
    canvas.save();
    canvas.clipRect(area, doAntiAlias: false);

    if (area.height < tileExtent * 2) {
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: variants.select(
          column: column,
          row: 1,
          seed: seed,
          salt: salt,
          edgeLength: 1,
        ),
        destination: Rect.fromLTWH(area.left, area.top, area.width, tileExtent),
        quarterTurns: transform.quarterTurns,
        flipHorizontally: transform.flipHorizontally,
        flipVertically: transform.flipVertically,
      );
      canvas.restore();
      return;
    }

    final middleHeight = area.height - tileExtent * 2;
    final fullMiddleCells = (middleHeight / tileExtent).floor();
    final remainder = middleHeight - fullMiddleCells * tileExtent;
    final hasFlexibleCells = remainder > 0.001;
    final edgeCells = fullMiddleCells + 2 + (hasFlexibleCells ? 2 : 0);

    void drawCell(int position, double top) {
      _drawRegion(
        canvas: canvas,
        paint: paint,
        region: variants.select(
          column: column,
          row: position,
          seed: seed,
          salt: salt,
          edgeLength: edgeCells,
        ),
        destination: Rect.fromLTWH(area.left, top, area.width, tileExtent),
        quarterTurns: transform.quarterTurns,
        flipHorizontally: transform.flipHorizontally,
        flipVertically: transform.flipVertically,
      );
    }

    drawCell(1, area.top);
    drawCell(edgeCells, area.bottom - tileExtent);

    var cursor = area.top + tileExtent;
    var middlePosition = 2;
    if (hasFlexibleCells) {
      final leadingHeight = (remainder / 2).floorToDouble();
      _paintClippedVerticalCell(
        canvas: canvas,
        paintCell: (top) => drawCell(middlePosition, top),
        left: area.left,
        top: cursor,
        width: area.width,
        visibleHeight: leadingHeight,
        alignToTrailingEdge: false,
      );
      cursor += leadingHeight;
      middlePosition += 1;
    }

    for (var index = 0; index < fullMiddleCells; index += 1) {
      drawCell(middlePosition, cursor);
      cursor += tileExtent;
      middlePosition += 1;
    }

    if (hasFlexibleCells) {
      final trailingHeight = area.bottom - tileExtent - cursor;
      _paintClippedVerticalCell(
        canvas: canvas,
        paintCell: (top) => drawCell(middlePosition, top),
        left: area.left,
        top: cursor,
        width: area.width,
        visibleHeight: trailingHeight,
        alignToTrailingEdge: true,
      );
    }
    canvas.restore();
  }

  void _paintClippedVerticalCell({
    required Canvas canvas,
    required void Function(double top) paintCell,
    required double left,
    required double top,
    required double width,
    required double visibleHeight,
    required bool alignToTrailingEdge,
  }) {
    if (visibleHeight <= 0) {
      return;
    }
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(left, top, width, visibleHeight),
      doAntiAlias: false,
    );
    paintCell(alignToTrailingEdge ? top + visibleHeight - tileExtent : top);
    canvas.restore();
  }

  Rect _interiorRect(Size size) {
    final horizontalInset = math.min(tileExtent, size.width / 2);
    final verticalInset = math.min(tileExtent, size.height / 2);
    return Rect.fromLTRB(
      horizontalInset,
      verticalInset,
      size.width - horizontalInset,
      size.height - verticalInset,
    );
  }

  void _drawRegion({
    required Canvas canvas,
    required Paint paint,
    required PixelAtlasRegion region,
    required Rect destination,
    int quarterTurns = 0,
    bool flipHorizontally = false,
    bool flipVertically = false,
  }) {
    if (quarterTurns == 0 && !flipHorizontally && !flipVertically) {
      canvas.drawImageRect(
        image,
        region.sourceRect(atlas.sourceTileExtent),
        destination,
        paint,
      );
      return;
    }

    canvas.save();
    canvas.translate(destination.center.dx, destination.center.dy);
    canvas.scale(flipHorizontally ? -1 : 1, flipVertically ? -1 : 1);
    canvas.rotate(quarterTurns * math.pi / 2);
    canvas.translate(-destination.center.dx, -destination.center.dy);
    canvas.drawImageRect(
      image,
      region.sourceRect(atlas.sourceTileExtent),
      destination,
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PixelPanelPainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.atlas != atlas ||
        oldDelegate.recipe != recipe ||
        oldDelegate.gridSize != gridSize ||
        oldDelegate.tileExtent != tileExtent ||
        oldDelegate.seed != seed;
  }
}
