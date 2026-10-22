import '../inventory/item.dart';

class ChestContents {
  const ChestContents({required this.id, this.item, this.quantity = 0});
  final String id;
  final Item? item;
  final int quantity;
}
