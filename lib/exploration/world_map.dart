import 'dart:ui';

import 'cresca_map.dart';
import 'area_transition.dart';
import 'chest_contents.dart';
import 'world_lighting.dart';
export 'world_maps.dart' show testingMap;

enum WorldArea { town, testing, routeOne, crescaIndoors }

enum NpcAction { talk, travel, battle }

class MapGate {
  const MapGate({
    required this.number,
    required this.destinationName,
    required this.trigger,
    required this.automatic,
    this.door = false,
    this.exit,
  });
  final String number;
  final String destinationName;
  final Rect trigger;
  final bool automatic;
  final bool door;
  final AreaExit? exit;
}

class AreaExit {
  const AreaExit({
    required this.id,
    required this.trigger,
    required this.destination,
    required this.arrival,
    required this.style,
  });
  final String id;
  final Rect trigger;
  final WorldArea destination;
  final Offset arrival;
  final AreaTransitionStyle style;
}

const characterAssets =
    'assets/monsters/dark_fantasy_creatures_cc0/'
    'raw_originals/03_stylized_fantasy/';

class TownNpc {
  const TownNpc({
    required this.id,
    required this.name,
    required this.role,
    required this.position,
    required this.lines,
    this.asset = '${characterAssets}Wizard/wizard_8.png',
    this.action = NpcAction.talk,
    this.route = const [],
    this.tint,
    this.gate,
  });

  final String id;
  final String name;
  final String role;
  final Offset position;
  final List<String> lines;
  final String asset;
  final NpcAction action;
  final String? gate;

  /// A closed loop of adjacent cells, starting at [position].
  final List<Offset> route;
  final Color? tint;
}

enum PropKind {
  fungus,
  rubble,
  flowers,
  crates,
  bench,
  well,
  stall,
  sign,
  garden,
  fence,
  gate,
  rock,
  chest,
  table,
  chair,
  cushions,
  rug,
  bookcase,
  door,
}

class MapProp {
  const MapProp(
    this.kind,
    this.position, {
    this.label,
    this.solid = false,
    this.lines = const [],
    this.chest,
  });
  final PropKind kind;
  final Offset position;
  final String? label;
  final bool solid;
  final List<String> lines;

  final ChestContents? chest;

  bool get isReadable => lines.isNotEmpty;
  bool get isFence => kind == PropKind.fence || kind == PropKind.gate;
}

class ExplorationMap {
  const ExplorationMap({
    required this.area,
    required this.name,
    required this.subtitle,
    required this.columns,
    required this.rows,
    required this.spawn,
    required this.buildings,
    required this.torches,
    required this.npcs,
    this.lightRadius = defaultLightRadius,
    this.roadAt,
    this.props = const [],
    List<AreaExit> exits = const [],
    this.gates = const [],
    this.cells,
    this.floorCells,
  }) : _exits = exits;

  final WorldArea area;
  final String name;
  final String subtitle;
  final int columns;
  final int rows;
  final Offset spawn;
  final double lightRadius;
  final List<MapBuilding> buildings;
  final List<Offset> torches;
  final List<TownNpc> npcs;
  final List<MapProp> props;
  final List<AreaExit> _exits;
  final List<MapGate> gates;
  List<AreaExit> get exits => [
    ..._exits,
    for (final gate in gates)
      if (gate.automatic && gate.exit != null) gate.exit!,
  ];
  final bool Function(int, int)? roadAt;

  /// Optional text terrain; cell coordinates are shared by art and collision.
  final List<String>? cells;

  /// Separate ground layer, so paths can continue under props and gates.
  final List<String>? floorCells;

  String? tileAt(int column, int row) =>
      cells != null && column >= 0 && row >= 0 && column < columns && row < rows
      ? cells![row][column]
      : null;

  bool isGrass(int column, int row) => tileAt(column, row) == 'g';

  String? floorAt(int column, int row) {
    if (column < 0 || row < 0 || column >= columns || row >= rows) return null;
    return floorCells?[row][column] ?? (tileAt(column, row) == '.' ? '.' : '-');
  }

  bool contains(Offset tile) =>
      tile.dx >= 0 && tile.dy >= 0 && tile.dx < columns && tile.dy < rows;

  bool isSolid(int column, int row) {
    final tile = Offset(column.toDouble(), row.toDouble());
    return !contains(tile) ||
        tileAt(column, row) == '#' ||
        tileAt(column, row) == 'x' ||
        floorAt(column, row) == '#' ||
        isCavernWall(column, row) ||
        buildings.any(
          (b) => b.footprint.contains(tile + const Offset(.5, .5)),
        ) ||
        props.any((p) => p.solid && p.position == tile);
  }

  /// Road openings cut through the cavern rim to the map boundary.
  bool isCavernWall(int column, int row) => tileAt(column, row) == 'X';

  bool isRoad(int column, int row) =>
      !isSolid(column, row) &&
      (roadAt?.call(column, row) ??
          const ['.', '='].contains(floorAt(column, row)));
}
