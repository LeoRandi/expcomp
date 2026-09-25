/// Icon identities stay independent of the widgets used to display them.
enum ItemIcon { meat, necklace }

enum ItemCategory {
  items('Items'),
  equipment('Equip'),
  key('Key');

  const ItemCategory(this.label);
  final String label;
}

class Item {
  const Item({
    required this.id,
    required this.name,
    required this.icon,
    required this.category,
    this.effectText = '',
  });

  final String id;
  final String name;
  final ItemIcon icon;
  final ItemCategory category;
  final String effectText;

  @override
  bool operator ==(Object other) => other is Item && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

const meat = Item(
  id: 'meat',
  name: 'Meat',
  icon: ItemIcon.meat,
  category: ItemCategory.items,
);
const moonlessNecklace = Item(
  id: 'moonless_necklace',
  name: 'Moonless necklace',
  icon: ItemIcon.necklace,
  category: ItemCategory.equipment,
);
