import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import '../battle/battle_page.dart';
import '../party/party_menu.dart';
import '../inventory/inventory_menu.dart';
import '../player/player.dart';
import 'cresca_map.dart';
import 'world_layers.dart';

enum _PlayerWindow { player, party, inventory }

const _gold = Color(0xFFAA8C59);
const _sprite =
    'assets/monsters/dark_fantasy_creatures_cc0/'
    'raw_originals/03_stylized_fantasy/Ranger_64x64/ranger_t.png';
final _groundAtlas = PixelAtlasDefinition(
  assetPath:
      'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
      '16x16_Block_Texture_Set/blocks__granite.png.png',
);
final _npcAtlas = PixelAtlasDefinition(
  assetPath:
      'assets/monsters/dark_fantasy_creatures_cc0/'
      'raw_originals/03_stylized_fantasy/Wizard/wizard_walking_0.png',
  sourceTileExtent: 48,
);

class ExplorationPage extends StatefulWidget {
  const ExplorationPage({super.key, this.player});

  final Player? player;

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  static const cells = 20;
  static const visibleCells = 8.4;
  static const npcColumn = cells ~/ 2;
  static const npcRow = cells ~/ 2 - 1;
  int _column = cells ~/ 2;
  int _row = cells ~/ 2;
  bool _faceLeft = false;
  bool _dialogueOpen = false;
  _PlayerWindow? _window;
  GlobalKey<NavigatorState> _windowNavigator = GlobalKey<NavigatorState>();
  late final Player _player = widget.player ?? Player.demo();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _move(int dx, int dy) {
    if (_dialogueOpen || _window != null) return;
    _focus.requestFocus();
    final nextColumn = (_column + dx).clamp(0, cells - 1);
    final nextRow = (_row + dy).clamp(0, cells - 1);
    if (isHouseTile(nextColumn, nextRow)) return;
    if (nextColumn == npcColumn && nextRow == npcRow) {
      _showNpcDialogue();
      return;
    }
    setState(() {
      _column = nextColumn;
      _row = nextRow;
      if (dx != 0) _faceLeft = dx < 0;
    });
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final direction = <LogicalKeyboardKey, (int, int)>{
      LogicalKeyboardKey.arrowUp: (0, -1),
      LogicalKeyboardKey.arrowDown: (0, 1),
      LogicalKeyboardKey.arrowLeft: (-1, 0),
      LogicalKeyboardKey.arrowRight: (1, 0),
    }[event.logicalKey];
    if (direction == null) return KeyEventResult.ignored;
    _move(direction.$1, direction.$2);
    return KeyEventResult.handled;
  }

