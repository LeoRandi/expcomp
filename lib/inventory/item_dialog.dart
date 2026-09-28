import 'package:flutter/material.dart';

import '../creatures/creature.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'inventory.dart';
import 'item.dart';
import 'item_icon.dart';

class ItemDialog extends StatefulWidget {
  const ItemDialog({
    super.key,
    required this.item,
    required this.inventory,
    required this.party,
  });

  final Item item;
  final Inventory inventory;
  final List<Creature> party;

  @override
  State<ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<ItemDialog> {
  bool _selecting = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    return Dialog(
      key: const ValueKey('item-dialog'),
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: 360,
        height: _selecting ? 440 : 280,
        child: PixelPanel.expanded(
          role: PixelSurfaceRole.dialog,
          padding: const EdgeInsets.all(20),
          child: DefaultTextStyle(
            style: TextStyle(color: palette.ink, fontSize: PixelUiMetrics.body),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ItemIconView(item: widget.item),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.item.name)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (widget.item.effectText.isNotEmpty)
                        Text(widget.item.effectText),
                      if (_selecting) ...[
                        const SizedBox(height: 12),
                        const Text('Choose a creature'),
                        if (widget.party.isEmpty)
                          const Text('There are no creatures in your party.'),
                        for (final creature in widget.party)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PixelButton(
                                  key: ValueKey('equip-to-${creature.id}'),
                                  label: creature.name,
                                  leading: SizedBox.square(
                                    dimension: 32,
                                    child: PixelAssetSprite(
                                      assetPath: creature.species.frontAsset,
                                    ),
                                  ),
                                  onPressed:
                                      creature.equippedItem == widget.item
                                      ? null
                                      : () {
                                          if (creature.equipFrom(
                                            widget.inventory,
                                            widget.item,
                                          )) {
                                            Navigator.of(context).pop(true);
                                          } else {
                                            setState(
                                              () => _error =
                                                  'This item is no longer available.',
                                            );
                                          }
                                        },
                                ),
                                if (creature.equippedItem != null)
                                  Text(
                                    creature.equippedItem == widget.item
                                        ? 'Already equipped'
                                        : 'Replaces ${creature.equippedItem!.name} (returned to bag)',
                                  ),
                              ],
                            ),
                          ),
                      ],
                      if (_error != null) Text(_error!),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: PixelButton(
                        key: const ValueKey('close-item-dialog'),
                        label: 'CLOSE',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    if (!_selecting &&
                        widget.item.category == ItemCategory.equipment) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: PixelButton(
                          key: const ValueKey('equip-item'),
                          label: 'EQUIP',
                          onPressed: () => setState(() => _selecting = true),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
