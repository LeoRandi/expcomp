import 'dart:ui';
import 'world_map.dart';

enum BuildingAppearance { cottage, inn }

class MapBuilding {
  const MapBuilding({
    required this.id,
    required this.bounds,
    required this.footprint,
    required this.wallZ,
    required this.roofZ,
    this.appearance = BuildingAppearance.cottage,
  });
  final String id;
  final Rect bounds;
  final Rect footprint;
  final int wallZ;
  final int roofZ;
  final BuildingAppearance appearance;
}

// Compatibility accessors derive from the testing area's text maps.
List<Offset> get crescaTorches => testingMap.torches;
List<MapBuilding> get crescaBuildings => testingMap.buildings;
List<Rect> get crescaHouses => [for (final b in crescaBuildings) b.footprint];
bool isHouseTile(int column, int row) =>
    crescaHouses.any((house) => house.contains(Offset(column + .5, row + .5)));
bool isRoadTile(int column, int row) => testingMap.isRoad(column, row);
