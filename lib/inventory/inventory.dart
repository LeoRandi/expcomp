import 'item.dart';

/// Owns item quantities; callers cannot bypass quantity validation.
class Inventory {
  Inventory({Map<Item, int> items = const {}}) {
    for (final entry in items.entries) {
      add(entry.key, entry.value);
    }
  }

  final Map<Item, int> _items = {};

  Map<Item, int> get items => Map.unmodifiable(_items);

  int quantityOf(Item item) => _items[item] ?? 0;

  void add(Item item, [int quantity = 1]) {
    _validateQuantity(quantity);
    _items[item] = quantityOf(item) + quantity;
  }

  /// Returns false without changing inventory when there are too few items.
  bool remove(Item item, [int quantity = 1]) {
    _validateQuantity(quantity);
    final remaining = quantityOf(item) - quantity;
    if (remaining < 0) return false;
    if (remaining == 0) {
      _items.remove(item);
    } else {
      _items[item] = remaining;
    }
    return true;
  }

  static void _validateQuantity(int quantity) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'Must be positive');
    }
  }
}
