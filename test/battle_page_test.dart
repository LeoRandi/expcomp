import 'package:expcomp/main.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/battle/active_ally_border.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/party/creature_source_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets(
      'Two sources, stable hexagons, pulsing selection and continues beyond three rounds at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Future<void> settle() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
        }

        Future<void> tap(String key) async {
          await tester.tap(find.byKey(ValueKey(key)));
          await settle();
        }

        Finder option(int ally, int move) => find.descendant(
          of: find.byKey(ValueKey('ally-hexagon-$ally')),
          matching: find.byKey(ValueKey('move-option-$move')),
        );
        PixelButton confirm() => tester.widget<PixelButton>(
          find.byKey(const ValueKey('confirm-move')),
        );
        PixelUiThemeData skin(String key) =>
            PixelUiThemeData.of(tester.element(find.byKey(ValueKey(key))));
        await tester.pumpWidget(const MyApp());
        await settle();
        await tap('move-up');
        await tap('start-battle');
        expect(find.byType(BattlePage), findsOneWidget);
        for (final key in ['ally-0', 'ally-1', 'enemy-0', 'enemy-1']) {
          expect(find.byKey(ValueKey(key)), findsOneWidget);
        }
        for (final entry in {
          'hp-ally-0': CreatureSource.koredull,
          'hp-ally-1': CreatureSource.undiria,
          'hp-enemy-0': CreatureSource.raida,
          'hp-enemy-1': CreatureSource.undiria,
        }.entries) {
          expect(skin(entry.key).atlas, themeForSource(entry.value).atlas);
        }
        for (final name in ['Pip', 'Vesper', 'Thorn Wisp', 'Ember Beetle']) {
          expect(find.text(name), findsOneWidget);
        }
        expect(find.byIcon(Icons.arrow_downward), findsNothing);
        final stateRect = tester.getRect(
          find.byKey(const ValueKey('combat-state-panel')),
        );
        final commandRect = tester.getRect(
          find.byKey(const ValueKey('combat-command-panel')),
        );
        expect(stateRect.height, commandRect.height);
        final lastUsed = <int, String>{};
        for (var round = 1; round <= 3; round++) {
          for (var ally = 0; ally < 2; ally++) {
            expect(confirm().onPressed, isNull);
            expect(
              skin('combat-command-panel').atlas,
              themeForSource(
                ally == 0 ? CreatureSource.koredull : CreatureSource.undiria,
              ).atlas,
            );
            expect(find.byKey(ValueKey('active-ally-$ally')), findsOneWidget);
            expect(find.byType(ActiveAllyBorder), findsOneWidget);
            final fade = find.descendant(
              of: find.byKey(ValueKey('active-ally-$ally')),
              matching: find.byType(FadeTransition),
            );
            final opacity = tester.widget<FadeTransition>(fade).opacity.value;
            await tester.pump(const Duration(milliseconds: 150));
            expect(
              tester.widget<FadeTransition>(fade).opacity.value,
              isNot(opacity),
            );
            for (var move = 0; move < 3; move++) {
              expect(
                tester.widget<Text>(option(ally, move)).data!.split('\n').last,
                isNot(lastUsed[ally]),
              );
            }
            final hex = find.byKey(ValueKey('ally-hexagon-$ally'));
            final before = tester.getSize(hex);
            lastUsed[ally] = tester
                .widget<Text>(option(ally, 0))
                .data!
                .split('\n')
                .last;
            await tester.tap(option(ally, 0));
            await settle();
            expect(tester.getSize(hex), before);
            expect(
              tester.getRect(hex).bottom,
              lessThan(
                tester.getRect(find.byKey(const ValueKey('confirm-move'))).top,
              ),
            );
            expect(confirm().onPressed, isNotNull);
            await tester.tap(find.byKey(const ValueKey('confirm-move')));
            await tester.pump();
            if (ally == 0) await settle();
          }
          expect(find.byType(ActiveAllyBorder), findsNothing);
          final sizeDuringAction = tester.getSize(
            find.byKey(const ValueKey('ally-hexagon-1')),
          );
          await tester.pump(const Duration(milliseconds: 200));
          expect(
            tester.getSize(find.byKey(const ValueKey('ally-hexagon-1'))),
            sizeDuringAction,
          );
          for (var i = 0; i < 23; i++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          await settle();
        }
        expect(find.byType(BattlePage), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
