import 'package:flutter/material.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'item.dart';

class ItemIconView extends StatelessWidget {
  const ItemIconView({super.key, required this.item});
  final Item item;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 48,
    child: PixelPanel.expanded(
      role: PixelSurfaceRole.inset,
      tileExtent: 8,
      child: Icon(
        switch (item.icon) {
          ItemIcon.meat => Icons.kebab_dining,
          ItemIcon.necklace => Icons.diamond_outlined,
        },
        color: PixelUiThemeData.of(context).palette.accent,
        size: 28,
      ),
    ),
  );
}
