import 'dart:convert';
import 'package:flutter/services.dart';
import '../inventory/item_catalog.dart';
import 'area_transition.dart';
import 'chest_contents.dart';
import 'cresca_map.dart';
import 'world_layers.dart';
import 'world_map.dart';

class TextMapLayer {
  TextMapLayer(String source, String allowed) {
    final lines = source.trimRight().split(RegExp(r'\r?\n'));
    var end = 0;
    while (end < lines.length &&
        lines[end].trim().isNotEmpty &&
        lines[end] != '---') {
      end++;
    }
    cells = List.unmodifiable(lines.take(end));
    if (cells.isEmpty ||
        cells.first.isEmpty ||
        cells.any(
          (row) =>
              row.length != cells.first.length ||
              !RegExp('^[$allowed]+\$').hasMatch(row),
        )) {
      throw const FormatException(
        'Map layer must be a rectangle of supported symbols.',
      );
    }
    legend = lines.skip(end).where((line) => line != '---').join('\n').trim();
  }
  late final List<String> cells;
  late final String legend;
  Map<String, dynamic> get metadata => legend.isEmpty
      ? {}
      : Map<String, dynamic>.from(jsonDecode(legend) as Map);
}

Offset _point(dynamic value) {
  final values = value as List;
  return Offset((values[0] as num).toDouble(), (values[1] as num).toDouble());
}

Map<String, List<Offset>> _numbers(TextMapLayer layer) {
  final result = <String, List<Offset>>{};
  for (var y = 0; y < layer.cells.length; y++) {
    for (var x = 0; x < layer.cells[y].length; x++) {
      final symbol = layer.cells[y][x];
      if (RegExp(r'[1-9]').hasMatch(symbol)) {
        result
            .putIfAbsent(symbol, () => [])
            .add(Offset(x.toDouble(), y.toDouble()));
      }
    }
  }
  return result;
}

List<MapGate> _gates(TextMapLayer layer) {
  final definitions = layer.metadata;
  final positions = _numbers(layer);
  if (definitions.length != positions.length ||
      !definitions.keys.every(positions.containsKey)) {
    throw const FormatException('Gate numbers and legend entries must match.');
  }
  final result = <MapGate>[];
  for (final number in definitions.keys) {
    final entry = MapEntry(number, positions[number]!);
    final data = definitions[entry.key] as Map;
    final rect = entry.value
        .map((p) => p & const Size(1, 1))
        .reduce((a, b) => a.expandToInclude(b));
    if (rect.width * rect.height != entry.value.length) {
      throw const FormatException(
        'A gate number must form one filled rectangle.',
      );
    }
    final destination = data['destination'] as String;
    final active = data['enabled'] != false;
    final style = AreaTransitionStyle.values.byName(data['style'] as String);
    final automatic = data['mode'] == 'walk';
    if (!const ['walk', 'interact'].contains(data['mode'])) {
      throw const FormatException('Gate mode must be walk or interact.');
    }
    result.add(
      MapGate(
        number: entry.key,
        destinationName: destination,
        trigger: rect,
        automatic: automatic,
        exit: active
            ? AreaExit(
                id: data['id'] as String,
                trigger: rect,
                destination: WorldArea.values.byName(destination),
                arrival: _point(data['arrival']),
                style: style,
              )
            : null,
      ),
    );
  }
  return result;
}

