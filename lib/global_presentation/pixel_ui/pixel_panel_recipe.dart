import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'pixel_atlas.dart';

@immutable
class PixelTileTransform {
  const PixelTileTransform({
    this.quarterTurns = 0,
    this.flipHorizontally = false,
    this.flipVertically = false,
  }) : assert(quarterTurns >= 0 && quarterTurns <= 3);

  static const identity = PixelTileTransform();

  final int quarterTurns;
  final bool flipHorizontally;
  final bool flipVertically;

  bool get isIdentity =>
      quarterTurns == 0 && !flipHorizontally && !flipVertically;

  @override
  bool operator ==(Object other) {
    return other is PixelTileTransform &&
        other.quarterTurns == quarterTurns &&
        other.flipHorizontally == flipHorizontally &&
        other.flipVertically == flipVertically;
  }

  @override
  int get hashCode =>
      Object.hash(quarterTurns, flipHorizontally, flipVertically);
}

@immutable
class PixelPanelCell {
  const PixelPanelCell({
    required this.region,
    this.transform = PixelTileTransform.identity,
  });

  final PixelAtlasRegion region;
  final PixelTileTransform transform;
}

enum PixelTileSequenceAxis { horizontal, vertical }

@immutable
class PixelTileVariants {
  PixelTileVariants(Iterable<PixelAtlasRegion> regions)
    : regions = List.unmodifiable(regions),
      sequenceAxis = null,
      assert(regions.isNotEmpty);

  PixelTileVariants.single(PixelAtlasRegion region)
    : regions = [region],
      sequenceAxis = null;

  PixelTileVariants.sequence(
    Iterable<PixelAtlasRegion> regions, {
    required this.sequenceAxis,
  }) : regions = List.unmodifiable(regions),
       assert(regions.isNotEmpty);

  final List<PixelAtlasRegion> regions;
  final PixelTileSequenceAxis? sequenceAxis;

  PixelAtlasRegion select({
    required int column,
    required int row,
    required int seed,
    int salt = 0,
    int? edgeLength,
  }) {
    if (regions.length == 1) {
      return regions.first;
    }

    if (sequenceAxis case final axis?) {
      final position =
          (axis == PixelTileSequenceAxis.horizontal ? column : row) - 1;
      if (edgeLength == null || edgeLength <= 0) {
        return regions[position % regions.length];
      }
      if (edgeLength == 1) {
        return regions[regions.length ~/ 2];
      }
      if (position <= 0) {
        return regions.first;
      }
      if (position >= edgeLength - 1) {
        return regions.last;
      }

      // Keep the source end caps beside the panel corners and repeat only the
      // connecting cells between them. Three-cell strips therefore behave as
      // start / repeatable middle / end at every panel size.
      if (regions.length > 2) {
        return regions[1 + ((position - 1) % (regions.length - 2))];
      }
      return regions[position % regions.length];
    }

    var hash = seed ^ salt;
    hash = 0x1fffffff & (hash + column * 0x45d9f3b);
    hash = 0x1fffffff & (hash ^ (row * 0x119de1f3));
    hash = 0x1fffffff & (hash ^ (hash >> 16));
    return regions[hash % regions.length];
  }
}

@immutable
class PixelTileStamp {
  const PixelTileStamp({
    required this.region,
    required this.column,
    required this.row,
    this.opacity = 1,
    this.quarterTurns = 0,
    this.flipHorizontally = false,
    this.flipVertically = false,
  }) : assert(opacity >= 0 && opacity <= 1),
       assert(quarterTurns >= 0 && quarterTurns <= 3);

  final PixelAtlasRegion region;
  final int column;
  final int row;
  final double opacity;
  final int quarterTurns;
  final bool flipHorizontally;
  final bool flipVertically;
}

/// A nine-slice-like recipe that repeats real tiles instead of stretching them.
@immutable
class PixelPanelRecipe {
  const PixelPanelRecipe({
    required this.topLeft,
    required this.top,
    required this.topRight,
    required this.left,
    required this.fill,
    required this.right,
    required this.bottomLeft,
    required this.bottom,
    required this.bottomRight,
    this.topLeftTransform = PixelTileTransform.identity,
    this.topTransform = PixelTileTransform.identity,
    this.topRightTransform = PixelTileTransform.identity,
    this.leftTransform = PixelTileTransform.identity,
    this.rightTransform = PixelTileTransform.identity,
    this.bottomLeftTransform = PixelTileTransform.identity,
    this.bottomTransform = PixelTileTransform.identity,
    this.bottomRightTransform = PixelTileTransform.identity,
    this.paintFillUnderFrame = false,
    this.solidFillColor,
    this.stamps = const [],
  });

