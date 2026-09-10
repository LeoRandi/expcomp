import 'dart:math';
import '../creatures/creature.dart';
import '../creatures/showcase_party.dart';
import 'battle_move.dart';
import 'turn_order.dart';
import '../creatures/innate_ability.dart';

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
    this.level = 1,
    this.innate,
  }) : hp = currentHp ?? stats.maxHp,
       prowess = stats.pro.toDouble(),
       magicalProwess = stats.mpr.toDouble(),
       resistance = stats.res.toDouble(),
       magicalResistance = stats.mre.toDouble();
  final int level;
  final InnateAbility? innate;
  bool entered = false;
  String? lastUsedMove;
  List<BattleMove> offeredMoves = [];
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
  for (var i = 0; i < showcaseParty.length; i++)
    BattleCreature(
      id: 'ally-$i',
      name: showcaseParty[i].name,
      side: BattleSide.allies,
      slot: i,
      stats: showcaseParty[i].stats,
      currentHp: showcaseParty[i].currentHp,
      asset: showcaseParty[i].species.backAsset,
      moves: showcaseParty[i].equippedMoves.whereType<BattleMove>().toList(),
      level: showcaseParty[i].level,
      innate: showcaseParty[i].species.innate,
    ),
  for (var i = 0; i < 2; i++)
    BattleCreature(
      id: 'enemy-$i',
      name: 'Enemy ${i + 1}',
      side: BattleSide.enemies,
      slot: i,
      stats: [thornWisp, emberBeetle][i].baseStats,
      asset: [thornWisp, emberBeetle][i].frontAsset,
      moves: [thornWisp, emberBeetle][i].moves,
      innate: [thornWisp, emberBeetle][i].innate,
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
  user.lastUsedMove = move.id;
  final results = <BattleResult>[];
  // Snapshot before transfers: every target loses the same requested amount.
  final transferAmount = (user.prowess * .1).roundToDouble();
  var totalTransferred = 0.0;
  for (final target in targetsFor(action, roster)) {
    if (!user.alive) break;
    final harmful = move.dealsDamage || move.effect == MoveEffect.powerTransfer;
    final areaAttack =
        move.target == MoveTarget.bothEnemies ||
        move.target == MoveTarget.allOthers;
    final guarded =
        harmful &&
        areaAttack &&
        target.side != user.side &&
        roster.any(
          (c) =>
              c.alive &&
              c != target &&
              c.side == target.side &&
              c.innate?.effect == InnateEffect.allyAreaGuard,
        );
    if (guarded) {
      results.add(
        BattleResult(target, 0, note: 'Protected by Sheltering Boughs'),
      );
      continue;
    }
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
  if (user.alive && user.innate?.effect == InnateEffect.regeneration) {
    final healing = min(
      user.stats.maxHp - user.hp,
      (user.stats.maxHp * .05).round(),
    );
    user.hp += healing;
    if (healing > 0) {
      results.add(BattleResult(user, 0, healing: healing, note: 'Self Repair'));
    }
  }
  return results;
}

void endRound(List<BattleCreature> roster) {
  for (final creature in roster) {
    creature.flameWardActive = false;
  }
}

/// Entry hooks run once per combatant, in roster order; reductions round.
void enterCombat(List<BattleCreature> roster) {
  for (final creature in roster.where((c) => c.alive && !c.entered)) {
    creature.entered = true;
    if (creature.innate?.effect == InnateEffect.entranceProwessDrop) {
      for (final enemy in roster.where(
        (c) => c.alive && c.side != creature.side,
      )) {
        enemy.prowess -= (enemy.prowess * .25).round();
      }
    }
  }
}

const waitMove = BattleMove(
  id: 'wait',
  name: 'WAIT',
  split: MoveSplit.blessing,
  target: MoveTarget.self,
  effectDescription: 'Pass this action.',
);

void dealRoundMoves(List<BattleCreature> roster, Random random) {
  for (final creature in roster) {
    final choices = {
      for (final move in creature.moves)
        if (move.id != creature.lastUsedMove) move.id: move,
    }.values.toList()..shuffle(random);
    creature.offeredMoves = choices.take(3).toList();
    if (creature.offeredMoves.isEmpty) creature.offeredMoves = [waitMove];
    // Only an actually executed action is excluded from the following round.
    creature.lastUsedMove = null;
  }
}
