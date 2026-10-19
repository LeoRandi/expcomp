import 'dart:ui';

import 'cresca_map.dart';

enum WorldArea { town, testing }

enum NpcAction { talk, testing, town, battle }

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
  });

  final String id;
  final String name;
  final String role;
  final Offset position;
  final List<String> lines;
  final String asset;
  final NpcAction action;

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
}

class MapProp {
  const MapProp(
    this.kind,
    this.position, {
    this.label,
    this.solid = false,
    this.lines = const [],
  });
  final PropKind kind;
  final Offset position;
  final String? label;
  final bool solid;
  final List<String> lines;

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
    required this.roadAt,
    this.props = const [],
  });

  final WorldArea area;
  final String name;
  final String subtitle;
  final int columns;
  final int rows;
  final Offset spawn;
  final List<MapBuilding> buildings;
  final List<Offset> torches;
  final List<TownNpc> npcs;
  final List<MapProp> props;
  final bool Function(int, int) roadAt;

  bool contains(Offset tile) =>
      tile.dx >= 0 && tile.dy >= 0 && tile.dx < columns && tile.dy < rows;

  bool isSolid(int column, int row) {
    final tile = Offset(column.toDouble(), row.toDouble());
    return !contains(tile) ||
        isCavernWall(column, row) ||
        buildings.any(
          (b) => b.footprint.contains(tile + const Offset(.5, .5)),
        ) ||
        props.any((p) => p.solid && p.position == tile);
  }

  /// Road openings cut through the cavern rim to the map boundary.
  bool isCavernWall(int column, int row) =>
      area == WorldArea.town &&
      (column == 0 || column == columns - 1 || row <= 1 || row == rows - 1) &&
      !roadAt(column, row);

  bool isRoad(int column, int row) =>
      !isSolid(column, row) && roadAt(column, row);
}

const testingMap = ExplorationMap(
  area: WorldArea.testing,
  name: 'Testing grounds',
  subtitle: 'Spar with the villager. The Waykeeper can take you home.',
  columns: 20,
  rows: 20,
  spawn: Offset(10, 10),
  buildings: crescaBuildings,
  torches: crescaTorches,
  roadAt: isRoadTile,
  npcs: [
    TownNpc(
      id: 'trainer',
      name: 'Cresca Villager',
      role: 'Sparring partner',
      position: Offset(10, 9),
      lines: ['Ready to meet your end?'],
      action: NpcAction.battle,
    ),
    TownNpc(
      id: 'waykeeper',
      name: 'The Waykeeper',
      role: 'A familiar shadow',
      position: Offset(11, 10),
      asset: '${characterAssets}Wizard/wizard_8.png',
      tint: Color(0xFF9692B2),
      lines: [
        'Enough practice? Take my hand. I will leave you outside your home in Cresca.',
      ],
      action: NpcAction.town,
    ),
  ],
);
