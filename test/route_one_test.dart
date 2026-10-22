import 'dart:io';
import 'dart:ui' as ui;

import 'package:expcomp/exploration/area_transition.dart';
import 'package:expcomp/exploration/cresca_town.dart';
import 'package:expcomp/exploration/exploration_page.dart';
import 'package:expcomp/exploration/route_one.dart';
import 'package:expcomp/exploration/route_one_scenery.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/player/player.dart';
import 'package:expcomp/inventory/item_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exploration_test_support.dart';

Future<void> _captureRoute(
  WidgetTester tester,
  GlobalKey screen,
  String name,
) async {
  await tester.runAsync(() async {
    final image =
        await (screen.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(
      'build/route1-$name.png',
    ).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setupExplorationMaps();
  setUp(PixelAtlasCache.clear);
  final source = File(routeOneTextAsset).readAsStringSync();
  final floorSource = File(routeOneFloorAsset).readAsStringSync();
  final chestSource = File(routeOneChestsAsset).readAsStringSync();
  final gateSource = File(routeOneGatesAsset).readAsStringSync();
  final map = parseRouteOne(
    source,
    floorSource: floorSource,
    chestSource: chestSource,
    gateSource: gateSource,
  );

  test(
    'Route 1 uses the author map for terrain, collision, lights and house',
    () {
      expect(
        Size(map.columns.toDouble(), map.rows.toDouble()),
        const Size(55, 55),
      );
      for (var y = 0; y < map.rows; y++) {
        for (var x = 0; x < map.columns; x++) {
          final symbol = map.tileAt(x, y)!;
          expect(
            map.isSolid(x, y),
            'XrhC'.contains(symbol),
            reason: '$symbol at $x,$y',
          );
          expect(map.isGrass(x, y), symbol == 'g');
          expect(
            map.isRoad(x, y),
            !map.isSolid(x, y) && map.floorAt(x, y) == '.',
          );
        }
      }
      expect(map.isSolid(-1, 10), isTrue);
      expect(map.isSolid(55, 10), isTrue);
      expect(map.torches, hasLength('i'.allMatches(map.cells!.join()).length));
      expect(
        map.props.where((p) => p.kind == PropKind.rock),
        hasLength('r'.allMatches(map.cells!.join()).length),
      );
      expect(
        map.props.where((p) => p.kind == PropKind.chest),
        hasLength('C'.allMatches(map.cells!.join()).length),
      );
      expect(
        map.props.every((p) => p.solid && !p.isReadable && p.lines.isEmpty),
        isTrue,
      );
      expect(map.npcs, isEmpty);
      expect(map.buildings.single.footprint, const Rect.fromLTWH(18, 14, 3, 2));
      expect(map.buildings.single.bounds, const Rect.fromLTWH(18, 13, 3, 3));
      expect(map.isSolid(18, 16), isFalse, reason: 'Doorstep stays clear.');
      final north = crescaTown.exits.singleWhere((e) => e.id == 'north');
      expect(north.destination, WorldArea.routeOne);
      expect(north.arrival, map.spawn);
      expect(map.exits.single.trigger, const Rect.fromLTWH(26, 54, 3, 1));
      expect(map.exits.single.destination, WorldArea.town);
      expect(map.exits.single.arrival, const Offset(29, 1));
      expect(
        map.isSolid(27, 0),
        isFalse,
      ); // Future Lubia gate, not connected yet.
      expect(map.isSolid(54, 4), isFalse); // Future Route 2 gate.
    },
  );

  test('Malformed maps fail before entering a broken scene', () {
    expect(
      () => parseRouteOne(
        'X0X\nX-X\nX0',
        floorSource: floorSource,
        chestSource: chestSource,
        gateSource: gateSource,
      ),
      throwsFormatException,
    );
    expect(
      () => parseRouteOne(
        source.replaceFirst('X', '?'),
        floorSource: floorSource,
        chestSource: chestSource,
        gateSource: gateSource,
      ),
      throwsFormatException,
    );
    expect(
      () => parseRouteOne(
        source.replaceFirst('hhh', 'hh-'),
        floorSource: floorSource,
        chestSource: chestSource,
        gateSource: gateSource,
      ),
      throwsFormatException,
    );
    expect(
      () => parseRouteOne(
        source,
        floorSource: floorSource.substring(1),
        chestSource: chestSource,
        gateSource: gateSource,
      ),
      throwsFormatException,
    );
    expect(
      () => parseRouteOne(
        source,
        floorSource: floorSource.replaceFirst('-', 'g'),
        chestSource: chestSource,
        gateSource: gateSource,
      ),
      throwsFormatException,
    );
  });

  test(
    'Numbered chest map assigns catalog rewards and validates definitions',
    () {
      final chests = {
        for (final prop in map.props.where((p) => p.chest != null))
          prop.chest!.id: prop.chest!,
      };
      expect(chests.length, 8);
      expect(chests['r1:2']!.item, meat);
      expect(chests['r1:2']!.quantity, 2);
      expect(chests['r1:3']!.item, moonlessNecklace);
      expect(chests['r1:3']!.quantity, 1);
      expect(chests.values.where((chest) => chest.item == null).length, 6);
      for (final invalid in [
        chestSource.replaceFirst('Meat x 2', 'Missing item x 2'),
        chestSource.replaceFirst('Meat x 2', 'Meat x 0'),
        chestSource.replaceFirst('1: None', '2: None'),
        chestSource.replaceFirst('7', '-'),
      ]) {
        expect(
          () => parseRouteOne(
            source,
            floorSource: floorSource,
            chestSource: invalid,
            gateSource: gateSource,
          ),
          throwsFormatException,
        );
      }
    },
  );

  test('Players claim each chest once, including empty ones', () {
    final player = Player();
    expect(player.openChest('r1:2', item: meat, quantity: 2), isTrue);
    expect(player.inventory.quantityOf(meat), 2);
    expect(player.openChest('r1:2', item: meat, quantity: 2), isFalse);
    expect(player.inventory.quantityOf(meat), 2);
    expect(player.openChest('r1:1'), isTrue);
    expect(player.hasOpenedChest('r1:1'), isTrue);
    expect(player.openChest('r1:1'), isFalse);
    expect(Player().hasOpenedChest('r1:2'), isFalse);
    expect(
      () => player.openChest('bad', item: meat, quantity: 0),
      throwsArgumentError,
    );
    expect(player.hasOpenedChest('bad'), isFalse);
  });

  test('Floor and object layers remain independent under rocks and gates', () {
    expect(map.tileAt(4, 6), 'r');
    expect(map.floorAt(4, 6), '.');
    expect(map.isSolid(4, 6), isTrue);
    expect(map.tileAt(26, 54), '-');
    expect(map.floorAt(26, 54), '.');
    expect(map.isSolid(26, 54), isFalse);
    expect(map.floorAt(54, 4), '-', reason: 'The eastern gate has stone ground.');
    final floors = floorSource.trimRight().split(RegExp(r'\r?\n'));
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        expect(map.floorAt(x, y), floors[y][x] == '.' ? '.' : '-');
      }
    }
  });

  testWidgets(
    'Sand continues under rocks and gates independently of object path marks',
    (tester) async {
      await warmExplorationAssets(tester);
      final sample = ExplorationMap(
        area: WorldArea.routeOne,
        name: 'Sample',
        subtitle: '',
        columns: 3,
        rows: 1,
        spawn: Offset.zero,
        buildings: const [],
        torches: const [],
        npcs: const [],
        roadAt: (_, _) => false,
        cells: const ['r0.'],
        floorCells: const ['..-'],
      );
      final screen = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: screen,
              child: SizedBox(
                width: 192,
                height: 64,
                child: ColoredBox(
                  color: const Color(0xFFFF00FF),
                  child: RouteOneTerrain(map: sample),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image =
            await (screen.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        int color(int x, int y) => pixels.getUint32((y * image.width + x) * 4);
        expect(color(32, 32), color(96, 32));
        expect(color(32, 32), isNot(0xFF00FFFF));
        expect(
          color(160, 32),
          0xFF00FFFF,
          reason: 'Object . cannot override stone floor.',
        );
        image.dispose();
      });
    },
  );

  testWidgets(
    'Grass hides exactly the lower half, while empty ground does not',
    (tester) async {
      await warmExplorationAssets(tester);
      await tester.runAsync(() async {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
      final screen = GlobalKey();
      for (final symbol in ['g', '-']) {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: screen,
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: GrassCoveredSprite(
                    covered: symbol == 'g',
                    child: const ColoredBox(color: Color(0xFFFF0000)),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (screen.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          bool red(int x, int y) {
            final i = (y * image.width + x) * 4;
            return bytes.getUint8(i) == 255 &&
                bytes.getUint8(i + 1) == 0 &&
                bytes.getUint8(i + 2) == 0;
          }

          for (var y = 0; y < 64; y++) {
            for (var x = 0; x < 64; x++) {
              expect(
                red(x, y),
                symbol != 'g' || y < 32,
                reason: '$symbol at pixel $x,$y',
              );
            }
          }
          image.dispose();
        });
      }
    },
  );

  for (final size in [const Size(800, 600), const Size(390, 844)]) {
    testWidgets('North road reaches Route 1 and south gate returns at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await warmExplorationAssets(tester);
      final player = Player.demo();
      final inventory = player.inventory;
      final screen = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: RepaintBoundary(
            key: screen,
            child: ExplorationPage(player: player),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await walkExplorationTo(tester, const Offset(29, 1));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(
        tester
            .widget<AreaTransitionOverlay>(find.byType(AreaTransitionOverlay))
            .style,
        AreaTransitionStyle.north,
      );
      await finishAreaTransition(tester);
      expect(find.byKey(const ValueKey(WorldArea.routeOne)), findsOneWidget);
      expect(explorationPlayerTile(tester), map.spawn);
      expect(find.byType(RouteOneTerrain), findsOneWidget);
      expect(find.byKey(const ValueKey('player-grass-cover')), findsNothing);
      await walkExplorationTo(tester, const Offset(17, 52), map: map);
      expect(map.isGrass(17, 52), isTrue);
      expect(find.byKey(const ValueKey('player-grass-cover')), findsOneWidget);
      if (size.width == 800) {
        await _captureRoute(tester, screen, 'grass');
      }
      await walkExplorationTo(tester, const Offset(17, 50), map: map);
      expect(find.byKey(const ValueKey('player-grass-cover')), findsNothing);
      for (final direction in [
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowDown,
      ]) {
        await tester.sendKeyEvent(direction);
        await tester.pump();
        for (final ms in [1, 29, 45, 74, 1]) {
          await tester.pump(Duration(milliseconds: ms));
          final cover = find.byKey(const ValueKey('player-grass-cover'));
          expect(
            cover,
            findsOneWidget,
            reason: 'Cover stays on during vertical grass movement.',
          );
          expect(
            tester.getRect(cover),
            tester.getRect(find.byKey(const ValueKey('player'))),
          );
        }
      }
      await stepExploration(
        tester,
        const Offset(0, 1),
      ); // Leave grass at 17,50.
      expect(find.byKey(const ValueKey('player-grass-cover')), findsNothing);
      await walkExplorationTo(tester, const Offset(21, 35), map: map);
      await stepExploration(tester, const Offset(1, 0)); // Chest at 22,35.
      expect(explorationPlayerTile(tester), const Offset(21, 35));
      expect(find.text('You got a Moonless necklace x 1'), findsOneWidget);
      expect(player.inventory.quantityOf(moonlessNecklace), 1);
      final chestSemantics = find.descendant(
        of: find.byKey(const ValueKey('route-prop-chest-22-35')),
        matching: find.byType(Semantics),
      );
      expect(
        tester.widget<Semantics>(chestSemantics).properties.label,
        'Open chest',
      );
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.text("It's empty..."), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      expect(player.inventory, same(inventory));
      if (size.width == 800) await _captureRoute(tester, screen, 'chest');
      await walkExplorationTo(tester, const Offset(34, 38), map: map);
      await tester.tap(find.byKey(const ValueKey('route-prop-chest-33-38')));
      await tester.pumpAndSettle();
      expect(find.text('You got a Meat x 2'), findsOneWidget);
      expect(player.inventory.quantityOf(meat), 2);
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.text("It's empty..."), findsOneWidget);
      expect(player.inventory.quantityOf(meat), 2);
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      await walkExplorationTo(tester, const Offset(43, 28), map: map);
      await tester.tap(find.byKey(const ValueKey('interact-npc')));
      await tester.pumpAndSettle();
      expect(find.text("It's empty..."), findsOneWidget);
      expect(player.hasOpenedChest('r1:4'), isTrue);
      expect(player.inventory.quantityOf(meat), 2);
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      await walkExplorationTo(tester, const Offset(19, 16), map: map);
      await stepExploration(tester, const Offset(0, -1)); // Closed house.
      expect(explorationPlayerTile(tester), const Offset(19, 16));
      if (size.width == 800) await _captureRoute(tester, screen, 'house');
      await walkExplorationTo(tester, const Offset(8, 51), map: map);
      await stepExploration(tester, const Offset(0, 1)); // Solid rock at 8,52.
      expect(explorationPlayerTile(tester), const Offset(8, 51));
      if (size.width == 800) await _captureRoute(tester, screen, 'rocks');
      await walkExplorationTo(tester, map.spawn, map: map);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(
        tester
            .widget<AreaTransitionOverlay>(find.byType(AreaTransitionOverlay))
            .style,
        AreaTransitionStyle.south,
      );
      await finishAreaTransition(tester);
      expect(find.byKey(const ValueKey(WorldArea.town)), findsOneWidget);
      expect(explorationPlayerTile(tester), const Offset(29, 1));
      expect(player.inventory, same(inventory));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      await finishAreaTransition(tester);
      await walkExplorationTo(tester, const Offset(21, 35), map: map);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      expect(find.text("It's empty..."), findsOneWidget);
      expect(player.inventory.quantityOf(moonlessNecklace), 1);
      expect(
        tester.widget<Semantics>(chestSemantics).properties.label,
        'Open chest',
      );
      await tester.tap(find.byKey(const ValueKey('close-chest-dialogue')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Route 1 can load as the initial scene', (tester) async {
    await warmExplorationAssets(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [SunderedKeepUi.theme]),
        home: const ExplorationPage(initialArea: WorldArea.routeOne),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey(WorldArea.routeOne)), findsOneWidget);
    expect(explorationPlayerTile(tester), map.spawn);
    expect(tester.takeException(), isNull);
  });
}
