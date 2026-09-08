import 'package:flutter/material.dart';

import '../pixel_asset_sprite.dart';
import '../pixel_grid.dart';
import '../pixel_panel.dart';
import '../pixel_sprite.dart';
import '../pixel_ui_theme.dart';
import '../primitives/pixel_badge.dart';
import '../primitives/pixel_button.dart';
import '../primitives/pixel_control_tone.dart';
import '../primitives/pixel_dialog_frame.dart';
import '../primitives/pixel_inventory_slot.dart';
import '../primitives/pixel_item_tile.dart';
import '../primitives/pixel_resource_bar.dart';
import '../primitives/pixel_tabs.dart';
import '../primitives/pixel_text_plate.dart';
import '../themes/sunderkeep_ui.dart';
import 'pixel_ui_showcase_skins.dart';

class PixelUiShowcasePage extends StatefulWidget {
  const PixelUiShowcasePage({super.key});

  static const routeName = '/pixel-ui-showcase';

  @override
  State<PixelUiShowcasePage> createState() => _PixelUiShowcasePageState();
}

class _PixelUiShowcasePageState extends State<PixelUiShowcasePage> {
  static const _swordAsset =
      'assets/sundered_keep/icons/5_RPG_Fantasy_Weapons_sword_f0_c0_02069.png';
  static const _bowAsset =
      'assets/sundered_keep/icons/5_RPG_Fantasy_Weapons_bow_f0_c0_02066.png';
  static const _potionAsset =
      'assets/sundered_keep/icons/16x16_RPG_Items_items_f0_c1_01873.png';
  static const _monsterAsset =
      'assets/monsters/'
      '50__Monsters_Pack_2D_Monster__10_Front_Normal_Color_Palette_f0_c0_00340.png';

  int _selectedTab = 0;
  int _selectedSlot = 1;
  int _pressCount = 0;
  int _selectedSkin = 0;
  double _health = 76;
  bool _dialogVisible = true;

