import 'dart:math' as math;
import 'dart:ui';

/// Player and torches share a circular aura measured between tile centers.
/// Overlapping auras reveal the tile using its nearest light source.
double worldDarknessAt(int column, int row, Iterable<Offset> lights) {
  var distance = double.infinity;
  for (final light in lights) {
    distance = math.min(
      distance,
      (Offset(column.toDouble(), row.toDouble()) - light).distance,
    );
  }
  return switch (distance) {
    < 3 => 0.0,
    < 4 => 0.5,
    < 5 => 0.75,
    < 6 => 0.9,
    _ => 1.0,
  };
}
