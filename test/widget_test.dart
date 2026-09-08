import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Camera follows across a 20 by 20 world at two-thirds tile scale',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      final player = find.byKey(const ValueKey('player'));
      final world = find.byKey(const ValueKey('world-grid'));
      final viewport = find.byKey(const ValueKey('world-viewport'));
      final center = tester.getCenter(viewport);
      // The previous 800x600 layout used (600 - 88) * .62 pixels for its board.
      const tile = (600 - 88) * .62 / 10.5 * 1.25;
      expect(tester.getSize(viewport), const Size(800, 600));
      expect(tester.getSize(player).width, closeTo(tile, .01));
      final npc = find.byKey(const ValueKey('npc'));
      expect(tester.getSize(npc), tester.getSize(player));
      expect(tester.getCenter(npc).dx, closeTo(center.dx, .01));
      expect(tester.getCenter(npc).dy, closeTo(center.dy - tile, .01));
      expect(tester.getSize(world).width, closeTo(tile * 20, .01));
      expect(tester.getSize(world).height, closeTo(tile * 20, .01));
      expect(tester.getCenter(player), center);
      var column = 10;
      var row = 10;
      Future<void> move(String direction, int dx, int dy) async {
        final before = tester.getTopLeft(world);
        var nextColumn = (column + dx).clamp(0, 19);
        var nextRow = (row + dy).clamp(0, 19);
        final hitsNpc = nextColumn == 10 && nextRow == 9;
        if (hitsNpc) {
          nextColumn = column;
          nextRow = row;
        }
        await tester.tap(find.byKey(ValueKey('move-$direction')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(tester.getCenter(player), center);
        if (nextColumn != column || nextRow != row) {
          final distance = (tester.getTopLeft(world) - before).distance;
          expect(distance, greaterThan(0));
          expect(distance, lessThan(tile));
        }
        await tester.pumpAndSettle();
        final after = tester.getTopLeft(world);
        expect(
          after.dx,
          closeTo(before.dx - (nextColumn - column) * tile, .01),
        );
        expect(after.dy, closeTo(before.dy - (nextRow - row) * tile, .01));
        expect(tester.getCenter(player), center);
        column = nextColumn;
        row = nextRow;
        if (hitsNpc) {
          expect(find.text('Ready to meet your end?'), findsOneWidget);
          expect(find.byKey(const ValueKey('npc-portrait')), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(world), after);
          await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
          await tester.pumpAndSettle();
          expect(find.text('Ready to meet your end?'), findsNothing);
        }
      }

      await move('up', 0, -1);
      await move('left', -1, 0);
      await move('up', 0, -1);
      await move('right', 1, 0);
      await move('up', 0, -1);
      await move('right', 1, 0);
      await move('down', 0, 1);
      await move('left', -1, 0);
      await move('up', 0, -1);
      await move('left', -1, 0);
      await move('down', 0, 1);
      await move('right', 1, 0);
      await move('down', 0, 1);
      await move('right', 1, 0);
      for (final direction in [
        ('up', 0, -1),
        ('left', -1, 0),
        ('down', 0, 1),
        ('right', 1, 0),
      ]) {
        for (var i = 0; i < 21; i++) {
          await move(direction.$1, direction.$2, direction.$3);
        }
      }
      final beforeKey = tester.getTopLeft(world);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world).dx, closeTo(beforeKey.dx + tile, .01));
      expect(tester.getCenter(player), center);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Portrait layout fits and player information opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byKey(const ValueKey('world-viewport'))),
      const Size(390, 844),
    );
    expect(
      (tester.getCenter(find.byKey(const ValueKey('player'))) -
              tester.getCenter(find.byKey(const ValueKey('world-viewport'))))
          .distance,
      lessThan(.01),
    );
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Youngest of Cresca'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-player-info')));
    await tester.pumpAndSettle();
    expect(find.text('Youngest of Cresca'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('move-up')));
    await tester.pumpAndSettle();
    expect(find.text('Ready to meet your end?'), findsOneWidget);
    final portrait = tester.getRect(find.byKey(const ValueKey('npc-portrait')));
    expect(
      portrait.bottom,
      lessThan(tester.getTopLeft(find.text('Ready to meet your end?')).dy),
    );
    await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
