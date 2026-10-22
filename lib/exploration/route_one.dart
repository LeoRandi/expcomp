import 'package:flutter/services.dart';

import 'area_transition.dart';
import 'cresca_map.dart';
import 'world_layers.dart';
import 'world_map.dart';

const routeOneTextAsset = 'assets/text-maps/r1.txt';
const routeOneFloorAsset = 'assets/text-maps/r1-floor.txt';

Future<ExplorationMap> loadRouteOne(AssetBundle bundle) async {
  final layers = await Future.wait([
    bundle.loadString(routeOneTextAsset),
    bundle.loadString(routeOneFloorAsset),
  ]);
  return parseRouteOne(layers[0], floorSource: layers[1]);
}

/// The author's text map is the runtime source, with no generated layout copy.
ExplorationMap parseRouteOne(String source, {required String floorSource}) {
  final cells = source.trimRight().split(RegExp(r'\r?\n'));
  if (cells.isEmpty ||
      cells.first.isEmpty ||
      cells.any(
        (row) =>
            row.length != cells.first.length ||
            !RegExp(r'^[X0.\-igrCh]+$').hasMatch(row),
      )) {
    throw const FormatException(
      'Route 1 must be a rectangle of legend symbols.',
    );
  }
  final columns = cells.first.length;
  final rows = cells.length;
  final floor = floorSource.trimRight().split(RegExp(r'\r?\n'));
  if (floor.length != rows ||
      floor.any(
        (row) => row.length != columns || !RegExp(r'^[X0.\-]+$').hasMatch(row),
      )) {
    throw const FormatException(
      'Route 1 floor must match the object grid and use -, ., X or 0.',
    );
  }
  // X/0 are reference markers on the floor draft, not collision or extra gates.
  final floorCells = [
    for (final row in floor) row.replaceAll(RegExp('[X0]'), '-'),
  ];
  final torches = <Offset>[];
  final props = <MapProp>[];
  final buildings = <MapBuilding>[];
  final houseCells = <Offset>{};
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      final position = Offset(x.toDouble(), y.toDouble());
      switch (cells[y][x]) {
        case 'i':
          torches.add(position);
        case 'r':
          props.add(MapProp(PropKind.rock, position, solid: true));
        case 'C':
          props.add(MapProp(PropKind.chest, position, solid: true));
        case 'h':
          if (houseCells.contains(position)) continue;
          if (y == 0 ||
              y + 1 >= rows ||
              x + 2 >= columns ||
              [
                for (var dy = 0; dy < 2; dy++)
                  for (var dx = 0; dx < 3; dx++) cells[y + dy][x + dx],
              ].any((symbol) => symbol != 'h')) {
            throw const FormatException(
              'House footprints must be 2 rows by 3 columns.',
            );
          }
          houseCells.addAll([
            for (var dy = 0; dy < 2; dy++)
              for (var dx = 0; dx < 3; dx++)
                position + Offset(dx.toDouble(), dy.toDouble()),
          ]);
          buildings.add(
            MapBuilding(
              id: 'route-house-${buildings.length}',
              bounds: Rect.fromLTWH(x.toDouble(), y - 1.0, 3, 3),
              footprint: Rect.fromLTWH(x.toDouble(), y.toDouble(), 3, 2),
              wallZ: WorldZ.actor,
              roofZ: WorldZ.roof,
            ),
          );
      }
    }
  }
  final south = cells.last.indexOf('0');
  final southEnd = cells.last.lastIndexOf('0');
  if (south < 0 ||
      !RegExp(r'^0+$').hasMatch(cells.last.substring(south, southEnd + 1))) {
    throw const FormatException(
      'Route 1 needs a contiguous southern gate to Cresca.',
    );
  }
  final spawn = Offset(((south + southEnd) ~/ 2).toDouble(), rows - 2.0);
  final map = ExplorationMap(
    area: WorldArea.routeOne,
    name: 'Route 1',
    subtitle: 'The broken road to Lubia',
    columns: columns,
    rows: rows,
    spawn: spawn,
    cells: List.unmodifiable(cells),
    floorCells: List.unmodifiable(floorCells),
    buildings: List.unmodifiable(buildings),
    torches: List.unmodifiable(torches),
    props: List.unmodifiable(props),
    npcs: const [],
    roadAt: (x, y) =>
        x >= 0 && y >= 0 && x < columns && y < rows && floorCells[y][x] == '.',
    exits: [
      AreaExit(
        id: 'Cresca',
        trigger: Rect.fromLTWH(
          south.toDouble(),
          rows - 1.0,
          (southEnd - south + 1).toDouble(),
          1,
        ),
        destination: WorldArea.town,
        arrival: const Offset(29, 1),
        style: AreaTransitionStyle.south,
      ),
    ],
  );
  if (map.isSolid(spawn.dx.toInt(), spawn.dy.toInt())) {
    throw const FormatException('Route 1 southern arrival must be walkable.');
  }
  return map;
}
