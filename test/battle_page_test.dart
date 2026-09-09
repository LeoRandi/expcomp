import 'package:expcomp/main.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('NPC starts battle and one command resolve a round at $size', (
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
      for (final key in ['enemy-0', 'enemy-1', 'ally-0']) {
        expect(find.byKey(ValueKey(key)), findsOneWidget);
      }
      PixelButton confirm() => tester.widget<PixelButton>(
        find.byKey(const ValueKey('confirm-move')),
      );
      expect(confirm().onPressed, isNull);
      expect(find.byKey(const ValueKey('ally-hexagon-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('ally-hexagon-1')), findsNothing);
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
      void expectLabelsInsideSectors() {
        for (var ally = 0; ally < 1; ally++) {
          for (var move = 0; move < 3; move++) {
            final label = option(ally, move);
            final clip = find
                .ancestor(of: label, matching: find.byType(ClipPath))
                .first;
            final clipBox = tester.renderObject<RenderBox>(clip);
            final path = tester
                .widget<ClipPath>(clip)
                .clipper!
                .getClip(clipBox.size);
            final bounds = tester.getRect(label);
            for (final corner in [
              bounds.topLeft,
              bounds.topRight,
              bounds.bottomLeft,
              bounds.bottomRight,
            ]) {
              expect(
                path.contains(clipBox.globalToLocal(corner)),
                isTrue,
                reason:
                    'Ally $ally move $move must fit entirely inside its sector',
              );
            }
          }
        }
      }

      expectLabelsInsideSectors();
      await tester.tap(option(0, 0));
      await tester.pumpAndSettle();
      expect(confirm().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('confirm-move')));
      await tester.pump();
      expect(find.textContaining('FLAMEWARD'), findsWidgets);
      expect(confirm().onPressed, isNull);
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      await tester.pumpAndSettle();
      expect(find.byType(BattlePage), findsOneWidget);
      expect(find.byKey(const ValueKey('leave-battle')), findsNothing);
      final hpBars = tester.widgetList<PixelResourceBar>(
        find.byType(PixelResourceBar),
      );
      expect(hpBars.any((bar) => bar.value < bar.maximum), isTrue);
      for (var round = 2; round <= 3; round++) {
        expect(confirm().onPressed, isNull);
        await tester.tap(option(0, 2));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('confirm-move')));
        await tester.pump();
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        await tester.pumpAndSettle();
        if (round == 2) expect(find.byType(BattlePage), findsOneWidget);
      }
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
