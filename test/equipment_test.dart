import 'package:expcomp/battle/battle_engine.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/inventory/inventory.dart';
import 'package:expcomp/inventory/item_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

Creature companion() => Creature(
  id: 'test',
  name: 'Companion',
  species: tinyBot,
  stats: tinyBot.baseStats,
  currentHp: tinyBot.baseStats.maxHp - 12,
  source: CreatureSource.koredull,
);

void main() {
  test('Catalog indexes all starter definitions by stable IDs', () {
    expect(itemCatalog.values, containsAll([meat, moonlessNecklace]));
    for (final entry in itemCatalog.entries) {
      expect(entry.key, entry.value.id);
    }
    expect(() => itemCatalog['new'] = meat, throwsUnsupportedError);
  });

  test(
    'Equipment transfers one copy and adds flat bonuses above allocated points',
    () {
      final creature = companion();
      final other = companion();
      final bag = Inventory(items: {moonlessNecklace: 2, meat: 1});
      creature.saveBuild({'CON': 2, 'SPE': 3}, creature.equippedMoves);
      final before = creature.stats.values;
      final hp = creature.currentHp;
      expect(creature.equipFrom(bag, meat), isFalse);
      expect(creature.equipFrom(bag, moonlessNecklace), isTrue);
      expect(bag.quantityOf(moonlessNecklace), 1);
      expect(creature.equippedItem, moonlessNecklace);
      expect(creature.stats.con, before['CON']! + 5);
      expect(creature.stats.spe, before['SPE']! + 5);
      for (final stat in statNames.where((s) => s != 'CON' && s != 'SPE')) {
        expect(creature.stats.values[stat], before[stat]);
      }
      expect(creature.extraPoints, {'CON': 2, 'SPE': 3});
      expect(creature.currentHp, hp + 50);
      expect(creature.maxHp - creature.currentHp, 12);
      expect(other.equippedItem, isNull);
      expect(creature.equipFrom(bag, moonlessNecklace), isFalse);
      expect(bag.quantityOf(moonlessNecklace), 1);
      creature.saveBuild({'SPE': 1}, creature.equippedMoves);
      expect(creature.stats.spe, tinyBot.baseStats.spe + 6);
      expect(creature.unequipTo(bag), isTrue);
      expect(creature.stats.spe, tinyBot.baseStats.spe + 1);
      expect(bag.quantityOf(moonlessNecklace), 2);
    },
  );

  test(
    'Swapping returns old gear, rejects missing copies, and preserves KO',
    () {
      const charm = Item(
        id: 'charm',
        name: 'Charm',
        icon: ItemIcon.necklace,
        category: ItemCategory.equipment,
        speedBonus: 2,
      );
      final creature = companion()..currentHp = 0;
      final bag = Inventory(items: {moonlessNecklace: 1});
      expect(creature.equipFrom(bag, moonlessNecklace), isTrue);
      expect(creature.currentHp, 0);
      expect(creature.equipFrom(bag, charm), isFalse);
      expect(creature.equippedItem, moonlessNecklace);
      bag.add(charm);
      expect(creature.equipFrom(bag, charm), isTrue);
      expect(bag.quantityOf(moonlessNecklace), 1);
      expect(bag.quantityOf(charm), 0);
      expect(creature.stats.con, tinyBot.baseStats.con);
      expect(creature.stats.spe, tinyBot.baseStats.spe + 2);
      expect(creature.currentHp, 0);
    },
  );

  test('Battle receives equipment bonuses and equipment identity', () {
    final creature = showcaseParty.first;
    final bag = Inventory(items: {moonlessNecklace: 1});
    final before = creature.stats;
    creature.equipFrom(bag, moonlessNecklace);
    addTearDown(() => creature.unequipTo(bag));
    final combatant = createShowcaseBattle().first;
    expect(combatant.stats.con, before.con + 5);
    expect(combatant.stats.spe, before.spe + 5);
    expect(combatant.stats.maxHp, before.maxHp + 50);
    expect(combatant.equippedItem, moonlessNecklace);
  });
}
