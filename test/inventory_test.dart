import 'package:expcomp/inventory/inventory.dart';
import 'package:expcomp/inventory/item.dart';
import 'package:expcomp/player/player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Inventory stacks by item identity and never stores invalid quantities',
    () {
      final inventory = Inventory(items: {meat: 1});
      const sameMeat = Item(
        id: 'meat',
        name: 'Meat',
        icon: ItemIcon.meat,
        category: ItemCategory.items,
      );
      inventory.add(sameMeat, 2);
      expect(inventory.items, {meat: 3});
      expect(inventory.remove(meat, 4), isFalse);
      expect(inventory.quantityOf(meat), 3);
      expect(inventory.remove(meat, 3), isTrue);
      expect(inventory.items, isEmpty);
      expect(inventory.remove(meat), isFalse);
      expect(() => inventory.add(meat, 0), throwsArgumentError);
      expect(() => inventory.remove(meat, -1), throwsArgumentError);
      expect(() => inventory.items[meat] = 5, throwsUnsupportedError);
    },
  );

  test('New players start with independent empty inventories', () {
    final first = Player.demo();
    final second = Player.demo();
    expect(first.inventory.items, isEmpty);
    first.inventory.add(meat);
    expect(second.inventory.items, isEmpty);
    expect(Player().inventory.items, isEmpty);
  });
}
