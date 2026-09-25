import 'dart:ui';
import 'world_layers.dart';

class MapBuilding {
  const MapBuilding({
    required this.id,
    required this.bounds,
    required this.footprint,
    required this.wallZ,
    required this.roofZ,
  });
  final String id;
  final Rect bounds;
  final Rect footprint;
  final int wallZ;
  final int roofZ;
}

const crescaBuildings = [
  MapBuilding(
    id: 'west',
    bounds: Rect.fromLTWH(5, 6, 3, 3),
    footprint: Rect.fromLTWH(5, 7, 3, 2),
    wallZ: WorldZ.actor,
    roofZ: WorldZ.roof,
  ),
  MapBuilding(
    id: 'east',
    bounds: Rect.fromLTWH(12, 3, 3, 3),
    footprint: Rect.fromLTWH(12, 4, 3, 2),
    wallZ: WorldZ.actor,
    roofZ: WorldZ.roof,
  ),
];

/// Walls and closed doors are solid; projected roofs are walkable below.
final crescaHouses = [for (final b in crescaBuildings) b.footprint];

bool isHouseTile(int column, int row) =>
    crescaHouses.any((house) => house.contains(Offset(column + .5, row + .5)));

bool isRoadTile(int column, int row) =>
    !isHouseTile(column, row) &&
    ((column >= 9 && column <= 10 && row >= 3 && row <= 16) ||
        (row == 9 && column >= 6 && column <= 10) ||
        (row == 6 && column >= 9 && column <= 13));
