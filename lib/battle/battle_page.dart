import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'battle_engine.dart';
import 'battle_move.dart';
import 'combatant_motion.dart';

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
  late final List<int?> _commands = List.filled(_allies.length, null);
  bool _resolving = false;
  int _round = 1;
  final _random = math.Random();
  late String _message = 'Choose a move for ${_allies.first.name}';
  int _actionPulse = 0;
  String? _actingId;
  Set<String> _hitIds = {};

  final _roster = createShowcaseBattle();
  List<BattleCreature> get _allies =>
      _roster.where((c) => c.side == BattleSide.allies).toList();
  List<BattleCreature> get _enemies =>
      _roster.where((c) => c.side == BattleSide.enemies).toList();

  Future<void> _confirm() async {
    if (_selection == null || _resolving) return;
    _commands[_activeAlly] = _selection;
    final nextAlly = _allies.indexWhere(
      (c) => c.alive && _commands[_allies.indexOf(c)] == null,
    );
    if (nextAlly != -1) {
      setState(() {
        _activeAlly = nextAlly;
        _selection = null;
        _message = 'Choose a move for ${_allies[nextAlly].name}';
      });
      return;
    }
    final actions = orderActions([
      for (var i = 0; i < _allies.length; i++)
        if (_allies[i].alive && _commands[i] != null)
          BattleAction(_allies[i], _allies[i].moves[_commands[i]!]),
      for (final enemy in _enemies.where((c) => c.alive))
        BattleAction(enemy, enemy.moves[(_round - 1) % enemy.moves.length]),
    ], _random);
    setState(() {
      _resolving = true;
      _selection = null;
    });
    for (final action in actions) {
      if (!mounted) return;
      if (!action.user.alive) continue;
      setState(() {
        _actionPulse++;
        _actingId = action.user.id;
        _hitIds = {};
        _message = '${action.user.name}: ${action.move.name}';
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      final results = resolveAction(action, _roster);
      setState(() {
        _hitIds = results
            .where((r) => r.damage > 0)
            .map((r) => r.target.id)
            .toSet();
        final details = results
            .map(
              (r) =>
                  '${r.target.name}: ${[if (r.damage > 0) '-${r.damage} HP', if (r.healing > 0) '+${r.healing} HP', if (r.note.isNotEmpty) r.note].join(' ')}',
            )
            .join(', ');
        _message = '${action.user.name}: ${action.move.name}\n$details';
      });
      await Future<void>.delayed(const Duration(milliseconds: 600));
    }
    if (!mounted) return;
    endRound(_roster);
    final defeated =
        !_allies.any((c) => c.alive) || !_enemies.any((c) => c.alive);
    setState(
      () => _message = defeated ? 'Battle finished' : 'Round $_round resolved',
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (_round == 3 || defeated) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _round++;
      _activeAlly = _allies.indexWhere((c) => c.alive);
      _commands.fillRange(0, _commands.length, null);
      _resolving = false;
      _message = 'Choose a move for ${_allies[_activeAlly].name}';
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
                    height: 64,
                    child: Center(
                      child: Text(
                        _message,
                        key: const ValueKey('battle-message'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final extent = math.min(
                          constraints.maxHeight,
                          math.min(
                            constraints.maxWidth /
                                (_allies.length == 1 ? 1 : 1.4),
                            340.0,
                          ),
                        );
                        return Center(
                          child: SizedBox(
                            width: extent * (_allies.length == 1 ? 1 : 1.4),
                            height: extent,
                            child: Stack(
                              children: [
                                // Paint the inactive ally first, behind the active ally.
                                for (final ally in [
                                  if (_allies.length > 1) 1 - _activeAlly,
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
                                          moves: _allies[ally].moves,
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
                    height: 42,
                    child: Center(
                      child: Text(
                        _selection == null
                            ? 'Select a move'
                            : _moveDescription(
                                _allies[_activeAlly].moves[_selection!],
                              ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: _ink,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
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
        for (var i = 0; i < (allies ? _allies : _enemies).length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: i == 1 ? 12 : 0),
              child: PixelResourceBar.expanded(
                value: (allies ? _allies : _enemies)[i].hp.toDouble(),
                maximum: (allies ? _allies : _enemies)[i].stats.maxHp
                    .toDouble(),
                label: '${allies ? 'ALLY' : 'ENEMY'} ${i + 1}',
                showValues: true,
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
          for (var i = 0; i < (allies ? _allies : _enemies).length; i++)
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
                      child: CombatantMotion(
                        key: ValueKey('motion-${allies ? 'ally' : 'enemy'}-$i'),
                        allied: allies,
                        actionPulse:
                            _actingId == (allies ? _allies : _enemies)[i].id
                            ? _actionPulse
                            : 0,
                        hitPulse:
                            _hitIds.contains(
                              (allies ? _allies : _enemies)[i].id,
                            )
                            ? _actionPulse
                            : 0,
                        child: PixelAssetSprite(
                          key: ValueKey('${allies ? 'ally' : 'enemy'}-$i'),
                          assetPath: (allies ? _allies : _enemies)[i].asset,
                          opacity: (allies ? _allies : _enemies)[i].alive
                              ? 1
                              : .25,
                          semanticLabel:
                              '${allies ? 'Ally' : 'Enemy'} ${i + 1}',
                        ),
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

String _moveDescription(BattleMove move) =>
    '${move.split.name.toUpperCase()} | Potency ${move.potency ?? '-'} | Priority ${move.priority}\n'
    '${move.targetLabel}';

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
    required this.moves,
  });
  final int? selected;
  final bool enabled;
  final ValueChanged<int> onSelected;
  final List<BattleMove> moves;
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
                label: moves[i].name,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Position by sector coordinates, not Align's remaining
                    // space (which moves wider labels toward the divider).
                    final centerX = i == 0 ? .5 : (i == 1 ? .25 : .75);
                    final centerY = i == 0 ? .25 : .625;
                    final width = constraints.maxWidth * (i == 0 ? .54 : .38);
                    final height = constraints.maxHeight * .18;
                    return Stack(
                      children: [
                        Positioned(
                          left: constraints.maxWidth * centerX - width / 2,
                          top: constraints.maxHeight * centerY - height / 2,
                          width: width,
                          height: height,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${i + 1}\n${moves[i].name}',
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
                      ],
                    );
                  },
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
