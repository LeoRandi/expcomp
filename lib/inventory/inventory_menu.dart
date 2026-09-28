import 'package:flutter/material.dart';

import '../creatures/creature.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'inventory.dart';
import 'item.dart';
import 'item_dialog.dart';
import 'item_icon.dart';

class InventoryMenu extends StatefulWidget {
  const InventoryMenu({
    super.key,
    required this.inventory,
    required this.party,
    required this.onClose,
  });

  final Inventory inventory;
  final List<Creature> party;
  final VoidCallback onClose;

  @override
  State<InventoryMenu> createState() => _InventoryMenuState();
}

class _InventoryMenuState extends State<InventoryMenu> {
  ItemCategory _category = ItemCategory.items;

  Future<void> _showItem(Item item) async {
    await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (_) => ItemDialog(
        item: item,
        inventory: widget.inventory,
        party: widget.party,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.inventory.items.entries
        .where((entry) => entry.key.category == _category)
        .toList();
    final palette = PixelUiThemeData.of(context).palette;
    return Material(
      key: const ValueKey('inventory-menu'),
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: PixelPanel.expanded(
                tileExtent: PixelUiMetrics.largeBorder,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text(
                                'No items in this category.',
                                style: TextStyle(color: palette.ink),
                              ),
                            )
                          : ListView.separated(
                              key: ValueKey('inventory-list-${_category.name}'),
                              padding: EdgeInsets.zero,
                              itemCount: entries.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 2,
                                thickness: 2,
                                color: palette.accent,
                              ),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                return InkWell(
                                  key: ValueKey(
                                    'inventory-item-${entry.key.id}',
                                  ),
                                  onTap: () => _showItem(entry.key),
                                  child: SizedBox(
                                    height: 64,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Row(
                                        children: [
                                          ItemIconView(item: entry.key),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              entry.key.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: palette.ink,
                                                fontSize:
                                                    PixelUiMetrics.caption,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'x${entry.value}',
                                            style: TextStyle(
                                              color: palette.ink,
                                              fontSize: PixelUiMetrics.caption,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          for (final category in ItemCategory.values) ...[
                            if (category.index > 0) const SizedBox(width: 4),
                            Expanded(
                              child: PixelButton(
                                key: ValueKey('inventory-tab-${category.name}'),
                                label: category.label,
                                tileExtent: 8,
                                expandToFill: true,
                                selected: category == _category,
                                onPressed: () =>
                                    setState(() => _category = category),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 48,
              width: double.infinity,
              child: PixelButton(
                key: const ValueKey('close-inventory'),
                label: 'BACK',
                expandToFill: true,
                onPressed: widget.onClose,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
