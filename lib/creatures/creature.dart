enum CreatureSource {
  falobris('Falobris'),
  raida('Raida'),
  koredull('Koredull'),
  sunderkeep('Sunderkeep'),
  undiria('Undiria');

  const CreatureSource(this.label);
  final String label;
}

/// Base attributes. CRI and EVA are percentage points (0-100).
class CreatureStats {
  const CreatureStats({
    required this.con,
    required this.pro,
    required this.mpr,
    required this.res,
    required this.mre,
    required this.cri,
    required this.eva,
    required this.spe,
  }) : assert(con > 0),
       assert(pro >= 0),
       assert(mpr >= 0),
       assert(res >= 0),
       assert(mre >= 0),
       assert(cri >= 0 && cri <= 100),
       assert(eva >= 0 && eva <= 100),
       assert(spe >= 0);

  /// Constitution: determines maximum HP.
  final int con;

  /// Prowess: physical attack strength.
  final int pro;

  /// Magical prowess: magical attack strength.
  final int mpr;

  /// Resistance: physical defense and resistance to physical effects.
  final int res;

  /// Magical resistance: magical defense and resistance to magical effects.
  final int mre;

  /// Critical chance: base chance of a strong attack.
  final int cri;

  /// Critical evasion: reduction of an enemy's strong-attack chance.
  final int eva;

  /// Speed: initiative order.
  final int spe;

  /// Provisional HP rule for the prototype; combat balancing comes later.
  int get maxHp => con * 10;
}

/// Shared species identity and presentation, independent of an individual.
class CreatureSpecies {
  const CreatureSpecies({
    required this.id,
    required this.name,
    required this.frontAsset,
    required this.backAsset,
    required this.baseStats,
  });
  final String id;
  final String name;
  final String frontAsset;
  final String backAsset;
  final CreatureStats baseStats;
}

/// One specific companion. Species can be shared by many individuals.
class Creature {
  Creature({
    required this.id,
    required this.name,
    required this.species,
    required this.stats,
    required this.currentHp,
    required this.source,
  }) : assert(currentHp >= 0),
       assert(currentHp <= stats.con * 10);
  final String id;
  final String name;
  final CreatureSpecies species;
  final CreatureStats stats;
  final int currentHp;
  final CreatureSource source;
  int get maxHp => stats.maxHp;
}
