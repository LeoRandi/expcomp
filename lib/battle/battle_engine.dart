import 'dart:math';
import '../creatures/creature.dart';
import '../creatures/showcase_party.dart';
import 'battle_move.dart';
import 'turn_order.dart';

enum BattleSide { allies, enemies }

class BattleCreature {
  BattleCreature({
    required this.id,
    required this.name,
    required this.side,
    required this.slot,
    required this.stats,
    required this.moves,
    required this.asset,
    int? currentHp,
  }) : hp = currentHp ?? stats.maxHp,
       prowess = stats.pro.toDouble(),
       magicalProwess = stats.mpr.toDouble(),
       resistance = stats.res.toDouble(),
       magicalResistance = stats.mre.toDouble();
  final String id;
  final String name;
  final BattleSide side;
  final int slot;
  final CreatureStats stats;
  final List<BattleMove> moves;
  final String asset;
  int hp;
  double prowess;
  double magicalProwess;
  double resistance;
  double magicalResistance;
  bool flameWardActive = false;
  bool get alive => hp > 0;
}

class BattleAction {
  const BattleAction(this.user, this.move);
  final BattleCreature user;
  final BattleMove move;
}

class BattleResult {
  const BattleResult(
    this.target,
    this.damage, {
    this.healing = 0,
    this.note = '',
  });
  final BattleCreature target;
  final int damage;
  final int healing;
  final String note;
}

List<BattleCreature> createShowcaseBattle() => [
  for (var i = 0; i < 2; i++)
    BattleCreature(
      id: 'ally-$i',
      name: showcaseParty[i].name,
      side: BattleSide.allies,
      slot: i,
      stats: showcaseParty[i].stats,
      currentHp: showcaseParty[i].currentHp,
      asset: showcaseParty[i].species.backAsset,
      moves: i == 0
          ? [psybite, psyclash, brancheal]
          : [piercecrash, headrip, wavelectrify],
    ),
  for (var i = 0; i < 2; i++)
    BattleCreature(
      id: 'enemy-$i',
      name: 'Enemy ${i + 1}',
      side: BattleSide.enemies,
      slot: i,
      stats: showcaseParty[i].species.baseStats,
      asset: showcaseParty[i].species.frontAsset,
      moves: i == 0
          ? [flameward, psyclash, psybite]
          : [poweride, headrip, wavelectrify],
    ),
];

List<BattleAction> orderActions(Iterable<BattleAction> actions, Random random) {
  final brackets = <int, List<BattleAction>>{};
  for (final action in actions) {
    brackets.putIfAbsent(action.move.priority, () => []).add(action);
  }
  final priorities = brackets.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final priority in priorities)
      ...orderBySpeed(
        brackets[priority]!,
        (action) => action.user.stats.spe,
        random,
      ),
  ];
}

List<BattleCreature> targetsFor(
  BattleAction action,
  List<BattleCreature> roster,
) {
  final user = action.user;
  final allies = roster.where((c) => c.alive && c.side == user.side).toList()
    ..sort((a, b) => a.slot.compareTo(b.slot));
  final enemies = roster.where((c) => c.alive && c.side != user.side).toList()
    ..sort((a, b) => a.slot.compareTo(b.slot));
  switch (action.move.target) {
    case MoveTarget.self:
      return user.alive ? [user] : [];
    case MoveTarget.bothAllies:
      return allies;
    case MoveTarget.bothEnemies:
      return enemies;
    case MoveTarget.allOthers:
      return [...allies.where((c) => c != user), ...enemies];
    case MoveTarget.closestEnemy:
    case MoveTarget.furthestEnemy:
      if (enemies.isEmpty) return [];
      final slot = action.move.target == MoveTarget.closestEnemy
          ? user.slot
          : 1 - user.slot;
      return [
        enemies.firstWhere((c) => c.slot == slot, orElse: () => enemies.first),
      ];
    case MoveTarget.healthiestEnemy:
      if (enemies.isEmpty) return [];
      // Current HP; ties go to the leftmost living enemy.
      return [enemies.reduce((a, b) => b.hp > a.hp ? b : a)];
  }
}

int calculateDamage(BattleMove move, CreatureStats user, CreatureStats target) {
  if (!move.dealsDamage) return 0;
  final attack = move.split == MoveSplit.physical ? user.pro : user.mpr;
  final defense = move.split == MoveSplit.physical ? target.res : target.mre;
  return max(1, attack + move.potency! - defense);
}

/// Resolve targets at execution time, so defeated targets are never hit again.
List<BattleResult> resolveAction(
  BattleAction action,
  List<BattleCreature> roster,
) {
  final user = action.user;
  if (!user.alive) return [];
  final move = action.move;
  final results = <BattleResult>[];
  // Snapshot before transfers: every target loses the same requested amount.
  final transferAmount = (user.prowess * .1).roundToDouble();
  var totalTransferred = 0.0;
  for (final target in targetsFor(action, roster)) {
    if (!user.alive) break;
    final harmful = move.dealsDamage || move.effect == MoveEffect.powerTransfer;
    if (harmful && target.flameWardActive) {
      results.add(BattleResult(target, 0, note: 'Blocked'));
      final reflected = min(
        user.hp,
        (target.magicalProwess * .2 + target.magicalResistance * .3).round(),
      );
      user.hp -= reflected;
      // Reflected damage is not a new attack and cannot trigger another ward.
      results.add(BattleResult(user, reflected, note: 'Reflected'));
      continue;
    }
    var damage = 0;
    var healing = 0;
    var note = '';
    if (move.dealsDamage) {
      final attack = move.split == MoveSplit.physical
          ? user.prowess
          : user.magicalProwess;
      final defense = move.split == MoveSplit.physical
          ? target.resistance
          : target.magicalResistance;
      damage = min(
        target.hp,
        max(1, (attack + move.potency! - defense).round()),
      );
      target.hp -= damage;
    }
    switch (move.effect) {
      case MoveEffect.none:
        break;
      case MoveEffect.resistanceDrop:
        if (target.alive) {
          final amount = min(
            target.resistance,
            (user.prowess * .1).roundToDouble(),
          );
          target.resistance -= amount;
          note = 'RES -${amount.toInt()}';
        }
      case MoveEffect.magicalResistanceDrop:
        if (target.alive) {
          final amount = min(
            target.magicalResistance,
            (user.magicalProwess * .1).roundToDouble(),
          );
          target.magicalResistance -= amount;
          note = 'MRE -${amount.toInt()}';
        }
      case MoveEffect.flameWard:
        target.flameWardActive = true;
        note = 'Protected this round';
      case MoveEffect.heal:
        healing = min(
          target.stats.maxHp - target.hp,
          (user.magicalProwess + move.potency!).round(),
        );
        target.hp += healing;
      case MoveEffect.powerTransfer:
        final amount = min(target.prowess, transferAmount);
        target.prowess -= amount;
        totalTransferred += amount;
        note = 'PRO -${amount.toInt()}';
    }
    results.add(BattleResult(target, damage, healing: healing, note: note));
  }
  if (move.effect == MoveEffect.powerTransfer && user.alive) {
    user.prowess += totalTransferred;
    results.add(
      BattleResult(user, 0, note: 'PRO +${totalTransferred.toInt()}'),
    );
  }
  return results;
}

void endRound(List<BattleCreature> roster) {
  for (final creature in roster) {
    creature.flameWardActive = false;
  }
}
