import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import '../battle/battle_page.dart';
import '../party/party_menu.dart';
import 'cresca_map.dart';

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
  const ExplorationPage({super.key});

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
  bool _partyOpen = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _move(int dx, int dy) {
    if (_dialogueOpen || _partyOpen) return;
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
                    height: 230,
                    child: PixelPanel.expanded(
                      role: PixelSurfaceRole.dialog,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            child: Text(
                              'Ready to meet your end?',
                              style: TextStyle(
                                color: Color(0xFFE5DAC5),
                                fontFamily: 'monospace',
                                fontSize: 18,
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

  void _showPlayer() {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
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
                const Text(
                  'Youngest of Cresca',
                  style: TextStyle(
                    color: _gold,
                    fontFamily: 'monospace',
                    fontSize: 18,
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
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  Future<void> _showParty() async {
    if (_partyOpen) return;
    _partyOpen = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        pageBuilder: (context, _, _) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 88),
            child: PartyMenu(onClose: () => Navigator.pop(context)),
          ),
        ),
      );
    } finally {
      _partyOpen = false;
      if (mounted) _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                _board(Size(constraints.maxWidth, constraints.maxHeight), tile),
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
                                    onTap: _showPlayer,
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
                                    onTap: _showParty,
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
              ],
            );
          },
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
              // Do not clamp the camera at world edges: the player stays centered.
              left: playerLeft - _column * tile,
              top: playerTop - _row * tile,
              width: cells * tile,
              height: cells * tile,
              child: PixelAtlasBuilder(
                atlas: _groundAtlas,
                builder: (context, image, error) => CustomPaint(
                  key: const ValueKey('world-grid'),
                  painter: _GroundPainter(cells, image),
                  foregroundPainter: _FloorPainter(cells, _column, _row),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: PixelAtlasBuilder(
                          atlas: SunderedKeepUi.theme.atlas,
                          builder: (context, image, error) =>
                              CustomPaint(painter: _VillagePainter(image)),
                        ),
                      ),
                      Positioned(
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
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: playerLeft,
              top: playerTop,
              width: tile,
              height: tile,
              child: Semantics(
                label: 'Player at column ${_column + 1}, row ${_row + 1}',
                child: Container(
                  key: const ValueKey('player'),
                  decoration: BoxDecoration(
                    color: const Color(0xFF886345).withValues(alpha: .5),
                    border: Border.all(color: _gold.withValues(alpha: .7)),
                  ),
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
    // Each logical movement cell contains four 16x16 art tiles.
    final artTile = size.width / cells / 2;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    for (var y = 0; y < cells * 2; y++) {
      for (var x = 0; x < cells * 2; x++) {
        canvas.drawImageRect(
          texture,
          const Rect.fromLTWH(0, 0, 16, 16),
          Rect.fromLTWH(x * artTile, y * artTile, artTile, artTile),
          paint,
        );
      }
    }
    final movementTile = artTile * 2;
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
    final artTile = tile / 2;
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
        for (var dy = 0; dy < 2; dy++) {
          for (var dx = 0; dx < 2; dx++) {
            stamp(
              4 + (x + dx) % 2,
              1,
              x * tile + dx * artTile,
              y * tile + dy * artTile,
            );
          }
        }
        if ((x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * tile, y * tile, tile, tile),
            Paint()..color = Colors.black.withValues(alpha: .2),
          );
        }
      }
    }
    for (final house in crescaHouses) {
      final left = house.left * tile;
      final top = house.top * tile;
      // Six by six art tiles form each cottage; three rows of roof above
      // brick walls, inset windows and a closed two-tile wooden door.
      for (var y = 3; y < 6; y++) {
        for (var x = 0; x < 6; x++) {
          stamp(1, 1, left + x * artTile, top + y * artTile);
        }
      }
      // The atlas's diagonal timbers form continuous gable edges. Fill the
      // roof with darkened brick tiles, clipped to the same triangular outline.
      canvas.save();
      canvas.clipPath(
        Path()
          ..moveTo(left, top + 3 * artTile)
          ..lineTo(left + 3 * artTile, top)
          ..lineTo(left + 6 * artTile, top + 3 * artTile)
          ..close(),
      );
      paint.colorFilter = const ColorFilter.mode(
        Color(0xFF70545C),
        BlendMode.modulate,
      );
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 6; x++) {
          stamp(1, 1, left + x * artTile, top + y * artTile);
        }
      }
      paint.colorFilter = null;
      canvas.restore();
      for (var y = 0; y < 3; y++) {
        stamp(3, 5, left + (2 - y) * artTile, top + y * artTile);
        canvas.save();
        canvas.translate(left + (4 + y) * artTile, top + y * artTile);
        canvas.scale(-1, 1);
        stamp(3, 5, 0, 0);
        canvas.restore();
      }
      stamp(0, 7, left + artTile, top + 3 * artTile);
      stamp(0, 7, left + 4 * artTile, top + 3 * artTile);
      stamp(2, 9, left + 2 * artTile, top + 4 * artTile, height: 2);
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
