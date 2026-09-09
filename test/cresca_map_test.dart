import 'package:expcomp/exploration/cresca_map.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Two solid houses fit in the map and are reached by the road', () {
    expect(crescaHouses.length, 2);
    for (final house in crescaHouses) {
      for (var y = house.top.toInt(); y < house.bottom; y++) {
        for (var x = house.left.toInt(); x < house.right; x++) {
          expect(isHouseTile(x, y), isTrue);
          expect(isRoadTile(x, y), isFalse);
          expect(x, inInclusiveRange(0, 19));
          expect(y, inInclusiveRange(0, 19));
        }
      }
      expect(isRoadTile(house.center.dx.floor(), house.bottom.toInt()), isTrue);
    }
    expect(isRoadTile(10, 10), isTrue);
  });

  testWidgets('Closed house doors block movement without opening dialogue', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final world = find.byKey(const ValueKey('world-grid'));
    Future<void> step(LogicalKeyboardKey key, [int count = 1]) async {
      for (var i = 0; i < count; i++) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }
    }

    await step(LogicalKeyboardKey.arrowLeft, 4);
    await step(LogicalKeyboardKey.arrowUp);
    final firstDoor = tester.getTopLeft(world);
    await step(LogicalKeyboardKey.arrowUp, 2);
    expect(tester.getTopLeft(world), firstDoor);
    expect(find.byKey(const ValueKey('npc-portrait')), findsNothing);

    // Go around the NPC along row 10, then follow the east branch.
    await step(LogicalKeyboardKey.arrowDown);
    await step(LogicalKeyboardKey.arrowRight, 7);
    await step(LogicalKeyboardKey.arrowUp, 4);
    final secondDoor = tester.getTopLeft(world);
    await step(LogicalKeyboardKey.arrowUp, 2);
    expect(tester.getTopLeft(world), secondDoor);
    expect(find.byKey(const ValueKey('npc-portrait')), findsNothing);
    await step(LogicalKeyboardKey.arrowRight);
    expect(tester.getTopLeft(world), isNot(secondDoor));
    expect(tester.takeException(), isNull);
  });
}