  /// A distinct three-by-three frame from the same source atlas.
  factory PixelPanelRecipe.ninePatch(int column, int row, Color fillColor) {
    PixelAtlasRegion tile(int x, int y) =>
        PixelAtlasRegion(column: column + x, row: row + y);
    PixelTileVariants edge(int x, int y) =>
        PixelTileVariants.single(tile(x, y));
    return PixelPanelRecipe(
      topLeft: tile(0, 0),
      top: edge(1, 0),
      topRight: tile(2, 0),
      left: edge(0, 1),
      fill: edge(1, 1),
      right: edge(2, 1),
      bottomLeft: tile(0, 2),
      bottom: edge(1, 2),
      bottomRight: tile(2, 2),
      solidFillColor: fillColor,
    );
  }

  final PixelAtlasRegion topLeft;
  final PixelTileVariants top;
  final PixelAtlasRegion topRight;
  final PixelTileVariants left;
  final PixelTileVariants fill;
  final PixelTileVariants right;
  final PixelAtlasRegion bottomLeft;
  final PixelTileVariants bottom;
  final PixelAtlasRegion bottomRight;
  final PixelTileTransform topLeftTransform;
  final PixelTileTransform topTransform;
  final PixelTileTransform topRightTransform;
  final PixelTileTransform leftTransform;
  final PixelTileTransform rightTransform;
  final PixelTileTransform bottomLeftTransform;
  final PixelTileTransform bottomTransform;
  final PixelTileTransform bottomRightTransform;
  final bool paintFillUnderFrame;
  final Color? solidFillColor;
  final List<PixelTileStamp> stamps;

  PixelPanelCell cellFor({
    required int column,
    required int row,
    required int columns,
    required int rows,
    required int seed,
  }) {
    assert(columns >= 2);
    assert(rows >= 2);
    assert(column >= 0 && column < columns);
    assert(row >= 0 && row < rows);

    final lastColumn = columns - 1;
    final lastRow = rows - 1;

    if (row == 0) {
      if (column == 0) {
        return PixelPanelCell(region: topLeft, transform: topLeftTransform);
      }
      if (column == lastColumn) {
        return PixelPanelCell(region: topRight, transform: topRightTransform);
      }
      return PixelPanelCell(
        region: top.select(
          column: column,
          row: row,
          seed: seed,
          salt: 1,
          edgeLength: columns - 2,
        ),
        transform: topTransform,
      );
    }

    if (row == lastRow) {
      if (column == 0) {
        return PixelPanelCell(
          region: bottomLeft,
          transform: bottomLeftTransform,
        );
      }
      if (column == lastColumn) {
        return PixelPanelCell(
          region: bottomRight,
          transform: bottomRightTransform,
        );
      }
      return PixelPanelCell(
        region: bottom.select(
          column: column,
          row: row,
          seed: seed,
          salt: 2,
          edgeLength: columns - 2,
        ),
        transform: bottomTransform,
      );
    }

    if (column == 0) {
      return PixelPanelCell(
        region: left.select(
          column: column,
          row: row,
          seed: seed,
          salt: 3,
          edgeLength: rows - 2,
        ),
        transform: leftTransform,
      );
    }
    if (column == lastColumn) {
      return PixelPanelCell(
        region: right.select(
          column: column,
          row: row,
          seed: seed,
          salt: 4,
          edgeLength: rows - 2,
        ),
        transform: rightTransform,
      );
    }
    return PixelPanelCell(
      region: fill.select(column: column, row: row, seed: seed, salt: 5),
    );
  }

  PixelAtlasRegion regionForCell({
    required int column,
    required int row,
    required int columns,
    required int rows,
    required int seed,
  }) {
    return cellFor(
      column: column,
      row: row,
      columns: columns,
      rows: rows,
      seed: seed,
    ).region;
  }
}
