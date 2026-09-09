import 'dart:math';
import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/battle/battle_move.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:flutter_test/flutter_test.dart';

CreatureStats stats({int speed = 10, int res = 12, int mre = 8}) =>
    CreatureStats(
      con: 10,
      pro: 30,
      mpr: 50,
      res: res,
      mre: mre,
      cri: 0,
      eva: 0,
      spe: speed,
    );
BattleCreature actor(String id, BattleSide side, int slot, {int speed = 10}) =>
    BattleCreature(
      id: id,
      name: id,
      side: side,
      slot: slot,
      stats: stats(speed: speed),
      moves: moveCatalog,
      asset: '',
    );

void main() {
  test(
    'Priority precedes speed, with fresh random ordering for exact ties',
    () {
      final fast = actor('fast', BattleSide.allies, 0, speed: 100);
      final slow = actor('slow', BattleSide.allies, 1, speed: 1);
      final tie = actor('tie', BattleSide.enemies, 0, speed: 100);
      final lowest = actor('lowest', BattleSide.enemies, 1, speed: 200);
      final orders = <String>{};
      for (var seed = 0; seed < 30; seed++) {
        final ordered = orderActions([
          BattleAction(fast, psybite),
          BattleAction(slow, flameward),
          BattleAction(tie, psybite),
          BattleAction(lowest, poweride),
        ], Random(seed));
        expect(ordered.first.user, slow);
        expect(ordered.last.user, lowest);
        orders.add(ordered.map((a) => a.user.id).join(','));
      }
      expect(orders.length, 2);
      expect(
        orderActions([
          BattleAction(slow, psybite),
          BattleAction(fast, psybite),
        ], Random(0)).first.user,
        fast,
      );
    },
  );

  test(
    'Damage uses the matching offensive and defensive stats and floors at one',
    () {
      expect(calculateDamage(psybite, stats(), stats()), 38);
      expect(calculateDamage(psyclash, stats(), stats()), 52);
      expect(calculateDamage(wavelectrify, stats(), stats()), 57);
      expect(calculateDamage(psybite, stats(), stats(res: 1000)), 1);
      expect(calculateDamage(flameward, stats(), stats()), 0);
      expect(calculateDamage(brancheal, stats(), stats()), 0);
    },
  );

  test(
    'Targets are positional, healthiest by current HP, and ordered for multiple targets',
    () {
      final a = actor('a', BattleSide.allies, 0);
      final b = actor('b', BattleSide.allies, 1);
      final c = actor('c', BattleSide.enemies, 0);
      final d = actor('d', BattleSide.enemies, 1);
      final roster = [d, b, c, a];
      List<BattleCreature> targets(BattleCreature user, BattleMove move) =>
          targetsFor(BattleAction(user, move), roster);
      expect(targets(a, psybite), [c]);
      expect(targets(a, psyclash), [d]);
      expect(targets(b, psybite), [d]);
      expect(targets(b, psyclash), [c]);
      expect(targets(c, psybite), [a]);
      expect(targets(c, psyclash), [b]);
      expect(targets(a, wavelectrify), [c, d]);
      expect(targets(b, brancheal), [a, b]);
      expect(targets(a, flameward), [a]);
      expect(targets(b, poweride), [a, c, d]);
      expect(targets(d, poweride), [c, a, b]);
      c.hp = 20;
      expect(targets(a, headrip), [d]);
      c.hp = 0;
      expect(targets(a, psybite), [d]);
      expect(targets(a, wavelectrify), [d]);
      d.hp = 0;
      expect(targets(a, headrip), isEmpty);
    },
  );

  test(
    'Defense drops round, persist through rounds, and affect later damage',
    () {
      final roster = fourCreatureFixture();
      final user = roster[0];
      final enemy = roster[2];
      final before = enemy.hp;
      resolveAction(BattleAction(user, piercecrash), roster);
      expect(enemy.hp, before - 9);
      expect(enemy.resistance, 5); // 10% of 5 rounds up to 1.
      final after = enemy.hp;
      resolveAction(BattleAction(user, psybite), roster);
      expect(enemy.hp, after - 20);
      final far = roster[3];
      resolveAction(BattleAction(user, psyclash), roster);
      expect(far.magicalResistance, 5); // 10% of 12 rounds to 1.
      endRound(roster);
      expect(enemy.resistance, 5);
      expect(far.magicalResistance, 5);
      expect(user.stats.pro, 5); // Base stats never mutate.
    },
  );

  test('Healing caps at maximum HP and does not revive defeated creatures', () {
    final roster = fourCreatureFixture();
    roster[0].hp = 60;
    roster[1].hp = 50;
    final results = resolveAction(BattleAction(roster[0], brancheal), roster);
    expect(results.map((r) => r.healing), [20, 22]);
    expect(roster[0].hp, 80);
    expect(roster[1].hp, 72);
    roster[1].hp = 0;
    resolveAction(BattleAction(roster[0], brancheal), roster);
    expect(roster[1].hp, 0);
  });

  test(
    'Flameward blocks damage and debuffs, reflects every hit, expires after round',
    () {
      final roster = fourCreatureFixture();
      final defender = roster[2];
      final attacker = roster[0];
      resolveAction(BattleAction(defender, flameward), roster);
      for (var i = 0; i < 2; i++) {
        final before = attacker.hp;
        final results = resolveAction(
          BattleAction(attacker, piercecrash),
          roster,
        );
        expect(defender.hp, 80);
        expect(defender.resistance, 6);
        expect(attacker.hp, before - 5); // round(12*.2 + 10*.3)
        expect(results.last.damage, 5);
      }
      endRound(roster);
      expect(defender.flameWardActive, isFalse);
      resolveAction(BattleAction(attacker, piercecrash), roster);
      expect(defender.hp, 71);
    },
  );

  test(
    'POWERIDE snapshots rounded reduction and gains only the amount available',
    () {
      final roster = fourCreatureFixture();
      final user = roster[3];
      user.prowess = 15;
      roster[0].prowess = 1;
      roster[1].prowess = 0;
      final total = roster.fold<double>(0, (sum, c) => sum + c.prowess);
      final results = resolveAction(BattleAction(user, poweride), roster);
      expect(results.take(3).map((r) => r.target.id), [
        'enemy-0',
        'ally-0',
        'ally-1',
      ]);
      expect(roster[2].prowess, 3);
      expect(roster[0].prowess, 0);
      expect(roster[1].prowess, 0);
      expect(user.prowess, 18);
      expect(roster.fold<double>(0, (sum, c) => sum + c.prowess), total);
    },
  );

  test(
    'Reflection cannot recurse; a reflected knockout stops remaining targets',
    () {
      final roster = fourCreatureFixture();
      final user = roster[1];
      user.hp = 1;
      user.flameWardActive = true;
      roster[2].flameWardActive = true;
      final untouched = roster[3].hp;
      resolveAction(BattleAction(user, wavelectrify), roster);
      expect(user.hp, 0);
      expect(roster[2].hp, 80);
      expect(roster[3].hp, untouched);
      expect(resolveAction(BattleAction(user, psybite), roster), isEmpty);
    },
  );
}

List<BattleCreature> fourCreatureFixture() => [
  for (final side in BattleSide.values)
    for (var i = 0; i < 2; i++)
      BattleCreature(
        id: '${side == BattleSide.allies ? 'ally' : 'enemy'}-$i',
        name: '${side.name}-$i',
        side: side,
        slot: i,
        stats: [thornWisp, emberBeetle][i].baseStats,
        moves: moveCatalog,
        asset: '',
      ),
];
