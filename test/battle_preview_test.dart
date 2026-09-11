import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_move.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/battle/active_ally_border.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<BattleCreature> fixture() => [
  for (var i = 0; i < 4; i++)
    BattleCreature(
      id: '${i < 2 ? 'ally' : 'enemy'}-${i % 2}',
      name: 'Creature $i',
      side: i < 2 ? BattleSide.allies : BattleSide.enemies,
      slot: i % 2,
      stats: tinyBot.baseStats,
      asset: tinyBot.frontAsset,
      moves: [wavelectrify, psybite, brancheal],
    ),
];

void main() {
  test(
    'Preview matches resolution while preserving live HP, stats and cooldown',
    () {
      final roster = fixture();
      roster[2].magicalResistance = 2;
      roster[3].flameWardActive = true;
      final action = BattleAction(roster[0], wavelectrify);
      final predicted = previewActionHp(action, roster);
      expect(predicted['enemy-0'], 133);
      expect(predicted['enemy-1'], 160);
      expect(predicted['ally-0'], lessThan(160));
      expect(roster.every((c) => c.hp == 160), isTrue);
      expect(roster[2].magicalResistance, 2);
      expect(roster[0].lastUsedMove, isNull);
      resolveAction(action, roster);
      expect({
        for (final creature in roster) creature.id: creature.hp,
      }, predicted);
    },
  );

  testWidgets(
    'Selection highlights targets, blinks damage and clears without applying it',
    (tester) async {
      final roster = fixture();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: BattlePage(roster: roster),
        ),
      );
      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
      }

      Future<void> choose(String name) async {
        final labels = find.descendant(
          of: find.byKey(const ValueKey('ally-hexagon-0')),
          matching: find.byType(Text),
        );
        final label = labels.evaluate().firstWhere(
          (e) => (e.widget as Text).data!.endsWith(name),
        );
        expect((label.widget as Text).style!.fontSize, 12);
        await tester.tap(find.byWidget(label.widget));
        await settle();
      }

      await settle();
      await choose('WAVELECTRIFY');
      for (var i = 0; i < 2; i++) {
        final border = tester.widget<ActiveAllyBorder>(
          find.byKey(ValueKey('target-enemy-$i')),
        );
        expect(border.color, Colors.red);
        final bar = tester.widget<PixelResourceBar>(
          find.byKey(ValueKey('hp-enemy-$i')),
        );
        expect(bar.value, 160);
        expect(bar.previewValue, 146);
      }
      expect(find.byType(PixelDamagePreview), findsNWidgets(2));
      final flashingBox = find.descendant(
        of: find.byType(PixelDamagePreview).first,
        matching: find.byType(ColoredBox),
      );
      final color = tester.widget<ColoredBox>(flashingBox).color;
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.widget<ColoredBox>(flashingBox).color, isNot(color));
      await choose('PSYBITE');
      expect(find.byKey(const ValueKey('target-enemy-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('target-enemy-1')), findsNothing);
      expect(find.byType(PixelDamagePreview), findsOneWidget);
      await choose('BRANCHEAL');
      expect(find.byKey(const ValueKey('target-ally-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('target-enemy-0')), findsNothing);
      expect(find.byType(PixelDamagePreview), findsNothing);
      await tester.tap(find.byKey(const ValueKey('confirm-move')));
      await settle();
      expect(find.byKey(const ValueKey('target-ally-1')), findsNothing);
      expect(find.byKey(const ValueKey('active-ally-1')), findsOneWidget);
      expect(roster.every((c) => c.hp == 160), isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}
