import 'package:expcomp/exploration/area_transition.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exploration_test_support.dart';

Finder _arrow(String name) => find.byKey(ValueKey('move-$name'));

Future<TestGesture> _press(
  WidgetTester tester,
  String name, {
  int? pointer,
}) async {
  final gesture = await tester.startGesture(
    tester.getCenter(_arrow(name)),
    pointer: pointer,
  );
  await tester.pump();
  return gesture;
}

Future<void> _testingArea(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp(initialArea: WorldArea.testing));
  await tester.pumpAndSettle();
}

void main() {
  setUp(PixelAtlasCache.clear);

  testWidgets(
    'Tap steps once, then a held arrow repeats at 0.7s and each .2s',
    (tester) async {
      await _testingArea(tester);
      final hold = await _press(tester, 'down');
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      await tester.pump(const Duration(milliseconds: 500));
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      await tester.pump(const Duration(milliseconds: 199));
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      await tester.pump(const Duration(milliseconds: 1));
      expect(explorationPlayerTile(tester), const Offset(10, 12));
      await tester.pump(const Duration(milliseconds: 199));
      expect(explorationPlayerTile(tester), const Offset(10, 12));
      await tester.pump(const Duration(milliseconds: 1));
      expect(explorationPlayerTile(tester), const Offset(10, 13));
      await tester.pump(const Duration(milliseconds: 400));
      expect(explorationPlayerTile(tester), const Offset(10, 15));
      await hold.up();
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(10, 15));
      await tester.tap(_arrow('down'));
      await tester.pumpAndSettle();
      expect(explorationPlayerTile(tester), const Offset(10, 16));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'A short press and dragging off the diamond both cancel repetition',
    (tester) async {
      await _testingArea(tester);
      final short = await _press(tester, 'down');
      await tester.pump(const Duration(milliseconds: 400));
      await short.up();
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      final drag = await _press(tester, 'down');
      final center = tester.getCenter(_arrow('down'));
      await tester.pump(const Duration(milliseconds: 400));
      await drag.moveTo(Offset.zero);
      await tester.pump(const Duration(seconds: 2));
      await drag.moveTo(center);
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(10, 12));
      await drag.up();
      await tester.pumpAndSettle();
      expect(explorationPlayerTile(tester), const Offset(10, 12));
    },
  );

  testWidgets('Pointer cancellation stops an already repeating arrow', (
    tester,
  ) async {
    await _testingArea(tester);
    final hold = await _press(tester, 'down');
    await tester.pump(const Duration(milliseconds: 700));
    expect(explorationPlayerTile(tester), const Offset(10, 12));
    await hold.cancel();
    await tester.pump(const Duration(seconds: 2));
    expect(explorationPlayerTile(tester), const Offset(10, 12));
  });

  testWidgets(
    'A new held direction replaces the old one; old release cannot cancel it',
    (tester) async {
      await _testingArea(tester);
      final down = await _press(tester, 'down');
      await tester.pump(const Duration(milliseconds: 500));
      final left = await _press(tester, 'left');
      expect(explorationPlayerTile(tester), const Offset(9, 11));
      await tester.pump(const Duration(milliseconds: 400));
      await down.up();
      await tester.pump(const Duration(milliseconds: 300));
      expect(explorationPlayerTile(tester), const Offset(8, 11));
      await tester.pump(const Duration(milliseconds: 200));
      expect(explorationPlayerTile(tester), const Offset(7, 11));
      await left.up();
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(7, 11));
    },
  );

  testWidgets(
    'Walking into an NPC cancels the hold, including after the dialogue closes',
    (tester) async {
      await _testingArea(tester);
      await tester.tap(_arrow('down'));
      await tester.tap(_arrow('down'));
      await tester.pumpAndSettle();
      final hold = await _press(tester, 'up');
      await tester.pump(const Duration(milliseconds: 900));
      await tester.pumpAndSettle();
      expect(find.text('Ready to meet your end?'), findsOneWidget);
      expect(explorationPlayerTile(tester), const Offset(10, 10));
      await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Ready to meet your end?'), findsNothing);
      expect(explorationPlayerTile(tester), const Offset(10, 10));
      await hold.up();
      await tester.tap(_arrow('down'));
      await tester.pumpAndSettle();
      expect(explorationPlayerTile(tester), const Offset(10, 11));
    },
  );

  testWidgets(
    'Opening a menu stops held movement without restarting on close',
    (tester) async {
      await _testingArea(tester);
      final hold = await _press(tester, 'down');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byKey(const ValueKey('open-party')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      await tester.tap(find.byKey(const ValueKey('close-party')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      expect(explorationPlayerTile(tester), const Offset(10, 11));
      await hold.up();
      await tester.tap(_arrow('down'));
      await tester.pumpAndSettle();
      expect(explorationPlayerTile(tester), const Offset(10, 12));
    },
  );

  testWidgets('Losing app focus stops held movement until a new press', (
    tester,
  ) async {
    addTearDown(
      () => tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      ),
    );
    await _testingArea(tester);
    final hold = await _press(tester, 'down');
    await tester.pump(const Duration(milliseconds: 700));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));
    expect(explorationPlayerTile(tester), const Offset(10, 12));
    await hold.up();
  });

  testWidgets('Held movement cannot resume after crossing an area boundary', (
    tester,
  ) async {
    await warmExplorationAssets(tester);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await walkExplorationTo(tester, const Offset(29, 3));
    final hold = await _press(tester, 'up');
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byType(AreaTransitionOverlay), findsOneWidget);
    await finishAreaTransition(tester);
    await tester.pump(const Duration(seconds: 2));
    expect(explorationPlayerTile(tester), const Offset(27, 53));
    await hold.up();
    await tester.tap(_arrow('up'));
    await tester.pumpAndSettle();
    expect(explorationPlayerTile(tester), const Offset(27, 52));
    expect(tester.takeException(), isNull);
  });

  for (final repeating in [false, true]) {
    testWidgets(
      'Disposal cancels ${repeating ? 'repetition' : 'the hold delay'}',
      (tester) async {
        await _testingArea(tester);
        final hold = await _press(tester, 'down');
        if (repeating) await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpWidget(const SizedBox.shrink());
        await hold.up();
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
