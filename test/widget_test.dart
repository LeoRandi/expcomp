import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Directional controls move one square and respect all edges', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final player = find.byKey(const ValueKey('player'));
    final start = tester.getTopLeft(player);
    final tile = tester.getSize(player).width;
    Future<void> move(String direction) async {
      await tester.tap(find.byKey(ValueKey('move-$direction')));
      await tester.pumpAndSettle();
    }

    await move('up');
    expect(tester.getTopLeft(player).dy, closeTo(start.dy - tile, .01));
    await move('left');
    expect(tester.getTopLeft(player).dx, closeTo(start.dx - tile, .01));
    await move('down');
    await move('right');
    expect(tester.getTopLeft(player), start);
    for (final direction in ['up', 'left', 'down', 'right']) {
      for (var i = 0; i < 7; i++) {
        await move(direction);
      }
      final edge = tester.getTopLeft(player);
      await move(direction);
      expect(tester.getTopLeft(player), edge);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(player).dx, closeTo(start.dx + 2 * tile, .01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Portrait layout fits and player information opens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('Youngest of Cresca'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Youngest of Cresca'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