  @override
  Widget build(BuildContext context) {
    final pixelTheme = PixelUiThemeData.of(context);

    return Scaffold(
      key: const ValueKey('pixel-ui-showcase'),
      backgroundColor: pixelTheme.palette.canvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final canvasWidth = constraints.maxWidth < 560
                ? 560.0
                : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: canvasWidth,
                height: constraints.maxHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 512,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(pixelTheme.palette),
                          const SizedBox(height: 24),
                          _ShowcaseSection(
                            title: 'Buttons',
                            description:
                                'Hover, focus, pressed, selected and disabled states.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PixelButton(
                                  key: const ValueKey('showcase-action-button'),
                                  label:
                                      'Invoke ${_pressCount == 0 ? '' : _pressCount}',
                                  columns: 9,
                                  tone: PixelControlTone.accent,
                                  onPressed: () =>
                                      setState(() => _pressCount += 1),
                                ),
                                PixelButton(
                                  label: 'Selected',
                                  columns: 9,
                                  selected: true,
                                  tone: PixelControlTone.gold,
                                  onPressed: () {},
                                ),
                                const PixelButton(
                                  label: 'Disabled',
                                  columns: 9,
                                  onPressed: null,
                                ),
                              ],
                            ),
                          ),
                          const _ShowcaseSection(
                            title: 'Text plates',
                            description:
                                'The backdrop is translucent while the text stays fully opaque.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PixelTextPlate(
                                  child: Text('DEFAULT 55% BACKDROP'),
                                ),
                                PixelTextPlate(
                                  backgroundOpacity: 0.72,
                                  borderOpacity: 0.8,
                                  child: Text('STRONG CONTRAST'),
                                ),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Alternate tilesets & widget concepts',
                            description:
                                'Experimental atlases stay isolated here until a skin is promoted into the game.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (
                                  var index = 0;
                                  index < PixelUiShowcaseSkins.skins.length;
                                  index += 1
                                )
                                  _SkinPreviewCard(
                                    key: ValueKey('showcase-skin-$index'),
                                    skin: PixelUiShowcaseSkins.skins[index],
                                    selected: _selectedSkin == index,
                                    onSelected: () {
                                      setState(() => _selectedSkin = index);
                                    },
                                  ),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Badges',
                            description:
                                'Small readouts share the same tiled inset surface.',
                            child: const Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                PixelBadge(
                                  label: '247 G',
                                  tone: PixelControlTone.gold,
                                  columns: 6,
                                ),
                                PixelBadge(
                                  label: '+12',
                                  tone: PixelControlTone.positive,
                                ),
                                PixelBadge(
                                  label: '-8',
                                  tone: PixelControlTone.danger,
                                ),
                                PixelBadge(
                                  label: 'READY',
                                  tone: PixelControlTone.energy,
                                  columns: 6,
                                ),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Resources',
                            description:
                                'Values clamp safely and the fill remains rectangular and crisp.',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                PixelResourceBar(
                                  key: const ValueKey('showcase-health-bar'),
                                  label: 'HP',
                                  value: _health,
                                  maximum: 100,
                                  columns: 24,
                                  tone: PixelControlTone.positive,
                                ),
                                const SizedBox(height: 8),
                                const PixelResourceBar(
                                  label: 'WARD',
                                  value: 34,
                                  maximum: 60,
                                  columns: 24,
                                  tone: PixelControlTone.energy,
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    PixelButton(
                                      label: 'Damage',
                                      columns: 7,
                                      rows: 2,
                                      tone: PixelControlTone.danger,
                                      onPressed: () => setState(
                                        () => _health = (_health - 9).clamp(
                                          0,
                                          100,
                                        ),
                                      ),
                                    ),
                                    PixelButton(
                                      label: 'Heal',
                                      columns: 7,
                                      rows: 2,
                                      tone: PixelControlTone.positive,
                                      onPressed: () => setState(
                                        () => _health = (_health + 9).clamp(
                                          0,
                                          100,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Tabs',
                            description:
                                'A composition of buttons; selection remains owned by the screen.',
                            child: PixelTabs(
                              key: const ValueKey('showcase-tabs'),
                              tabs: const [
                                PixelTabData(label: 'Pack'),
                                PixelTabData(label: 'Gear'),
                                PixelTabData(label: 'Relics'),
                              ],
                              selectedIndex: _selectedTab,
                              tabColumns: 8,
                              onSelected: (index) {
                                setState(() => _selectedTab = index);
                              },
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Inventory slots',
                            description:
                                'Empty, occupied, selected, valid, invalid and locked states.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _slot(0, PixelInventorySlotState.empty),
                                _slot(1, PixelInventorySlotState.occupied),
                                _slot(2, PixelInventorySlotState.validDrop),
                                _slot(3, PixelInventorySlotState.invalidDrop),
                                _slot(4, PixelInventorySlotState.disabled),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Item tiles and sprites',
                            description:
                                'Standalone icons and monsters use nearest-neighbour sampling.',
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                PixelItemTile(
                                  label: 'Keep sword',
                                  art: const PixelAssetSprite(
                                    assetPath: _swordAsset,
                                    width: 48,
                                    height: 48,
                                  ),
                                  quantity: 2,
                                  state: PixelItemTileState.selected,
                                  seed: 3,
                                ),
                                PixelItemTile(
                                  label: 'Hunter bow',
                                  art: const PixelAssetSprite(
                                    assetPath: _bowAsset,
                                    width: 48,
                                    height: 48,
                                  ),
                                  state: PixelItemTileState.dragging,
                                  seed: 8,
                                ),
                                const PixelItemTile(
                                  label: 'Spent potion',
                                  art: PixelAssetSprite(
                                    assetPath: _potionAsset,
                                    width: 48,
                                    height: 48,
                                  ),
                                  state: PixelItemTileState.disabled,
                                  seed: 11,
                                ),
                                const PixelAssetSprite(
                                  assetPath: _monsterAsset,
                                  width: 64,
                                  height: 64,
                                  semanticLabel: 'Curated keep monster',
                                ),
                              ],
                            ),
                          ),
                          _ShowcaseSection(
                            title: 'Dialog frame',
                            description:
                                'Title, content and actions remain normal Flutter widgets.',
                            child: _dialogVisible
                                ? PixelDialogFrame(
                                    key: const ValueKey('showcase-dialog'),
                                    title: 'The sealed armory',
                                    gridSize: const PixelGridSize(
                                      columns: 30,
                                      rows: 16,
                                    ),
                                    onClose: () {
                                      setState(() => _dialogVisible = false);
                                    },
                                    actions: [
                                      PixelButton(
                                        label: 'Leave',
                                        columns: 7,
                                        onPressed: () {
                                          setState(
                                            () => _dialogVisible = false,
                                          );
                                        },
                                      ),
                                      PixelButton(
                                        label: 'Enter',
                                        columns: 7,
                                        tone: PixelControlTone.gold,
                                        onPressed: () {},
                                      ),
                                    ],
                                    child: const PixelTextPlate(
                                      child: Text(
                                        'Iron-bound doors answer with a low groan. '
                                        'The interaction layer is independent from the tiled frame.',
                                      ),
                                    ),
                                  )
                                : PixelButton(
                                    label: 'Reopen dialog',
                                    columns: 10,
                                    onPressed: () {
                                      setState(() => _dialogVisible = true);
                                    },
                                  ),
                          ),
                          _ShowcaseSection(
                            title: '512-tile stress card',
                            description:
                                'A 32×16 grid: 512 source tiles painted as one background.',
                            child: PixelPanel(
                              key: const ValueKey('showcase-512-tile-card'),
                              gridSize: const PixelGridSize(
                                columns: 32,
                                rows: 16,
                              ),
                              role: PixelSurfaceRole.panel,
                              seed: 512,
                              padding: const EdgeInsets.all(32),
                              semanticLabel: '512 tile Sundered Keep card',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PixelTextPlate(
                                    child: Text(
                                      'SUNDERED KEEP',
                                      style: TextStyle(
                                        color: pixelTheme.palette.ink,
                                        fontFamily: 'monospace',
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const PixelResourceBar(
                                    label: 'KEEP',
                                    value: 412,
                                    maximum: 512,
                                    columns: 24,
                                    tone: PixelControlTone.gold,
                                  ),
                                  const Spacer(),
                                  PixelTextPlate(
                                    child: Text(
                                      '32 columns  ×  16 rows',
                                      style: TextStyle(
                                        color: pixelTheme.palette.mutedInk,
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PixelUiPalette palette) {
    return PixelPanel(
      gridSize: const PixelGridSize(columns: 32, rows: 6),
      seed: 1,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          PixelSprite(
            region: SunderedKeepUi.atlas.region('timber_diagonal_a'),
            width: 64,
            height: 64,
            semanticLabel: 'Sundered Keep tile sample',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: PixelTextPlate(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUNDERED KEEP UI',
                    style: TextStyle(
                      color: palette.ink,
                      fontFamily: 'monospace',
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'DEVELOPMENT SHOWCASE  •  16 PX GRID',
                    style: TextStyle(
                      color: palette.gold,
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slot(int index, PixelInventorySlotState previewState) {
    final selectedState = _selectedSlot == index
        ? PixelInventorySlotState.selected
        : previewState;
    final art = index == 0
        ? const SizedBox.shrink()
        : PixelAssetSprite(
            assetPath: index.isEven ? _potionAsset : _swordAsset,
            width: 48,
            height: 48,
          );

    return PixelInventorySlot(
      key: ValueKey('showcase-slot-$index'),
      state: selectedState,
      semanticLabel: 'Preview slot ${index + 1}, ${selectedState.name}',
      seed: index,
      onTap: previewState == PixelInventorySlotState.disabled
          ? null
          : () => setState(() => _selectedSlot = index),
      child: art,
    );
  }
}

class _SkinPreviewCard extends StatelessWidget {
  const _SkinPreviewCard({
    super.key,
    required this.skin,
    required this.selected,
    required this.onSelected,
  });

  final PixelUiShowcaseSkin skin;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      gridSize: const PixelGridSize(columns: 15, rows: 10),
      atlas: skin.atlas,
      recipe: skin.recipe,
      seed: skin.name.hashCode,
      padding: const EdgeInsets.all(16),
      semanticLabel: '${skin.name} skin preview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PixelTextPlate(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            backgroundColor: const Color(0xFF100B16),
            borderColor: skin.accent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  skin.concept,
                  style: TextStyle(
                    color: skin.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  skin.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  skin.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9, height: 1.2),
                ),
              ],
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PixelBadge(
                label: selected ? 'ACTIVE' : 'SKIN',
                columns: 5,
                atlas: skin.atlas,
                recipe: skin.recipe,
                tone: selected
                    ? PixelControlTone.positive
                    : PixelControlTone.energy,
              ),
              PixelButton(
                label: selected ? 'Using' : 'Try',
                columns: 5,
                rows: 2,
                atlas: skin.atlas,
                recipe: skin.recipe,
                selected: selected,
                tone: PixelControlTone.accent,
                onPressed: onSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShowcaseSection extends StatelessWidget {
  const _ShowcaseSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = PixelUiThemeData.of(context).palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PixelTextPlate(
            key: ValueKey('showcase-text-plate-$title'),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: palette.ink,
                    fontFamily: 'monospace',
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: palette.mutedInk,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
