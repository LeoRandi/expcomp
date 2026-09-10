import '../battle/battle_move.dart';
import 'innate_ability.dart';

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
    this.moves = const [],
    this.innate,
  });
  final String id;
  final String name;
  final String frontAsset;
  final String backAsset;
  final CreatureStats baseStats;
  final List<BattleMove> moves;
  final InnateAbility? innate;
}

/// One specific companion. Species can be shared by many individuals.
class Creature {
  Creature({
    required this.id,
    required this.name,
    required this.species,
    required CreatureStats stats,
    required this.currentHp,
    required this.source,
    this.level = 1,
  }) : baseStats = stats,
       assert(level > 0),
       assert(currentHp >= 0),
       assert(currentHp <= stats.con * 10);
  final String id;
  final String name;
  final CreatureSpecies species;
  final CreatureStats baseStats;
  final int level;
  Map<String, int> _extra = {};
  late List<BattleMove?> _equippedMoves = List.generate(
    5,
    (i) => i < species.moves.length ? species.moves[i] : null,
  );
  Map<String, int> get extraPoints => Map.unmodifiable(_extra);
  List<BattleMove?> get equippedMoves => List.unmodifiable(_equippedMoves);
  int get pointBudget => level * 10;
  CreatureStats get stats => baseStats.withExtra(_extra);

  void saveBuild(Map<String, int> points, List<BattleMove?> moves) {
    final total = points.values.fold(0, (a, b) => a + b);
    if (points.keys.any((key) => !statNames.contains(key)) ||
        points.values.any((value) => value < 0) ||
        total > pointBudget ||
        moves.length != 5 ||
        moves.whereType<BattleMove>().map((m) => m.id).toSet().length !=
            moves.whereType<BattleMove>().length ||
        moves.whereType<BattleMove>().any((m) => !moveCatalog.contains(m)) ||
        baseStats.cri + (points['CRI'] ?? 0) > 100 ||
        baseStats.eva + (points['EVA'] ?? 0) > 100) {
      throw ArgumentError('Invalid creature build');
    }
    final missingHp = maxHp - currentHp;
    _extra = Map.of(points);
    _equippedMoves = List.of(moves);
    if (currentHp > 0) currentHp = (maxHp - missingHp).clamp(1, maxHp);
  }

  int currentHp;
  final CreatureSource source;
  int get maxHp => stats.maxHp;
}

const statNames = ['CON', 'PRO', 'MPR', 'CRI', 'SPE', 'RES', 'MRE', 'EVA'];

extension StatAllocation on CreatureStats {
  Map<String, int> get values => {
    'CON': con,
    'PRO': pro,
    'MPR': mpr,
    'RES': res,
    'MRE': mre,
    'CRI': cri,
    'EVA': eva,
    'SPE': spe,
  };
  CreatureStats withExtra(Map<String, int> extra) => CreatureStats(
    con: con + (extra['CON'] ?? 0),
    pro: pro + (extra['PRO'] ?? 0),
    mpr: mpr + (extra['MPR'] ?? 0),
    res: res + (extra['RES'] ?? 0),
    mre: mre + (extra['MRE'] ?? 0),
    cri: cri + (extra['CRI'] ?? 0),
    eva: eva + (extra['EVA'] ?? 0),
    spe: spe + (extra['SPE'] ?? 0),
  );
}
