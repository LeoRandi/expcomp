import '../inventory/inventory.dart';
import '../inventory/item.dart';

class Player {
  Player({this.name = 'Youngest of Cresca', Inventory? inventory})
    : inventory = inventory ?? Inventory();

  factory Player.demo() => Player();

  final String name;
  final Inventory inventory;
  final Set<String> _openedChests = {};

  bool hasOpenedChest(String id) => _openedChests.contains(id);

  /// Claim before showing UI, so duplicate input cannot grant a reward twice.
  bool openChest(String id, {Item? item, int quantity = 1}) {
    if (_openedChests.contains(id)) return false;
    if (item != null) inventory.add(item, quantity);
    _openedChests.add(id);
    return true;
  }
}
