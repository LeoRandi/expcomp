import 'dart:io';
import 'dart:ui' as ui;

import 'package:expcomp/exploration/area_transition.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/exploration/world_maps.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exploration_test_support.dart';

void main() {
  setupExplorationMaps();

  test(
    'Nine furnished rooms have 12x12 floors and isolated black surrounds',
    () {
      final map = loadedWorldMap(WorldArea.crescaIndoors);
      expect(
        Size(map.columns.toDouble(), map.rows.toDouble()),
        const Size(110, 110),
      );
      final remaining = <Offset>{
        for (var y = 0; y < map.rows; y++)
          for (var x = 0; x < map.columns; x++)
            if (map.floorAt(x, y) == 'W') Offset(x.toDouble(), y.toDouble()),
      };
      final rooms = <Rect>[];
      while (remaining.isNotEmpty) {
        final queue = [remaining.first];
        remaining.remove(queue.first);
        for (var i = 0; i < queue.length; i++) {
          for (final d in const [
            Offset(1, 0),
            Offset(-1, 0),
            Offset(0, 1),
            Offset(0, -1),
          ]) {
            final next = queue[i] + d;
            if (remaining.remove(next)) queue.add(next);
          }
        }
        final bounds = queue
            .map((p) => p & const Size(1, 1))
            .reduce((a, b) => a.expandToInclude(b));
        expect(bounds.size, const Size(14, 14)); // Walls enclose 12x12 floors.
        expect(queue.length, 196);
        final furniture = map.props
            .where((p) => bounds.contains(p.position))
            .map((p) => p.kind);
        expect(
          furniture,
          containsAll([
            PropKind.table,
            PropKind.chair,
            PropKind.cushions,
            PropKind.bookcase,
            PropKind.rug,
          ]),
        );
        rooms.add(bounds);
      }
      expect(rooms.length, 9);
      for (var a = 0; a < rooms.length; a++) {
        for (var b = a + 1; b < rooms.length; b++) {
          expect(rooms[a].inflate(10).overlaps(rooms[b].inflate(10)), isFalse);
        }
      }
      for (var y = 0; y < map.rows; y++) {
        for (var x = 0; x < map.columns; x++) {
          if (map.floorAt(x, y) == '#') {
            expect(map.tileAt(x, y), '#');
            expect(map.isSolid(x, y), isTrue);
          }
        }
      }
      expect(map.tileAt(map.spawn.dx.toInt(), map.spawn.dy.toInt()), 'k');
      expect(map.isSolid(map.spawn.dx.toInt(), map.spawn.dy.toInt()), isFalse);
      for (final chair in map.props.where((p) => p.kind == PropKind.chair)) {
        expect(chair.solid, isFalse);
        expect(
          map.isSolid(chair.position.dx.toInt(), chair.position.dy.toInt()),
          isFalse,
        );
      }
      expect(map.exits.single.destination, WorldArea.town);
      final door = loadedWorldMap(
        WorldArea.town,
      ).gates.singleWhere((g) => g.door);
      expect(door.exit!.destination, WorldArea.crescaIndoors);
      expect(door.exit!.style, AreaTransitionStyle.circle);
      expect(map.exits.single.style, AreaTransitionStyle.circle);
      // Every active travel link lands on a usable cell, outside walk gates.
      for (final area in WorldArea.values) {
        for (final gate in loadedWorldMap(
          area,
        ).gates.where((g) => g.exit != null)) {
          final exit = gate.exit!;
          final target = loadedWorldMap(exit.destination);
          expect(
            target.isSolid(exit.arrival.dx.toInt(), exit.arrival.dy.toInt()),
            isFalse,
          );
          expect(
            target.exits.any(
              (e) => e.trigger.contains(exit.arrival + const Offset(.5, .5)),
            ),
            isFalse,
          );
        }
      }
    },
  );

  testWidgets(
    'New game starts on cushions, with black void outside the walls',
    (tester) async {
      await warmExplorationAssets(tester);
      // Use readable type in the optional local review image instead of Ahem.
      await tester.runAsync(() async {
        final font = File('C:/Windows/Fonts/consola.ttf');
        if (await font.exists()) {
          await (FontLoader(
            'monospace',
          )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
        }
      });
      final screen = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: screen, child: const MyApp()),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey(WorldArea.crescaIndoors)),
        findsOneWidget,
      );
      expect(explorationPlayerTile(tester), const Offset(16, 16));
      final viewport = tester.getCenter(
        find.byKey(const ValueKey('world-viewport')),
      );
      final tile = tester.getSize(find.byKey(const ValueKey('player'))).width;
      final voidPoint = viewport - Offset(tile * 3, tile * 3);
      await tester.runAsync(() async {
        final boundary =
            screen.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final index =
            (voidPoint.dy.floor() * image.width + voidPoint.dx.floor()) * 4;
        expect(
          [for (var c = 0; c < 4; c++) pixels.getUint8(index + c)],
          [0, 0, 0, 255],
        );
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          'build/cresca-home-start.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Chairs can be crossed while dining tables remain solid', (
    tester,
  ) async {
    await warmExplorationAssets(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final indoors = loadedWorldMap(WorldArea.crescaIndoors);
    await walkExplorationTo(tester, const Offset(22, 20), map: indoors);
    expect(explorationPlayerTile(tester), const Offset(22, 20));
    await stepExploration(tester, const Offset(0, 1));
    expect(explorationPlayerTile(tester), const Offset(22, 20));
    await stepExploration(tester, const Offset(-1, 0));
    await stepExploration(tester, const Offset(1, 0));
    expect(explorationPlayerTile(tester), const Offset(22, 20));
    expect(tester.takeException(), isNull);
  });

  for (final interaction in ['keyboard', 'button', 'bump', 'tap']) {
    testWidgets(
      'Home exit and $interaction entrance use circular transitions',
      (tester) async {
        await warmExplorationAssets(tester);
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        final indoors = loadedWorldMap(WorldArea.crescaIndoors);
        await walkExplorationTo(tester, const Offset(20, 26), map: indoors);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(
          tester
              .widget<AreaTransitionOverlay>(find.byType(AreaTransitionOverlay))
              .style,
          AreaTransitionStyle.circle,
        );
        await finishAreaTransition(tester);
        expect(find.byKey(const ValueKey(WorldArea.town)), findsOneWidget);
        expect(explorationPlayerTile(tester), const Offset(20, 25));
        if (interaction == 'keyboard') {
          await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
        } else if (interaction == 'button') {
          await tester.tap(find.byKey(const ValueKey('interact-npc')));
        } else if (interaction == 'bump') {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        } else {
          await tester.tap(find.byKey(const ValueKey('door-6')));
        }
        await tester.pump();
        expect(
          tester
              .widget<AreaTransitionOverlay>(find.byType(AreaTransitionOverlay))
              .style,
          AreaTransitionStyle.circle,
        );
        await finishAreaTransition(tester);
        expect(
          find.byKey(const ValueKey(WorldArea.crescaIndoors)),
          findsOneWidget,
        );
        expect(explorationPlayerTile(tester), const Offset(20, 26));
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(AreaTransitionOverlay), findsNothing);
        expect(explorationPlayerTile(tester), const Offset(20, 26));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