/// One parser for all areas. Each independently authored layer has one purpose.
ExplorationMap parseTextMap({
  required String areaId,
  required String objectSource,
  required String floorSource,
  required String chestSource,
  required String gateSource,
}) {
  final objects = TextMapLayer(objectSource, r'X.\-ighCrufvcbwspFGS1-9');
  final floor = TextMapLayer(floorSource, r'X0.\-=');
  final chests = TextMapLayer(chestSource, r'X.\-1-9');
  final gateLayer = TextMapLayer(gateSource, r'X.\-1-9');
  final rows = objects.cells.length;
  final columns = objects.cells.first.length;
  for (final layer in [floor, chests, gateLayer]) {
    if (layer.cells.length != rows || layer.cells.first.length != columns) {
      throw const FormatException(
        'All four map layers must have matching dimensions.',
      );
    }
  }
  final meta = objects.metadata;
  final gates = _gates(gateLayer);
  final contents = _parseChests(chests, objects.cells, areaId);
  final floorCells = [
    for (final row in floor.cells) row.replaceAll(RegExp('[X0]'), '-'),
  ];
  final torches = <Offset>[];
  final buildings = <MapBuilding>[];
  final props = <MapProp>[];
  final houseCells = <Offset>{};
  final buildingInfo = meta['buildings'] as Map? ?? {};
  final propInfo = meta['props'] as Map? ?? {};
  const kinds = {
    'r': PropKind.rock,
    'C': PropKind.chest,
    'u': PropKind.rubble,
    'f': PropKind.fungus,
    'v': PropKind.flowers,
    'c': PropKind.crates,
    'b': PropKind.bench,
    'w': PropKind.well,
    's': PropKind.stall,
    'p': PropKind.garden,
    'F': PropKind.fence,
    'G': PropKind.gate,
    'S': PropKind.sign,
  };
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      final symbol = objects.cells[y][x];
      final p = Offset(x.toDouble(), y.toDouble());
      if (symbol == 'i') torches.add(p);
      if (symbol == 'h' && !houseCells.contains(p)) {
        if (y == 0 ||
            y + 1 >= rows ||
            x + 2 >= columns ||
            [
              for (var dy = 0; dy < 2; dy++)
                for (var dx = 0; dx < 3; dx++) objects.cells[y + dy][x + dx],
            ].any((s) => s != 'h')) {
          throw const FormatException(
            'House footprints must be 2 rows by 3 columns.',
          );
        }
        houseCells.addAll([
          for (var dy = 0; dy < 2; dy++)
            for (var dx = 0; dx < 3; dx++)
              p + Offset(dx.toDouble(), dy.toDouble()),
        ]);
        final info = buildingInfo['$x,$y'] as Map? ?? {};
        buildings.add(
          MapBuilding(
            id: info['id'] as String? ?? '$areaId-house-${buildings.length}',
            bounds: Rect.fromLTWH(x.toDouble(), y - 1.0, 3, 3),
            footprint: Rect.fromLTWH(x.toDouble(), y.toDouble(), 3, 2),
            appearance: BuildingAppearance.values.byName(
              info['appearance'] as String? ?? 'cottage',
            ),
            wallZ: WorldZ.actor,
            roofZ: WorldZ.roof,
          ),
        );
      }
      final kind = kinds[symbol];
      if (kind != null) {
        final info = propInfo['$x,$y'] as Map? ?? {};
        props.add(
          MapProp(
            kind,
            p,
            label: info['label'] as String?,
            solid:
                info['solid'] as bool? ??
                !const [PropKind.flowers, PropKind.garden].contains(kind),
            lines: List<String>.from(info['lines'] as List? ?? []),
            chest: contents[p],
          ),
        );
      }
    }
  }
  final npcInfo = meta['npcs'] as Map? ?? {};
  final npcCells = _numbers(objects);
  if (npcCells.length != npcInfo.length ||
      !npcInfo.keys.every(npcCells.containsKey)) {
    throw const FormatException('NPC numbers must match the object legend.');
  }
  final npcs = <TownNpc>[];
  for (final number in npcInfo.keys.cast<String>()) {
    final entry = MapEntry(number, npcCells[number]!);
    if (entry.value.length != 1) {
      throw const FormatException('NPC numbers must be unique cells.');
    }
    final info = npcInfo[entry.key] as Map;
    final action = NpcAction.values.byName(info['action'] as String? ?? 'talk');
    final gate = info['gate'] as String?;
    if (action == NpcAction.travel &&
        !gates.any((g) => g.number == gate && !g.automatic && g.exit != null)) {
      throw const FormatException(
        'Travel NPC must reference an active interaction gate.',
      );
    }
    npcs.add(
      TownNpc(
        id: info['id'] as String,
        name: info['name'] as String,
        role: info['role'] as String,
        position: entry.value.single,
        asset: info['sprite'] as String,
        lines: List<String>.from(info['lines'] as List),
        action: action,
        gate: gate,
        tint: info['tint'] == null
            ? null
            : Color(int.parse(info['tint'] as String, radix: 16)),
        route: [for (final p in info['route'] as List? ?? []) _point(p)],
      ),
    );
  }
  final map = ExplorationMap(
    area: WorldArea.values.byName(meta['area'] as String),
    name: meta['name'] as String,
    subtitle: meta['subtitle'] as String,
    spawn: _point(meta['spawn']),
    columns: columns,
    rows: rows,
    cells: objects.cells,
    floorCells: List.unmodifiable(floorCells),
    buildings: List.unmodifiable(buildings),
    torches: List.unmodifiable(torches),
    props: List.unmodifiable(props),
    npcs: List.unmodifiable(npcs),
    gates: List.unmodifiable(gates),
  );
  if (map.isSolid(map.spawn.dx.toInt(), map.spawn.dy.toInt()) ||
      npcs.any(
        (npc) => map.isSolid(npc.position.dx.toInt(), npc.position.dy.toInt()),
      ) ||
      gates.any(
        (gate) =>
            gate.exit != null &&
            gate.automatic &&
            [
              for (final p in _numbers(gateLayer)[gate.number]!)
                map.isSolid(p.dx.toInt(), p.dy.toInt()),
            ].any((v) => v),
      )) {
    throw const FormatException(
      'Spawns, NPCs, and active walk gates must be walkable.',
    );
  }
  return map;
}

