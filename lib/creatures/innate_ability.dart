enum InnateEffect {
  allyAreaGuard,
  entranceProwessDrop,
  regeneration,
  roundFortune,
}

class InnateAbility {
  const InnateAbility(this.name, this.description, this.effect);
  final String name;
  final String description;
  final InnateEffect effect;
}

const shelteringBoughs = InnateAbility(
  'Sheltering Boughs',
  'Other allies are immune to hostile area attacks while this creature is alive.',
  InnateEffect.allyAreaGuard,
);
const imposingShell = InnateAbility(
  'Imposing Shell',
  'On entering combat, reduce each enemy’s current Prowess by 25%.',
  InnateEffect.entranceProwessDrop,
);
const selfRepair = InnateAbility(
  'Self Repair',
  'At the end of this creature’s action, restore 5% of its maximum HP.',
  InnateEffect.regeneration,
);

const twilightFortune = InnateAbility(
  'Twilight Fortune',
  'At the start of each round, randomly choose CRI or EVA and grant +5 points to this creature and its living allies. Stacks up to 100.',
  InnateEffect.roundFortune,
);