  Future<void> _showNpcDialogue() async {
    if (_dialogueOpen) return;
    _dialogueOpen = true;
    try {
      final startBattle = await showDialog<bool>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          alignment: Alignment.bottomCenter,
          insetPadding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 24, bottom: 8),
                    child: PixelAssetSprite(
                      key: ValueKey('npc-portrait'),
                      assetPath:
                          'assets/monsters/dark_fantasy_creatures_cc0/'
                          'raw_originals/03_stylized_fantasy/Wizard/wizard_8.png',
                      width: 96,
                      height: 96,
                      semanticLabel: 'Cresca villager portrait',
                    ),
                  ),
                  SizedBox(
                    height: 256,
                    child: PixelPanel.expanded(
                      role: PixelSurfaceRole.dialog,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cresca Villager',
                            style: TextStyle(
                              color: Color(0xFFE5DAC5),
                              fontFamily: 'monospace',
                              fontSize: PixelUiMetrics.title,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Expanded(
                            child: Text(
                              'Ready to meet your end?',
                              style: TextStyle(
                                color: Color(0xFFE5DAC5),
                                fontFamily: 'monospace',
                                fontSize: PixelUiMetrics.body,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              PixelButton(
                                key: const ValueKey('start-battle'),
                                label: 'Yes',
                                columns: 5,
                                onPressed: () => Navigator.pop(context, true),
                              ),
                              const SizedBox(width: 12),
                              PixelButton(
                                key: const ValueKey('close-npc-dialogue'),
                                label: 'No',
                                columns: 5,
                                onPressed: () => Navigator.pop(context, false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      if (startBattle == true && mounted) {
        await Navigator.of(
          context,
        ).push<void>(MaterialPageRoute(builder: (_) => const BattlePage()));
      }
    } finally {
      _dialogueOpen = false;
      if (mounted) _focus.requestFocus();
    }
  }

  Widget _playerInfo() => Dialog(
    backgroundColor: Colors.transparent,
    elevation: 0,
    child: SizedBox(
      width: 360,
      height: 240,
      child: PixelPanel.expanded(
        role: PixelSurfaceRole.dialog,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _player.name,
              style: const TextStyle(
                color: _gold,
                fontFamily: 'monospace',
                fontSize: PixelUiMetrics.title,
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: Text(
                'Your journey begins here.\nPlayer details are coming soon.',
                style: TextStyle(
                  color: Color(0xFFE5DAC5),
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: PixelButton(
                key: const ValueKey('close-player-info'),
                label: 'Close',
                onPressed: _closeWindow,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  void _showWindow(_PlayerWindow window) {
    if (_window == window) {
      _closeWindow();
      return;
    }
    setState(() {
      _window = window;
      // Switching discards the previous window's detail/dialog navigation too.
      _windowNavigator = GlobalKey<NavigatorState>();
    });
  }

  void _closeWindow() {
    setState(() => _window = null);
    _focus.requestFocus();
  }

  Future<void> _backWindow() async {
    final navigator = _windowNavigator.currentState;
    if (navigator != null && await navigator.maybePop()) return;
    if (mounted && _window != null) _closeWindow();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: _window == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _window != null) _backWindow();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final insets = MediaQuery.paddingOf(context);
              final usableHeight = math.max(
                0.0,
                constraints.maxHeight - insets.vertical - 88,
              );
              // Preserve the tile scale from the original framed viewport.
              final tile =
                  math.min(
                    math.min(
                      constraints.maxWidth - insets.horizontal - 24,
                      560.0,
                    ),
                    usableHeight * .62,
                  ) /
                  visibleCells;
              final controlsSize = math.min(280.0, usableHeight * .34);
              return Stack(
                fit: StackFit.expand,
                children: [
                  _board(
                    Size(constraints.maxWidth, constraints.maxHeight),
                    tile,
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 88,
                          child: PixelPanel.expanded(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 60,
                                  height: 66,
                                  child: Material(
                                    color: const Color(0xFF242026),
                                    shape: const _HexagonBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      onTap: () =>
                                          _showWindow(_PlayerWindow.player),
                                      child: Semantics(
                                        button: true,
                                        label: 'Player information',
                                        child: const Center(
                                          child: Icon(
                                            Icons.close,
                                            color: Color(0xFFC35C55),
                                            size: 34,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Material(
                                    color: const Color(0xFF242026),
                                    shape: const _HexagonBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: const ValueKey('open-party'),
                                      onTap: () =>
                                          _showWindow(_PlayerWindow.party),
                                      child: Semantics(
                                        label: 'Party',
                                        button: true,
                                        child: Center(
                                          child: Icon(
                                            Icons.pets,
                                            color: _gold,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                SizedBox(
                                  width: 56,
                                  height: 56,
                                  child: Material(
                                    color: const Color(0xFF242026),
                                    shape: const _HexagonBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: const ValueKey('open-inventory'),
                                      onTap: () =>
                                          _showWindow(_PlayerWindow.inventory),
                                      child: Semantics(
                                        label: 'Inventory',
                                        button: true,
                                        child: const Center(
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            color: _gold,
                                            size: 32,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: controlsSize,
                            height: controlsSize,
                            child: Stack(
                              children: [
                                _direction(
                                  Alignment.topCenter,
                                  Icons.arrow_upward,
                                  'up',
                                  0,
                                  -1,
                                  controlsSize,
                                ),
                                _direction(
                                  Alignment.centerLeft,
                                  Icons.arrow_back,
                                  'left',
                                  -1,
                                  0,
                                  controlsSize,
                                ),
                                _direction(
                                  Alignment.centerRight,
                                  Icons.arrow_forward,
                                  'right',
                                  1,
                                  0,
                                  controlsSize,
                                ),
                                _direction(
                                  Alignment.bottomCenter,
                                  Icons.arrow_downward,
                                  'down',
                                  0,
                                  1,
                                  controlsSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_window != null)
                    Positioned.fill(
                      top: insets.top + 88,
                      bottom: insets.bottom,
                      left: insets.left,
                      right: insets.right,
                      child: ClipRect(
                        child: Navigator(
                          key: _windowNavigator,
                          onGenerateRoute: (_) => MaterialPageRoute<void>(
                            builder: (context) => switch (_window!) {
                              _PlayerWindow.player => ColoredBox(
                                color: Colors.transparent,
                                child: _playerInfo(),
                              ),
                              _PlayerWindow.party => PartyMenu(
                                onClose: _closeWindow,
                              ),
                              _PlayerWindow.inventory => InventoryMenu(
                                inventory: _player.inventory,
                                onClose: _closeWindow,
                              ),
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _board(Size size, double tile) {
    final playerLeft = (size.width - tile) / 2;
    final playerTop = (size.height - tile) / 2;
    return SizedBox(
      key: const ValueKey('world-viewport'),
      width: size.width,
      height: size.height,
      child: ClipRect(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              left: playerLeft - _column * tile,
              top: playerTop - _row * tile,
              width: cells * tile,
              height: cells * tile,
              child: SizedBox(
                key: const ValueKey('world-grid'),
                child: WorldLayers(
                  entries: [
                    WorldEntry(
                      z: WorldZ.ground,
                      child: Positioned.fill(
                        child: PixelAtlasBuilder(
                          atlas: _groundAtlas,
                          builder: (context, image, error) => CustomPaint(
                            painter: _GroundPainter(cells, image),
                          ),
                        ),
                      ),
                    ),
                    WorldEntry(
                      z: WorldZ.road,
                      child: Positioned.fill(
                        child: PixelAtlasBuilder(
                          atlas: SunderedKeepUi.theme.atlas,
                          builder: (context, image, error) =>
                              CustomPaint(painter: _VillagePainter(image)),
                        ),
                      ),
                    ),
                    for (final building in crescaBuildings)
                      for (var y = 0; y < building.bounds.height; y++)
                        for (var x = 0; x < building.bounds.width; x++)
                          WorldEntry(
                            z: y == 0 ? building.roofZ : building.wallZ,
                            depth: building.footprint.bottom,
                            child: Positioned(
                              key: ValueKey('house-${building.id}-$x-$y'),
                              left: (building.bounds.left + x) * tile,
                              top: (building.bounds.top + y) * tile,
                              width: tile,
                              height: tile,
                              child: Image.asset(
                                'assets/overworld/cottage/tile_${y}_$x.png',
                                filterQuality: FilterQuality.none,
                                fit: BoxFit.fill,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                    WorldEntry(
                      z: WorldZ.actor,
                      depth: npcRow + 1,
                      child: Positioned(
                        left: npcColumn * tile,
                        top: npcRow * tile,
                        width: tile,
                        height: tile,
                        child: PixelSprite(
                          key: const ValueKey('npc'),
                          atlas: _npcAtlas,
                          region: const PixelAtlasRegion(column: 0, row: 0),
                          width: tile,
                          height: tile,
                          semanticLabel: 'Cresca villager',
                        ),
                      ),
                    ),
                    WorldEntry(
                      z: WorldZ.actor,
                      depth: _row + 1,
                      // Equal and opposite camera/actor tweens keep the player
                      // centered even mid-step, inside the shared world layers.
                      child: AnimatedPositioned(
                        key: const ValueKey('player-position'),
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        left: _column * tile,
                        top: _row * tile,
                        width: tile,
                        height: tile,
                        child: Semantics(
                          label:
                              'Player at column ${_column + 1}, row ${_row + 1}',
                          child: SizedBox(
                            key: const ValueKey('player'),
                            child: Transform.flip(
                              flipX: _faceLeft,
                              child: Image.asset(
                                _sprite,
                                filterQuality: FilterQuality.none,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    WorldEntry(
                      z: WorldZ.atmosphere,
                      child: Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _FloorPainter(cells, _column, _row),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _direction(
    Alignment alignment,
    IconData icon,
    String name,
    int dx,
    int dy,
    double size,
  ) {
    return Align(
      alignment: alignment,
      child: SizedBox(
        width: size * .39,
        height: size * .39,
        child: Material(
          color: const Color(0xFF302C30),
          shape: const _DiamondBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: ValueKey('move-$name'),
            onTap: () => _move(dx, dy),
            child: Semantics(
              label: 'Move $name',
              button: true,
              child: Center(
                child: Icon(
                  icon,
                  color: const Color(0xFFE5DAC5),
                  size: size * .17,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroundPainter extends CustomPainter {
  const _GroundPainter(this.cells, this.image);
  final int cells;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final texture = image;
    if (texture == null) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = const Color(0xFF34363B),
      );
      return;
    }
    // One 16x16 source image fills each logical movement cell.
    final artTile = size.width / cells;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        canvas.drawImageRect(
          texture,
          const Rect.fromLTWH(0, 0, 16, 16),
          Rect.fromLTWH(x * artTile, y * artTile, artTile, artTile),
          paint,
        );
      }
    }
    final movementTile = artTile;
    paint.color = Colors.black.withValues(alpha: .2);
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * movementTile,
              y * movementTile,
              movementTile,
              movementTile,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter oldDelegate) =>
      cells != oldDelegate.cells || image != oldDelegate.image;
}

class _VillagePainter extends CustomPainter {
  const _VillagePainter(this.image);
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = image;
    if (atlas == null) return;
    final tile = size.width / 20;
    final artTile = tile;
    final paint = Paint()..filterQuality = FilterQuality.none;
    void stamp(int sx, int sy, double x, double y, {int height = 1}) {
      canvas.drawImageRect(
        atlas,
        Rect.fromLTWH(sx * 16, sy * 16, 16, height * 16),
        Rect.fromLTWH(x, y, artTile, artTile * height),
        paint,
      );
    }

    for (var y = 0; y < 20; y++) {
      for (var x = 0; x < 20; x++) {
        if (!isRoadTile(x, y)) continue;
        stamp(4 + x % 2, 1, x * tile, y * tile);
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * tile, y * tile, tile, tile),
            Paint()..color = Colors.black.withValues(alpha: .2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_VillagePainter oldDelegate) => image != oldDelegate.image;
}

class _FloorPainter extends CustomPainter {
  const _FloorPainter(this.cells, this.playerColumn, this.playerRow);
  final int cells;
  final int playerColumn;
  final int playerRow;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / cells;
    final paint = Paint();
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        // Square rings: diagonal neighbors count as one tile away, too.
        final distance = math.max(
          (x - playerColumn).abs(),
          (y - playerRow).abs(),
        );
        final darkness = switch (distance) {
          < 4 => 0.0,
          4 => 0.5,
          5 => 0.75,
          6 => 0.9,
          _ => 1.0,
        };
        if (darkness > 0) {
          paint.color = Colors.black.withValues(alpha: darkness);
          canvas.drawRect(Rect.fromLTWH(x * tile, y * tile, tile, tile), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FloorPainter oldDelegate) =>
      cells != oldDelegate.cells ||
      playerColumn != oldDelegate.playerColumn ||
      playerRow != oldDelegate.playerRow;
}

class _DiamondBorder extends _HexagonBorder {
  const _DiamondBorder();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right, rect.center.dy)
    ..lineTo(rect.center.dx, rect.bottom)
    ..lineTo(rect.left, rect.center.dy)
    ..close();
}

class _HexagonBorder extends ShapeBorder {
  const _HexagonBorder();

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(2);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()
    ..moveTo(rect.center.dx, rect.top)
    ..lineTo(rect.right, rect.top + rect.height * .25)
    ..lineTo(rect.right, rect.top + rect.height * .75)
    ..lineTo(rect.center.dx, rect.bottom)
    ..lineTo(rect.left, rect.top + rect.height * .75)
    ..lineTo(rect.left, rect.top + rect.height * .25)
    ..close();

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect.deflate(2));

  @override
  ShapeBorder scale(double t) => this;

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    canvas.drawPath(
      getOuterPath(rect.deflate(1)),
      Paint()
        ..color = _gold
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
