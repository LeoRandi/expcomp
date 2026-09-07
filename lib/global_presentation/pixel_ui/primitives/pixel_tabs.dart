import 'package:flutter/material.dart';

import 'pixel_button.dart';
import 'pixel_control_tone.dart';

@immutable
class PixelTabData {
  const PixelTabData({required this.label, this.leading, this.semanticLabel});

  final String label;
  final Widget? leading;
  final String? semanticLabel;
}

class PixelTabs extends StatelessWidget {
  const PixelTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
    this.tabColumns = 8,
    this.tabRows = 3,
    this.tone = PixelControlTone.accent,
    this.spacing = 4,
  }) : assert(tabs.length > 0),
       assert(selectedIndex >= 0 && selectedIndex < tabs.length),
       assert(tabColumns >= 2),
       assert(tabRows >= 2),
       assert(spacing >= 0);

  final List<PixelTabData> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final int tabColumns;
  final int tabRows;
  final PixelControlTone tone;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Tabs',
      explicitChildNodes: true,
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (var index = 0; index < tabs.length; index += 1)
            PixelButton(
              key: ValueKey('pixel-tab-$index'),
              label: tabs[index].label,
              semanticLabel: tabs[index].semanticLabel,
              leading: tabs[index].leading,
              columns: tabColumns,
              rows: tabRows,
              tone: tone,
              selected: index == selectedIndex,
              onPressed: () => onSelected(index),
            ),
        ],
      ),
    );
  }
}
