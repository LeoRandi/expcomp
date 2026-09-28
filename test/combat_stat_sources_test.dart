import 'dart:math';

import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_move.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/innate_ability.dart';
import 'package:flutter_test/flutter_test.dart';

BattleCreature actor(String id, BattleSide side, {InnateAbility? innate}) =>
    BattleCreature(
      id: id,
      name: id,
      side: side,
      slot: 0,
      asset: '',
      moves: moveCatalog,
      innate: innate,
      stats: const CreatureStats(
        con: 100,
        pro: 30,
        mpr: 40,
        res: 5,
        mre: 10,
        cri: 98,
        eva: 98,
        spe: 10,
      ),
    );

void expectAccounted(BattleCreature creature) {
  for (final stat in statNames) {
    final delta = (creature.statChanges[stat] ?? {}).values.fold(
      0,
      (a, b) => a + b,
    );
    expect(
      creature.combatStats[stat],
      creature.stats.values[stat]! + delta,
      reason: '$stat contributions must equal total',
    );
  }
}

void main() {
  test(
    'Repeated moves combine actual reductions and respect floors and wards',
    () {
      final user = actor('user', BattleSide.allies);
      final target = actor('target', BattleSide.enemies);
      final roster = [user, target];
      for (var i = 0; i < 3; i++) {
        resolveAction(BattleAction(user, piercecrash), roster);
      }
      expect(target.statChanges['RES'], {'PIERCECRASH': -5});
      resolveAction(BattleAction(user, psyclash), roster);
      resolveAction(BattleAction(user, psyclash), roster);
      expect(target.statChanges['MRE'], {'PSYCLASH': -8});
      target.flameWardActive = true;
      resolveAction(BattleAction(user, psyclash), roster);
      expect(target.statChanges['MRE'], {'PSYCLASH': -8});
      expectAccounted(target);
    },
  );

  test(
    'Abilities have their own rows and only applied capped amounts accumulate',
    () {
      final bearer = actor(
        'bearer',
        BattleSide.allies,
        innate: twilightFortune,
      );
      final enemy = actor('enemy', BattleSide.enemies, innate: imposingShell);
      final roster = [bearer, enemy];
      enterCombat(roster);
      enterCombat(roster);
      expect(bearer.statChanges['PRO'], {'Imposing Shell': -8});
      for (var i = 0; i < 30; i++) {
        beginRound(roster, Random(i));
      }
      expect(bearer.statChanges['CRI'], {'Twilight Fortune': 2});
      expect(bearer.statChanges['EVA'], {'Twilight Fortune': 2});
      resolveAction(BattleAction(bearer, poweride), roster);
      expect(bearer.statChanges['PRO'], {'Imposing Shell': -8, 'POWERIDE': 2});
      expect(enemy.statChanges['PRO'], {'POWERIDE': -2});
      expectAccounted(bearer);
      expectAccounted(enemy);
    },
  );

  test('Opposing uses of the same move cancel and remove its source row', () {
    final a = actor('a', BattleSide.allies);
    final b = actor('b', BattleSide.enemies);
    final roster = [a, b];
    resolveAction(BattleAction(a, poweride), roster);
    resolveAction(BattleAction(b, poweride), roster);
    expect(a.statChanges, isEmpty);
    expect(b.statChanges, isEmpty);
    expectAccounted(a);
    expectAccounted(b);
  });

  test(
    'Previews do not mutate sources and source snapshots cannot be edited',
    () {
      final a = actor('a', BattleSide.allies);
      final b = actor('b', BattleSide.enemies);
      a.changeStat('PRO', 2, source: 'POWERIDE');
      final before = a.statChanges;
      previewActionHp(BattleAction(a, poweride), [a, b]);
      expect(a.statChanges, before);
      expect(b.statChanges, isEmpty);
      expect(() => before['PRO']!['POWERIDE'] = 100, throwsUnsupportedError);
      a.changeStat('PRO', 1, source: 'POWERIDE');
      expect(before['PRO'], {'POWERIDE': 2});
      expectAccounted(a);
    },
  );
}
