import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_move.dart';
import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final losingSide in BattleSide.values) {
    testWidgets(
      'Combat continues past round three until $losingSide is defeated',
      (tester) async {
        // One damage per hit. The only move sits out alternate rounds,
        // so the third and lethal hit lands in round five.
        const strike = BattleMove(
          id: 'strike',
          name: 'STRIKE',
          split: MoveSplit.physical,
          target: MoveTarget.closestEnemy,
          potency: 1,
        );
        final roster = [
          for (final side in BattleSide.values)
            BattleCreature(
              id: side.name,
              name: side.name,
              side: side,
              slot: 0,
              stats: tinyBot.baseStats,
              moves: [strike],
              asset: tinyBot.frontAsset,
              currentHp: side == losingSide ? 3 : 160,
            ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [SunderedKeepUi.theme]),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => BattlePage(roster: roster),
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        for (var round = 1; round <= 5; round++) {
          await tester.tap(find.byKey(const ValueKey('move-option-0')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('confirm-move')));
          await tester.pump();
          for (var tick = 0; tick < 15; tick++) {
            await tester.pump(const Duration(milliseconds: 200));
          }
          if (round < 5) expect(find.byType(BattlePage), findsOneWidget);
        }
        expect(roster.firstWhere((c) => c.side == losingSide).hp, 0);
        expect(find.byType(BattlePage), findsNothing);
        expect(find.text('Start'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
