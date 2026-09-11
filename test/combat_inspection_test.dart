import 'dart:math';
import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/creatures/innate_ability.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/party/creature_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Twilight Fortune rolls once for both allies, stacks, caps, and requires a living bearer',
    () {
      final choices = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final roster = createShowcaseBattle();
        final allies = roster
            .where((c) => c.side == BattleSide.allies)
            .toList();
        expect(allies[1].innate, twilightFortune);
        beginRound(roster, Random(seed));
        final critical = allies[0].criticalChance > allies[0].stats.cri;
        choices.add(critical ? 'CRI' : 'EVA');
        for (final ally in allies) {
          expect(ally.criticalChance - ally.stats.cri, critical ? 5 : 0);
          expect(ally.criticalEvasion - ally.stats.eva, critical ? 0 : 5);
        }
        expect(roster.last.criticalChance, roster.last.stats.cri);
      }
      expect(choices, {'CRI', 'EVA'});
      final roster = createShowcaseBattle();
      final random = Random(5);
      for (var round = 0; round < 100; round++) {
        beginRound(roster, random);
      }
      expect(roster[0].criticalChance, 100);
      expect(roster[0].criticalEvasion, 100);
      roster[0].criticalChance = 20;
      roster[0].criticalEvasion = 20;
      roster[1].hp = 0;
      beginRound(roster, random);
      expect(roster[0].criticalChance, 20);
      expect(roster[0].criticalEvasion, 20);
    },
  );

  testWidgets(
    'Every sprite opens source-themed read-only details with signed modifiers',
    (tester) async {
      final roster = createShowcaseBattle();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: BattlePage(roster: roster, random: Random(3)),
        ),
      );
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      await settle();
      roster[0].prowess = roster[0].stats.pro + 5.0;
      roster[2].prowess = roster[2].stats.pro - 5.0;
      for (var i = 0; i < roster.length; i++) {
        await tester.longPress(find.byKey(ValueKey(roster[i].id)));
        await settle();
        final page = tester.widget<CreatureInfoPage>(
          find.byType(CreatureInfoPage),
        );
        expect(page.readOnly, isTrue);
        expect(page.creature.name, roster[i].name);
        expect(page.creature.species.frontAsset, roster[i].species!.frontAsset);
        for (final key in [
          'info-save',
          'rename-creature',
          'plus-PRO',
          'minus-PRO',
          'change-move-0',
        ]) {
          expect(find.byKey(ValueKey(key)), findsNothing);
        }
        if (i == 0 || i == 2) {
          final modifier = tester.widget<Text>(
            find.byKey(const ValueKey('combat-delta-PRO')),
          );
          expect(modifier.data, i == 0 ? '+5' : '-5');
          expect(
            modifier.style!.color,
            i == 0 ? Colors.greenAccent : Colors.redAccent,
          );
        }
        await tester.tap(find.byKey(const ValueKey('info-back')));
        await settle();
      }
      // Start resolving, then inspect: health and action state stay frozen until Back.
      for (var ally = 0; ally < 2; ally++) {
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey('ally-hexagon-$ally')),
            matching: find.byKey(const ValueKey('move-option-0')),
          ),
        );
        await settle();
        await tester.tap(find.byKey(const ValueKey('confirm-move')));
        await tester.pump();
        if (ally == 0) await settle();
      }
      await tester.longPress(find.byKey(const ValueKey('enemy-0')));
      await settle();
      expect(find.byType(CreatureInfoPage), findsOneWidget);
      final health = roster.map((c) => c.hp).toList();
      for (var tick = 0; tick < 20; tick++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(roster.map((c) => c.hp).toList(), health);
      await tester.tap(find.byKey(const ValueKey('info-back')));
      await tester.pump();
      for (var tick = 0; tick < 25; tick++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(CreatureInfoPage), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
