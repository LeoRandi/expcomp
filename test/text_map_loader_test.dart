import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expcomp/exploration/text_map_loader.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/exploration/world_maps.dart';
import 'package:expcomp/main.dart';
import 'exploration_test_support.dart';

Map<String, String> sources(WorldArea area) => {
  for (final layer in mapLayers)
    layer: File(worldMapAsset(area, layer)).readAsStringSync(),
};

ExplorationMap parse(WorldArea area, Map<String, String> layers) =>
    parseTextMap(
      areaId: mapPrefixes[area]!,
      objectSource: layers['objects']!,
      floorSource: layers['floor']!,
      chestSource: layers['chests']!,
      gateSource: layers['gates']!,
    );

void main() {
  setupExplorationMaps();
  test('All areas use four independent layers with matching dimensions', () {
    for (final area in WorldArea.values) {
      final map = parse(area, sources(area));
      expect(map.area, area);
      expect(map.cells!.length, map.rows);
      expect(map.floorCells!.length, map.rows);
      expect(map.gates, isNotEmpty);
      expect(map.isSolid(map.spawn.dx.toInt(), map.spawn.dy.toInt()), isFalse);
      if (area != WorldArea.routeOne) {
        expect(map.props.where((prop) => prop.chest != null), isEmpty);
        expect(map.npcs.length, switch (area) {
          WorldArea.town => 7,
          WorldArea.testing => 2,
          _ => 0,
        });
      }
    }
  });

  test('Floor, NPC and gate edits affect only their own data', () {
    final layers = sources(WorldArea.town);
    final original = parse(WorldArea.town, layers);
    // Change floor under the stranger without moving him or changing collision.
    final floorRows = layers['floor']!.trimRight().split(RegExp(r'\r?\n'));
    floorRows[25] = floorRows[25].replaceRange(21, 22, '.');
    final floor = parse(WorldArea.town, {
      ...layers,
      'floor': floorRows.join('\n'),
    });
    expect(floor.floorAt(21, 25), '.');
    expect(floor.tileAt(21, 25), '1');
    expect(floor.npcs.first.name, original.npcs.first.name);
    expect(floor.isSolid(21, 25), original.isSolid(21, 25));
    final npc = parse(WorldArea.town, {
      ...layers,
      'objects': layers['objects']!.replaceFirst(
        '"name": "Mara"',
        '"name": "Mara the Baker"',
      ),
    });
    expect(npc.npcs.singleWhere((n) => n.id == 'mara').name, 'Mara the Baker');
    expect(npc.exits.first.arrival, original.exits.first.arrival);
    final gates = parse(WorldArea.town, {
      ...layers,
      'gates': layers['gates']!.replaceFirst('"north"', '"Northern passage"'),
    });
    expect(gates.exits.first.id, 'Northern passage');
    expect(gates.cells, original.cells);
    expect(gates.floorCells, original.floorCells);
  });

  test(
    'Object legends configure player light with a validated legacy fallback',
    () {
      const radii = {
        WorldArea.town: 6.0,
        WorldArea.testing: 6.0,
        WorldArea.routeOne: 2.0,
        WorldArea.crescaIndoors: 100.0,
      };
      for (final area in WorldArea.values) {
        expect(parse(area, sources(area)).lightRadius, radii[area]);
      }
      final layers = sources(WorldArea.crescaIndoors);
      final setting = RegExp(r'"light radius":\s*100');
      final original = parse(WorldArea.crescaIndoors, layers);
      final changed = parse(WorldArea.crescaIndoors, {
        ...layers,
        'objects': layers['objects']!.replaceFirst(
          setting,
          '"light radius": 1.5',
        ),
      });
      expect(changed.lightRadius, 1.5);
      expect(changed.cells, original.cells);
      expect(changed.floorCells, original.floorCells);
      final fallback = parse(WorldArea.crescaIndoors, {
        ...layers,
        'objects': layers['objects']!.replaceFirst(
          RegExp(r'\s*"light radius":\s*100,'),
          '',
        ),
      });
      expect(fallback.lightRadius, 6);
      for (final invalid in ['0', '-1', '"bright"', 'true', '1e999']) {
        expect(
          () => parse(WorldArea.crescaIndoors, {
            ...layers,
            'objects': layers['objects']!.replaceFirst(
              setting,
              '"light radius": $invalid',
            ),
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('Gate data owns NPC teleports and inactive future routes', () {
    final town = parse(WorldArea.town, sources(WorldArea.town));
    final stranger = town.npcs.singleWhere((n) => n.id == 'stranger');
    expect(stranger.action, NpcAction.travel);
    final link = town.gates.singleWhere((g) => g.number == stranger.gate);
    expect(link.automatic, isFalse);
    expect(link.exit!.destination, WorldArea.testing);
    expect(link.exit!.arrival, const Offset(10, 10));
    final route = parse(WorldArea.routeOne, sources(WorldArea.routeOne));
    expect(route.gates.length, 3);
    expect(
      route.gates.where((g) => g.exit == null).map((g) => g.destinationName),
      ['lubia', 'route2'],
    );
    expect(route.exits.single.destination, WorldArea.town);
  });

  test(
    'Invalid independent layer dimensions and numbered legends are rejected',
    () {
      final layers = sources(WorldArea.town);
      expect(
        () => parse(WorldArea.town, {
          ...layers,
          'floor': layers['floor']!.substring(1),
        }),
        throwsFormatException,
      );
      expect(
        () => parse(WorldArea.town, {
          ...layers,
          'objects': layers['objects']!.replaceFirst('"1": {', '"8": {'),
        }),
        throwsFormatException,
      );
      expect(
        () => parse(WorldArea.town, {
          ...layers,
          'gates': layers['gates']!.replaceFirst('"1": {', '"8": {'),
        }),
        throwsFormatException,
      );
    },
  );

  testWidgets('A new game shows an empty inventory', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('open-inventory')));
    await tester.pumpAndSettle();
    expect(find.text('No items in this category.'), findsOneWidget);
    expect(find.byKey(const ValueKey('inventory-item-meat')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('inventory-tab-equipment')));
    await tester.pumpAndSettle();
    expect(find.text('No items in this category.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('inventory-item-moonless_necklace')),
      findsNothing,
    );
  });
}
