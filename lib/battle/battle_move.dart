enum MoveSplit { physical, magical, curse, blessing }

enum MoveTarget {
  closestEnemy,
  furthestEnemy,
  healthiestEnemy,
  self,
  bothAllies,
  bothEnemies,
  allOthers,
}

enum MoveEffect {
  none,
  resistanceDrop,
  magicalResistanceDrop,
  flameWard,
  heal,
  powerTransfer,
}

class BattleMove {
  const BattleMove({
    required this.id,
    required this.name,
    required this.split,
    required this.target,
    this.potency,
    this.priority = 0,
    this.effect = MoveEffect.none,
    this.effectDescription = 'None',
  });
  final String id;
  final String name;
  final MoveSplit split;
  final MoveTarget target;
  final int? potency;
  final int priority;
  final MoveEffect effect;
  final String effectDescription;
  bool get dealsDamage =>
      (split == MoveSplit.physical || split == MoveSplit.magical) &&
      potency != null &&
      effect != MoveEffect.heal;
  String get targetLabel => switch (target) {
    MoveTarget.closestEnemy => 'Closest enemy',
    MoveTarget.furthestEnemy => 'Furthest enemy',
    MoveTarget.healthiestEnemy => 'Healthiest enemy',
    MoveTarget.self => 'Self',
    MoveTarget.bothAllies => 'Both allies',
    MoveTarget.bothEnemies => 'Both enemies',
    MoveTarget.allOthers => 'All other creatures',
  };
}

const psybite = BattleMove(
  id: 'psybite',
  name: 'PSYBITE',
  split: MoveSplit.physical,
  potency: 20,
  target: MoveTarget.closestEnemy,
);
const piercecrash = BattleMove(
  id: 'piercecrash',
  name: 'PIERCECRASH',
  split: MoveSplit.physical,
  potency: 10,
  target: MoveTarget.closestEnemy,
  effect: MoveEffect.resistanceDrop,
  effectDescription: "Reduces target RES by 10% of the user's PRO.",
);
const psyclash = BattleMove(
  id: 'psyclash',
  name: 'PSYCLASH',
  split: MoveSplit.magical,
  potency: 10,
  target: MoveTarget.furthestEnemy,
  effect: MoveEffect.magicalResistanceDrop,
  effectDescription: "Reduces target MRE by 10% of the user's MPR.",
);
const flameward = BattleMove(
  id: 'flameward',
  name: 'FLAMEWARD',
  split: MoveSplit.blessing,
  target: MoveTarget.self,
  priority: 2,
  effect: MoveEffect.flameWard,
  effectDescription:
      'Blocks attacks this turn; each blocked attack reflects 20% MPR + 30% MRE.',
);
const headrip = BattleMove(
  id: 'headrip',
  name: 'HEADRIP',
  split: MoveSplit.physical,
  potency: 25,
  target: MoveTarget.healthiestEnemy,
  priority: 1,
);
const brancheal = BattleMove(
  id: 'brancheal',
  name: 'BRANCHEAL',
  split: MoveSplit.magical,
  potency: 10,
  target: MoveTarget.bothAllies,
  effect: MoveEffect.heal,
  effectDescription: 'Heals instead of damaging.',
);
const poweride = BattleMove(
  id: 'poweride',
  name: 'POWERIDE',
  split: MoveSplit.curse,
  target: MoveTarget.allOthers,
  priority: -1,
  effect: MoveEffect.powerTransfer,
  effectDescription:
      "Reduces each other's PRO by 10% of user's PRO; adds the total reduction to user's PRO.",
);
const wavelectrify = BattleMove(
  id: 'wavelectrify',
  name: 'WAVELECTRIFY',
  split: MoveSplit.magical,
  potency: 15,
  target: MoveTarget.bothEnemies,
);
const moveCatalog = [
  psybite,
  piercecrash,
  psyclash,
  flameward,
  headrip,
  brancheal,
  poweride,
  wavelectrify,
];
