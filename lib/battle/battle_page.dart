import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'battle_engine.dart';
import 'battle_move.dart';
import 'combatant_motion.dart';
import '../party/creature_source_theme.dart';
import 'active_ally_border.dart';
import '../creatures/creature.dart';
import '../party/creature_info_page.dart';

const _ink = Color(0xFFE5DAC5);
const _brass = Color(0xFFAA8C59);

class BattlePage extends StatefulWidget {
  const BattlePage({super.key, this.roster, this.random});
  final List<BattleCreature>? roster;
  final math.Random? random;
  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> {
  int _activeAlly = 0;
  int? _selection;
  late final List<int?> _commands = List.filled(_allies.length, null);
  bool _resolving = false;
  int _round = 1;
  late final _random = widget.random ?? math.Random();
  late String _message = 'Choose a move for ${_allies.first.name}';
  int _actionPulse = 0;
  String? _actingId;
  Set<String> _hitIds = {};

  late final _roster = widget.roster ?? createShowcaseBattle();

  @override
  void initState() {
    super.initState();
    enterCombat(_roster);
    beginRound(_roster, _random);
    dealRoundMoves(_roster, _random);
  }

  Completer<void>? _inspectionClosed;

  Future<void> _inspect(BattleCreature combatant) async {
    if (_inspectionClosed != null) return;
    final gate = Completer<void>();
    _inspectionClosed = gate;
    final species = CreatureSpecies(
      id: combatant.species?.id ?? combatant.id,
      name: combatant.species?.name ?? combatant.name,
      frontAsset: combatant.species?.frontAsset ?? combatant.asset,
      backAsset: combatant.species?.backAsset ?? combatant.asset,
      baseStats: combatant.stats,
      moves: combatant.moves,
      innate: combatant.innate,
    );
    final snapshot = Creature(
      id: combatant.id,
      name: combatant.name,
      species: species,
      stats: combatant.stats,
      currentHp: combatant.hp,
      source: combatant.source,
      level: combatant.level,
    );
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => Scaffold(
            body: SafeArea(
              child: CreatureInfoPage(
                creature: snapshot,
                readOnly: true,
                combatStats: combatant.combatStats,
              ),
            ),
          ),
        ),
      );
    } finally {
      if (!gate.isCompleted) gate.complete();
      _inspectionClosed = null;
    }
  }

  Future<void> _waitForInspection() async {
    if (_inspectionClosed case final gate?) await gate.future;
  }

  @override
  void dispose() {
    final gate = _inspectionClosed;
    if (gate != null && !gate.isCompleted) gate.complete();
    super.dispose();
  }

  List<BattleCreature> get _allies =>
      _roster.where((c) => c.side == BattleSide.allies).toList();
  List<BattleCreature> get _enemies =>
      _roster.where((c) => c.side == BattleSide.enemies).toList();

  BattleAction? get _previewAction => _selection == null || _resolving
      ? null
      : BattleAction(
          _allies[_activeAlly],
          _allies[_activeAlly].offeredMoves[_selection!],
        );
  Set<String> get _previewTargets => _previewAction == null
      ? {}
      : targetsFor(_previewAction!, _roster).map((c) => c.id).toSet();
  Map<String, int> get _previewHp =>
      _previewAction == null ? {} : previewActionHp(_previewAction!, _roster);

  Widget? _selectionBorder(BattleCreature creature) {
    if (_resolving || !creature.alive) return null;
    if (creature.side == BattleSide.allies &&
        creature == _allies[_activeAlly]) {
      return ActiveAllyBorder(
        key: ValueKey('active-ally-${creature.slot}'),
        color: themeForSource(creature.source).palette.accent,
      );
    }
    if (_previewTargets.contains(creature.id)) {
      return ActiveAllyBorder(
        key: ValueKey('target-${creature.id}'),
        semanticLabel: 'Selected move target: ${creature.name}',
        color: creature.side == BattleSide.enemies
            ? Colors.red
            : themeForSource(creature.source).palette.accent,
      );
    }
    return null;
  }

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
          BattleAction(_allies[i], _allies[i].offeredMoves[_commands[i]!]),
      for (final enemy in _enemies.where((c) => c.alive))
        BattleAction(
          enemy,
          enemy.offeredMoves[_random.nextInt(enemy.offeredMoves.length)],
        ),
    ], _random);
    setState(() {
      _resolving = true;
      _selection = null;
    });
    for (final action in actions) {
      await _waitForInspection();
      if (!mounted) return;
      if (!action.user.alive) continue;
      setState(() {
        _actionPulse++;
        _actingId = action.user.id;
        _hitIds = {};
        _message = '${action.user.name}: ${action.move.name}';
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _waitForInspection();
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
      await _waitForInspection();
      if (!mounted) return;
      if (!_allies.any((c) => c.alive) || !_enemies.any((c) => c.alive)) break;
    }
    if (!mounted) return;
    endRound(_roster);
    final defeated =
        !_allies.any((c) => c.alive) || !_enemies.any((c) => c.alive);
    setState(
      () => _message = defeated ? 'Battle finished' : 'Round $_round resolved',
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _waitForInspection();
    if (!mounted) return;
    if (defeated) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _round++;
      beginRound(_roster, _random);
      dealRoundMoves(_roster, _random);
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
            flex: 1,
            child: PixelPanel.expanded(
              key: const ValueKey('combat-state-panel'),
              tileExtent: PixelUiMetrics.largeBorder,
              padding: const EdgeInsets.all(16),
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
            flex: 1,
            child: Theme(
              data: Theme.of(context).copyWith(
                extensions: [themeForSource(_allies[_activeAlly].source)],
              ),
              child: PixelPanel.expanded(
                key: const ValueKey('combat-command-panel'),
                tileExtent: PixelUiMetrics.largeBorder,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      height: 48,
                      child: SingleChildScrollView(
                        child: Text(
                          _message,
                          key: const ValueKey('battle-message'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeForSource(
                              _allies[_activeAlly].source,
                            ).palette.ink,
                            fontFamily: 'monospace',
                            fontSize: PixelUiMetrics.caption,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
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
                                      duration: const Duration(
                                        milliseconds: 280,
                                      ),
                                      curve: Curves.easeInOut,
                                      left: ally == 0
                                          ? 0
                                          : extent *
                                                (ally == _activeAlly ? .4 : .6),
                                      top: ally == _activeAlly
                                          ? 0
                                          : extent * .1,
                                      width:
                                          extent *
                                          (ally == _activeAlly ? 1 : .8),
                                      height:
                                          extent *
                                          (ally == _activeAlly ? 1 : .8),
                                      child: IgnorePointer(
                                        ignoring:
                                            ally != _activeAlly || _resolving,
                                        child: ExcludeSemantics(
                                          excluding: ally != _activeAlly,
                                          child: _MoveHexagon(
                                            key: ValueKey('ally-hexagon-$ally'),
                                            moves: _allies[ally].offeredMoves,
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
                      height: 40,
                      child: SingleChildScrollView(
                        child: Text(
                          _selection == null
                              ? 'Select a move'
                              : _moveDescription(
                                  _allies[_activeAlly]
                                      .offeredMoves[_selection!],
                                ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: themeForSource(
                              _allies[_activeAlly].source,
                            ).palette.ink,
                            fontFamily: 'monospace',
                            fontSize: PixelUiMetrics.caption,
                          ),
                        ),
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
          ),
        ],
      ),
    ),
  );

  Widget _bars(bool allies) => SizedBox(
    height: 56,
    child: Row(
      children: [
        for (final creature in (allies ? _allies : _enemies))
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: creature.slot == 0 ? 0 : 12),
              child: Theme(
                data: Theme.of(
                  context,
                ).copyWith(extensions: [themeForSource(creature.source)]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      creature.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: PixelUiMetrics.caption,
                        color: themeForSource(creature.source).palette.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: PixelResourceBar.expanded(
                        key: ValueKey('hp-${creature.id}'),
                        value: creature.hp.toDouble(),
                        previewValue:
                            (_previewHp[creature.id] ?? creature.hp) <
                                creature.hp
                            ? _previewHp[creature.id]!.toDouble()
                            : null,
                        maximum: creature.stats.maxHp.toDouble(),
                        semanticLabel: '${creature.name} HP',
                        showValues: true,
                        tileExtent: PixelUiMetrics.mediumBorder,
                        tone: allies
                            ? PixelControlTone.positive
                            : PixelControlTone.danger,
                      ),
                    ),
                  ],
                ),
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
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onLongPress: () =>
                              _inspect((allies ? _allies : _enemies)[i]),
                          child: PixelAssetSprite(
                            key: ValueKey('${allies ? 'ally' : 'enemy'}-$i'),
                            assetPath: (allies ? _allies : _enemies)[i].asset,
                            opacity: (allies ? _allies : _enemies)[i].alive
                                ? 1
                                : .25,
                            semanticLabel:
                                (allies ? _allies : _enemies)[i].name,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 8,
                    child: _selectionBorder((allies ? _allies : _enemies)[i]),
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
              onTap: enabled && i < moves.length ? () => onSelected(i) : null,
              child: Semantics(
                button: true,
                selected: selected == i,
                enabled: enabled && i < moves.length,
                label: i < moves.length ? moves[i].name : 'Empty move',
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Position by sector coordinates, not Align's remaining
                    // space (which moves wider labels toward the divider).
                    final centerX = i == 0 ? .5 : (i == 1 ? .25 : .75);
                    final centerY = i == 0 ? .25 : .625;
                    final width = constraints.maxWidth * (i == 0 ? .54 : .38);
                    final height = constraints.maxHeight * .25;
                    return Stack(
                      children: [
                        Positioned(
                          left: constraints.maxWidth * centerX - width / 2,
                          top: constraints.maxHeight * centerY - height / 2,
                          width: width,
                          height: height,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: SizedBox(
                                width: width,
                                child: Text(
                                  '${i + 1}\n${i < moves.length ? moves[i].name : 'EMPTY'}',
                                  key: ValueKey('move-option-$i'),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: enabled ? _ink : _brass,
                                    fontFamily: 'monospace',
                                    fontSize: PixelUiMetrics.caption,
                                    height: 1,
                                  ),
                                ),
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