Map<Offset, ChestContents> _parseChests(
  TextMapLayer layer,
  List<String> objects,
  String areaId,
) {
  final rows = objects.length;
  final columns = objects.first.length;
  final definitions = <String, (Item?, int)>{};
  for (final line
      in layer.legend
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)) {
    final entry = RegExp(r'^\s*([1-9])\s*:\s*(.+?)\s*$').firstMatch(line);
    if (entry == null || definitions.containsKey(entry[1])) {
      throw const FormatException(
        'Invalid or duplicate chest contents definition.',
      );
    }
    final value = entry[2]!;
    if (value.toLowerCase() == 'none') {
      definitions[entry[1]!] = (null, 0);
      continue;
    }
    final reward = RegExp(
      r'^(.*?)(?:\s+x\s*(\d+))?$',
      caseSensitive: false,
    ).firstMatch(value)!;
    final name = reward[1]!
        .toLowerCase()
        .replaceFirst(RegExp(r'\s+item$'), '')
        .trim();
    final item = name == 'necklace'
        ? moonlessNecklace
        : itemCatalog.values
              .where(
                (item) => item.name.toLowerCase() == name || item.id == name,
              )
              .firstOrNull;
    final quantity = int.tryParse(reward[2] ?? '1') ?? 0;
    if (item == null || quantity <= 0) {
      throw FormatException(
        'Unknown item or invalid quantity in chest ${entry[1]}.',
      );
    }
    definitions[entry[1]!] = (item, quantity);
  }
  final result = <Offset, ChestContents>{};
  final used = <String>{};
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < columns; x++) {
      final symbol = layer.cells[y][x];
      final numbered = RegExp(r'[1-9]').hasMatch(symbol);
      if ((objects[y][x] == 'C') != numbered) {
        throw FormatException('Chest number must match a C at $x,$y.');
      }
      if (!numbered) continue;
      final reward = definitions[symbol];
      if (reward == null || !used.add(symbol)) {
        throw const FormatException(
          'Each chest needs a unique number and contents definition.',
        );
      }
      result[Offset(x.toDouble(), y.toDouble())] = ChestContents(
        id: '$areaId:$symbol',
        item: reward.$1,
        quantity: reward.$2,
      );
    }
  }
  if (used.length != definitions.length) {
    throw const FormatException('Chest definitions contain an unused number.');
  }
  return result;
}
