import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import '../creatures/showcase_party.dart';
import 'turn_order.dart';

const _ink = Color(0xFFE5DAC5);
const _brass = Color(0xFFAA8C59);

class BattlePage extends StatefulWidget {
  const BattlePage({super.key});
  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  int _activeAlly = 0;
  int? _selection;
  final List<int?> _commands = [null, null];
  bool _resolving = false;
  int _round = 1;
  final _random = math.Random();
  String _message = 'Choose a move for Ally 1';

  Future<void> _confirm() async {
    if (_selection == null || _resolving) return;
    _commands[_activeAlly] = _selection;
    if (_activeAlly == 0) {
      setState(() {
        _activeAlly = 1;
        _selection = null;
        _message = 'Choose a move for Ally 2';
      });
      return;
    }
    final actions = orderBySpeed(
      [
        for (var i = 0; i < 2; i++)
          (
            speed: showcaseParty[i].stats.spe,
            message: 'Ally ${i + 1} uses Move ${_commands[i]! + 1}',
          ),
        for (var i = 0; i < 2; i++)
          (
            speed: showcaseParty[i].species.baseStats.spe,
            message: 'Enemy ${i + 1} takes its turn',
          ),
      ],
      (actor) => actor.speed,
      _random,
    );
    setState(() {
      _resolving = true;
      _selection = null;
      _message = actions.first.message;
    });
    // UI-only resolution: no damage, stats, or combat rules yet.
    for (final message in [
      ...actions.skip(1).map((action) => action.message),
      'Round $_round resolved',
    ]) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() => _message = message);
    }
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    if (_round == 3) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _round++;
      _activeAlly = 0;
      _commands.fillRange(0, 2, null);
      _resolving = false;
      _message = 'Choose a move for Ally 1';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF151419),
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PixelPanel.expanded(
              tileExtent: 8,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _bars(false),
                  Expanded(child: _creatures(false)),
                  Expanded(child: _creatures(true)),
                  _bars(true),
                ],
              ),
            ),
          ),
          Expanded(
            child: PixelPanel.expanded(
              tileExtent: 8,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: Text(
                        _message,
                        key: const ValueKey('battle-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final extent = math.min(
                          constraints.maxHeight,
                          math.min(constraints.maxWidth / 1.4, 340.0),
                        );
                        return Center(
                          child: SizedBox(
                            width: extent * 1.4,
                            height: extent,
                            child: Stack(
                              children: [
                                // Paint the inactive ally first, behind the active ally.
                                for (final ally in [
                                  1 - _activeAlly,
                                  _activeAlly,
                                ])
                                  AnimatedPositioned(
                                    key: ValueKey('hexagon-position-$ally'),
                                    duration: const Duration(milliseconds: 280),
                                    curve: Curves.easeInOut,
                                    left: ally == 0
                                        ? 0
                                        : extent *
                                              (ally == _activeAlly ? .4 : .6),
                                    top: ally == _activeAlly ? 0 : extent * .1,
                                    width:
                                        extent * (ally == _activeAlly ? 1 : .8),
                                    height:
                                        extent * (ally == _activeAlly ? 1 : .8),
                                    child: IgnorePointer(
                                      ignoring:
                                          ally != _activeAlly || _resolving,
                                      child: ExcludeSemantics(
                                        excluding: ally != _activeAlly,
                                        child: _MoveHexagon(
                                          key: ValueKey('ally-hexagon-$ally'),
                                          selected: ally == _activeAlly
                                              ? _selection
                                              : _commands[ally],
                                          enabled:
                                              ally == _activeAlly &&
                                              !_resolving,
                                          onSelected: (index) => setState(
                                            () => _selection = index,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: PixelButton(
                      key: const ValueKey('confirm-move'),
                      label: 'SELECT',
                      expandToFill: true,
                      onPressed: _selection == null || _resolving
                          ? null
                          : _confirm,
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

  Widget _bars(bool allies) => SizedBox(
    height: 40,
    child: Row(
      children: [
        for (var i = 0; i < 2; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 1 ? 12 : 0),
              child: PixelResourceBar.expanded(
                value: 1,
                maximum: 1,
                label: '${allies ? 'ALLY' : 'ENEMY'} ${i + 1}',
                showValues: false,
                tileExtent: 6,
                tone: allies
                    ? PixelControlTone.positive
                    : PixelControlTone.danger,
              ),
            ),
          ),
      ],
    ),
  );
  Widget _creatures(bool allies) => Align(
    alignment: allies ? Alignment.centerLeft : Alignment.centerRight,
    child: FractionallySizedBox(
      widthFactor: .78,
      heightFactor: 1,
      child: Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: 18,
                    child: allies && !_resolving && _activeAlly == i
                        ? const Icon(
                            Icons.arrow_downward,
                            color: _brass,
                            size: 18,
                          )
                        : null,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: PixelAssetSprite(
                        key: ValueKey('${allies ? 'ally' : 'enemy'}-$i'),
                        assetPath: allies
                            ? showcaseParty[i].species.backAsset
                            : showcaseParty[i].species.frontAsset,
                        semanticLabel: '${allies ? 'Ally' : 'Enemy'} ${i + 1}',
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

// Three equal rhombi meet at the center of a point-up hexagon.
Path _sector(Size size, int index) {
  final w = size.width;
  final h = size.height;
  final points = <Offset>[
    Offset(w / 2, 0),
    Offset(w, h / 4),
    Offset(w, h * .75),
    Offset(w / 2, h),
    Offset(0, h * .75),
    Offset(0, h / 4),
  ];
  final vertices = switch (index) {
    0 => [points[5], points[0], points[1], Offset(w / 2, h / 2)],
    1 => [points[5], Offset(w / 2, h / 2), points[3], points[4]],
    _ => [Offset(w / 2, h / 2), points[1], points[2], points[3]],
  };
  return Path()..addPolygon(vertices, true);
}

class _MoveHexagon extends StatelessWidget {
  const _MoveHexagon({
    super.key,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });
  final int? selected;
  final bool enabled;
  final ValueChanged<int> onSelected;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      for (var i = 0; i < 3; i++)
        ClipPath(
          clipper: _SectorClipper(i),
          child: Material(
            color: selected == i
                ? const Color(0xFF725C3C)
                : const Color(0xFF302C35),
            child: InkWell(
              onTap: enabled ? () => onSelected(i) : null,
              child: Semantics(
                button: true,
                selected: selected == i,
                enabled: enabled,
                label: 'Move ${i + 1}',
                child: Align(
                  alignment: [
                    const Alignment(0, -.5),
                    const Alignment(-.5, .25),
                    const Alignment(.5, .25),
                  ][i],
                  child: Text(
                    '${i + 1}\nMOVE ${i + 1}',
                    key: ValueKey('move-option-$i'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: enabled ? _ink : _brass,
                      fontFamily: 'monospace',
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      IgnorePointer(child: CustomPaint(painter: _HexagonOutline())),
    ],
  );
}

class _SectorClipper extends CustomClipper<Path> {
  const _SectorClipper(this.index);
  final int index;
  @override
  Path getClip(Size size) => _sector(size, index);
  @override
  bool shouldReclip(_SectorClipper oldClipper) => index != oldClipper.index;
}

class _HexagonOutline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _brass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      canvas.drawPath(_sector(size, i), paint);
    }
  }

  @override
  bool shouldRepaint(_HexagonOutline oldDelegate) => false;
}
