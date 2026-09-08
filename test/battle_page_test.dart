import 'package:expcomp/main.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('NPC starts battle and two commands resolve a round at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('move-up')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('start-battle')));
      await tester.pumpAndSettle();
      expect(find.byType(BattlePage), findsOneWidget);
      expect(find.byKey(const ValueKey('npc-portrait')), findsNothing);
      for (final key in ['enemy-0', 'enemy-1', 'ally-0', 'ally-1']) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      PixelButton confirm() => tester.widget<PixelButton>(
        find.byKey(const ValueKey('confirm-move')),
      );
      expect(confirm().onPressed, isNull);
      expect(find.byKey(const ValueKey('ally-hexagon-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('ally-hexagon-1')), findsOneWidget);
      Rect hexagon(int ally) =>
          tester.getRect(find.byKey(ValueKey('ally-hexagon-$ally')));
      expect(hexagon(0).width, greaterThan(hexagon(1).width));
      expect(hexagon(0).overlaps(hexagon(1)), isTrue);
      expect(hexagon(1).right, greaterThan(hexagon(0).right));
      final button = find.byKey(const ValueKey('confirm-move'));
      final panel = tester.widget<PixelPanel>(
        find.descendant(of: button, matching: find.byType(PixelPanel)),
      );
      expect(panel.expanded, isTrue);
      expect(tester.getSize(button).width, closeTo(size.width - 32, .01));
      Finder option(int ally, int move) => find.descendant(
        of: find.byKey(ValueKey('ally-hexagon-$ally')),
        matching: find.byKey(ValueKey('move-option-$move')),
      );
      // The exposed inactive half must not select a command.
      await tester.tapAt(Offset(hexagon(1).right - 12, hexagon(1).center.dy));
      await tester.pumpAndSettle();
      expect(confirm().onPressed, isNull);
      await tester.tap(option(0, 0));
      await tester.pumpAndSettle();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('confirm-move')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ally-hexagon-1')), findsOneWidget);
      expect(hexagon(1).width, greaterThan(hexagon(0).width));
      expect(hexagon(0).overlaps(hexagon(1)), isTrue);
      expect(hexagon(0).left, lessThan(hexagon(1).left));
      expect(confirm().onPressed, isNull);
      await tester.tap(option(1, 2));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-move')));
      await tester.pump();
      expect(find.text('Ally 1 uses Move 1'), findsOneWidget);
      expect(confirm().onPressed, isNull);
      await tester.pump(const Duration(milliseconds: 650));
      expect(find.text('Ally 2 uses Move 3'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 650));
      }
      await tester.pumpAndSettle();
      expect(find.text('ROUND 2'), findsOneWidget);
      expect(find.byKey(const ValueKey('ally-hexagon-0')), findsOneWidget);
      expect(confirm().onPressed, isNull);
      await tester.tap(find.byKey(const ValueKey('leave-battle')));
      await tester.pumpAndSettle();
      expect(find.byType(BattlePage), findsNothing);
      await tester.tap(find.byKey(const ValueKey('move-up')));
      await tester.pumpAndSettle();
      expect(find.text('Ready to meet your end?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('npc-portrait')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
