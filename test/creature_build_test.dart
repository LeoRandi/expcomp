import 'dart:math';
import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_move.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/innate_ability.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Level-one build has ten reusable points and validates before saving',
    () {
      final creature = Creature(
        id: 'test',
        name: 'Pip',
        species: tinyBot,
        stats: tinyBot.baseStats,
        currentHp: 150,
        source: CreatureSource.koredull,
      );
      expect(creature.pointBudget, 10);
      creature.saveBuild({'CON': 10}, creature.equippedMoves);
      expect(creature.stats.con, 26);
      expect(creature.currentHp, 250);
      creature.saveBuild({'MPR': 10}, creature.equippedMoves);
      expect(creature.stats.con, 16);
      expect(creature.stats.mpr, 24);
      expect(creature.currentHp, 150);
      expect(
        () => creature.saveBuild({'MPR': 11}, creature.equippedMoves),
        throwsArgumentError,
      );
      expect(creature.stats.mpr, 24);
      expect(
        () => creature.saveBuild({}, [psybite, psybite, null, null, null]),
        throwsArgumentError,
      );
    },
  );

  test(
    'Demo loadouts have five moves, draw three unique choices, exclude last use',
    () {
      final roster = createShowcaseBattle();
      for (final creature in roster) {
        expect(creature.level, 1);
        expect(creature.moves.length, 5);
        expect(creature.innate, isNotNull);
      }
      final random = Random(12);
      final draws = <String>{};
      for (var round = 0; round < 50; round++) {
        final previous = roster.first.lastUsedMove;
        dealRoundMoves(roster, random);
        final choices = roster.first.offeredMoves.map((m) => m.id).toList();
        expect(choices.toSet().length, 3);
        expect(choices, isNot(contains(previous)));
        draws.add(choices.join(','));
        resolveAction(
          BattleAction(roster.first, roster.first.offeredMoves.first),
          roster,
        );
      }
      expect(draws.length, greaterThan(5));
      final empty = BattleCreature(
        id: 'empty',
        name: 'Empty',
        side: BattleSide.allies,
        slot: 0,
        stats: tinyBot.baseStats,
        moves: [],
        asset: '',
      );
      dealRoundMoves([empty], random);
      expect(empty.offeredMoves.single, waitMove);
    },
  );

  test(
    'Innates apply on entry, protect allies only, and heal living actors',
    () {
      BattleCreature actor(
        String id,
        BattleSide side,
        int slot,
        InnateAbility? innate,
      ) => BattleCreature(
        id: id,
        name: id,
        side: side,
        slot: slot,
        stats: tinyBot.baseStats,
        moves: moveCatalog,
        asset: '',
        innate: innate,
      );
      final bot = actor('bot', BattleSide.allies, 0, selfRepair);
      final wisp = actor('wisp', BattleSide.enemies, 0, shelteringBoughs);
      final beetle = actor('beetle', BattleSide.enemies, 1, imposingShell);
      final roster = [bot, wisp, beetle];
      enterCombat(roster);
      expect(bot.prowess, 4); // 5 - round(25% of 5).
      enterCombat(roster);
      expect(bot.prowess, 4);
      bot.hp = 100;
      resolveAction(BattleAction(bot, wavelectrify), roster);
      expect(wisp.hp, lessThan(wisp.stats.maxHp));
      expect(beetle.hp, beetle.stats.maxHp);
      expect(bot.hp, 108);
      resolveAction(BattleAction(bot, psyclash), roster);
      expect(beetle.hp, lessThan(beetle.stats.maxHp));
      wisp.hp = 0;
      final before = beetle.hp;
      resolveAction(BattleAction(bot, wavelectrify), roster);
      expect(beetle.hp, lessThan(before));
      bot.hp = 0;
      resolveAction(BattleAction(bot, waitMove), roster);
      expect(bot.hp, 0);
      expect(flameward.split, MoveSplit.blessing);
      expect(poweride.split, MoveSplit.curse);
    },
  );
}
