import 'dart:math' as math;
import 'dart:ui';

/// The original outer reach, with a clear inner half and three shaded rings.
const defaultLightRadius = 6.0;

double _auraDarkness(double distance, double radius) {
  if (radius <= 0) return 1;
  final scaledDistance = distance * defaultLightRadius / radius;
  return switch (scaledDistance) {
    < 3 => 0.0,
    < 4 => 0.5,
    < 5 => 0.75,
    < 6 => 0.9,
    _ => 1.0,
  };
}

/// Fixed lights retain their original radius. The player's independent aura
/// uses the map's radius; overlapping sources keep the brighter result.
double worldDarknessAt(
  int column,
  int row,
  Iterable<Offset> lights, {
  Offset? player,
  double playerRadius = defaultLightRadius,
}) {
  final tile = Offset(column.toDouble(), row.toDouble());
  var distance = double.infinity;
  for (final light in lights) {
    distance = math.min(distance, (tile - light).distance);
  }
  final fixedLight = _auraDarkness(distance, defaultLightRadius);
  return player == null
      ? fixedLight
      : math.min(
          fixedLight,
          _auraDarkness((tile - player).distance, playerRadius),
        );
}
