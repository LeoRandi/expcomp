import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Shared geometry for UI that is authored on a fixed pixel-art grid.
abstract final class PixelGrid {
  static const double defaultTileExtent = 16;

  static bool isAligned(double value, {double tileExtent = defaultTileExtent}) {
    _validateTileExtent(tileExtent);
    final tileCount = value / tileExtent;
    return (tileCount - tileCount.round()).abs() < precisionErrorTolerance;
  }

  static double snapUp(double value, {double tileExtent = defaultTileExtent}) {
    _validateTileExtent(tileExtent);
    return (value / tileExtent).ceil() * tileExtent;
  }

  static double snapDown(
    double value, {
    double tileExtent = defaultTileExtent,
  }) {
    _validateTileExtent(tileExtent);
    return (value / tileExtent).floor() * tileExtent;
  }

  static double snapNearest(
    double value, {
    double tileExtent = defaultTileExtent,
  }) {
    _validateTileExtent(tileExtent);
    return (value / tileExtent).round() * tileExtent;
  }

  static void _validateTileExtent(double tileExtent) {
    if (!tileExtent.isFinite || tileExtent <= 0) {
      throw ArgumentError.value(
        tileExtent,
        'tileExtent',
        'Must be finite and greater than zero.',
      );
    }
  }
}

@immutable
class PixelGridSize {
  const PixelGridSize({required this.columns, required this.rows})
    : assert(columns > 0),
      assert(rows > 0);

  final int columns;
  final int rows;

  int get tileCount => columns * rows;

  Size logicalSize([double tileExtent = PixelGrid.defaultTileExtent]) {
    if (!tileExtent.isFinite || tileExtent <= 0) {
      throw ArgumentError.value(
        tileExtent,
        'tileExtent',
        'Must be finite and greater than zero.',
      );
    }
    return Size(columns * tileExtent, rows * tileExtent);
  }

  @override
  bool operator ==(Object other) {
    return other is PixelGridSize &&
        other.columns == columns &&
        other.rows == rows;
  }

  @override
  int get hashCode => Object.hash(columns, rows);

  @override
  String toString() => 'PixelGridSize($columns x $rows)';
}
