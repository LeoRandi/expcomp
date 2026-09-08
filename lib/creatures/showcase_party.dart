import 'creature.dart';

const _root = 'assets/monsters/50__Monsters_Pack_2D_Monster__';

// Working names and starter values for the two showcase companions.
const thornWisp = CreatureSpecies(
  id: 'thorn_wisp',
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
final showcaseParty = List<Creature>.unmodifiable([
  Creature(
    id: 'companion_01',
    source: CreatureSource.raida,
    name: 'Briar',
    species: thornWisp,
    stats: thornWisp.baseStats,
    currentHp: 80,
  ),
  Creature(
    id: 'companion_02',
    source: CreatureSource.undiria,
    name: 'Cinder',
    species: emberBeetle,
    stats: emberBeetle.baseStats,
    currentHp: 120,
  ),
]);
