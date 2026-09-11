import 'creature.dart';
import 'innate_ability.dart';
import '../battle/battle_move.dart';

const _root = 'assets/monsters/50__Monsters_Pack_2D_Monster__';

// Working names and starter values for the two showcase companions.
const thornWisp = CreatureSpecies(
  id: 'thorn_wisp',
  innate: shelteringBoughs,
  moves: [psybite, psyclash, brancheal, flameward, wavelectrify],
  name: 'Thorn Wisp',
  frontAsset: '${_root}11_Front_Normal_Color_Palette_f0_c0_00342.png',
  backAsset: '${_root}11_Back_Normal_Color_Palette_f0_c0_00341.png',
  baseStats: CreatureStats(
    con: 8,
    pro: 5,
    mpr: 12,
    res: 6,
    mre: 10,
    cri: 5,
    eva: 3,
    spe: 11,
  ),
);
const emberBeetle = CreatureSpecies(
  id: 'ember_beetle',
  innate: imposingShell,
  moves: [piercecrash, headrip, wavelectrify, poweride, flameward],
  name: 'Ember Beetle',
  frontAsset: '${_root}12_Front_Normal_Color_Palette_f0_c0_00344.png',
  backAsset: '${_root}12_Back_Normal_Color_Palette_f0_c0_00343.png',
  baseStats: CreatureStats(
    con: 12,
    pro: 11,
    mpr: 4,
    res: 12,
    mre: 6,
    cri: 5,
    eva: 2,
    spe: 7,
  ),
);
const tinyBot = CreatureSpecies(
  id: 'tiny_bot',
  innate: selfRepair,
  moves: [psyclash, wavelectrify, flameward, brancheal, poweride],
  name: 'Tiny Bot',
  frontAsset: '${_root}2_Front_Alternative_Color_Palette_f0_c0_00248.png',
  backAsset: '${_root}2_Back_Alternative_Color_Palette_f0_c0_00247.png',
  baseStats: CreatureStats(
    con: 16,
    pro: 5,
    mpr: 14,
    res: 14,
    mre: 15,
    cri: 3,
    eva: 3,
    spe: 5,
  ),
);
const thornwing = CreatureSpecies(
  id: 'thornwing',
  name: 'Thornwing',
  innate: shelteringBoughs,
  frontAsset: '${_root}14_Front_Normal_Color_Palette_f0_c0_00348.png',
  backAsset: '${_root}14_Back_Normal_Color_Palette_f0_c0_00347.png',
  moves: [psybite, piercecrash, headrip, psyclash, brancheal],
  baseStats: CreatureStats(
    con: 10,
    pro: 13,
    mpr: 8,
    res: 8,
    mre: 9,
    cri: 10,
    eva: 8,
    spe: 16,
  ),
);
final showcaseParty = List<Creature>.unmodifiable([
  Creature(
    id: 'tiny_bot_01',
    source: CreatureSource.koredull,
    name: 'Pip',
    species: tinyBot,
    stats: tinyBot.baseStats,
    currentHp: tinyBot.baseStats.maxHp,
  ),
  Creature(
    id: 'thornwing_01',
    name: 'Vesper',
    source: CreatureSource.undiria,
    species: thornwing,
    stats: thornwing.baseStats,
    currentHp: thornwing.baseStats.maxHp,
  ),
]);
