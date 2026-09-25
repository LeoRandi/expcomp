import '../inventory/inventory.dart';
import '../inventory/item.dart';

class Player {
  Player({this.name = 'Youngest of Cresca', Inventory? inventory})
    : inventory = inventory ?? Inventory();

  factory Player.demo() =>
      Player(inventory: Inventory(items: {meat: 1, moonlessNecklace: 2}));

  final String name;
  final Inventory inventory;
}
