import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';

const _gold = Color(0xFFAA8C59);
const _sprite =
    'assets/monsters/dark_fantasy_creatures_cc0/'
    'raw_originals/03_stylized_fantasy/Ranger_64x64/ranger_t.png';

class ExplorationPage extends StatefulWidget {
  const ExplorationPage({super.key});

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  static const cells = 7;
  int _column = cells ~/ 2;
  int _row = cells ~/ 2;
  bool _faceLeft = false;
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _move(int dx, int dy) {
    _focus.requestFocus();
    setState(() {
      _column = (_column + dx).clamp(0, cells - 1);
      _row = (_row + dy).clamp(0, cells - 1);
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

  void _showPlayer() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252329),
        title: const Text('Youngest of Cresca', style: TextStyle(color: _gold)),
        content: const Text(
          'Your journey begins here.\nPlayer details are coming soon.',
          style: TextStyle(color: Color(0xFFE5DAC5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111216),
      body: SafeArea(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Column(
            children: [
              SizedBox(
                height: 88,
                child: PixelPanel.expanded(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 60,
                      height: 66,
                      child: Material(
                        color: const Color(0xFF242026),
                        shape: const _HexagonBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _showPlayer,
                          child: const Semantics(
                            button: true,
                            label: 'Player information',
                            child: Center(
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
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final boardSize = math.min(
                      math.min(constraints.maxWidth - 24, 560.0),
                      constraints.maxHeight * .62,
                    );
                    final controlsSize = math.min(
                      280.0,
                      constraints.maxHeight * .34,
                    );
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Center(child: _board(boardSize)),
                        SizedBox(
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
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _board(double size) {
    final tile = size / cells;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _gold.withValues(alpha: .45)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24)],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _FloorPainter(cells))),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              left: _column * tile,
              top: _row * tile,
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

class _FloorPainter extends CustomPainter {
  const _FloorPainter(this.cells);
  final int cells;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / cells;
    final paint = Paint();
    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final rect = Rect.fromLTWH(x * tile, y * tile, tile, tile).deflate(1);
        paint.color = (x + y) % 2 == 0
            ? const Color(0xFF34363B)
            : const Color(0xFF2C2E33);
        canvas.drawRect(rect, paint);
        paint.color = const Color(0xFF45464A);
        canvas.drawLine(rect.topLeft, rect.topRight, paint);
        canvas.drawLine(rect.topLeft, rect.bottomLeft, paint);
        if ((x * 3 + y) % 5 == 0) {
          paint.color = const Color(0xFF222429);
          final crack = Path()
            ..moveTo(rect.left + tile * .6, rect.top)
            ..lineTo(rect.left + tile * .5, rect.top + tile * .18)
            ..lineTo(rect.left + tile * .65, rect.top + tile * .28);
          paint.style = PaintingStyle.stroke;
          canvas.drawPath(crack, paint);
          paint.style = PaintingStyle.fill;
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FloorPainter oldDelegate) => cells != oldDelegate.cells;
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
