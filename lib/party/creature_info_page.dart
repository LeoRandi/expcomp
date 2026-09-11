import 'package:flutter/material.dart';
import '../battle/battle_move.dart';
import '../creatures/creature.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'creature_source_theme.dart';

class CreatureInfoPage extends StatefulWidget {
  const CreatureInfoPage({
    super.key,
    required this.creature,
    this.readOnly = false,
    this.combatStats = const {},
  });
  final bool readOnly;
  final Map<String, int> combatStats;
  final Creature creature;
  @override
  State<CreatureInfoPage> createState() => _CreatureInfoPageState();
}

class _CreatureInfoPageState extends State<CreatureInfoPage> {
  late final Map<String, int> _points = Map.of(widget.creature.extraPoints);
  late final List<BattleMove?> _moves = List.of(widget.creature.equippedMoves);
  late String _name = widget.creature.name;

  Future<void> _rename() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => Theme(
        data: _sourceTheme(context),
        child: _RenameDialog(name: _name),
      ),
    );
    if (name != null && mounted) setState(() => _name = name);
  }

  int get _allocated => _points.values.fold(0, (a, b) => a + b);

  void _changePoint(String stat, int delta) {
    final next = (_points[stat] ?? 0) + delta;
    if (next < 0 || _allocated + delta > widget.creature.pointBudget) return;
    if ((stat == 'CRI' || stat == 'EVA') &&
        widget.creature.baseStats.values[stat]! + next > 100) {
      return;
    }
    setState(() => _points[stat] = next);
  }

  ThemeData _sourceTheme(BuildContext context) {
    final source = themeForSource(widget.creature.source);
    return Theme.of(context).copyWith(
      extensions: [source],
      textTheme: Theme.of(context).textTheme
          .apply(
            bodyColor: source.palette.ink,
            displayColor: source.palette.ink,
          )
          .copyWith(
            bodyMedium: TextStyle(
              color: source.palette.ink,
              fontFamily: 'monospace',
              fontSize: PixelUiMetrics.body,
            ),
          ),
    );
  }

  Future<void> _changeMove(int slot) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => Theme(
        data: _sourceTheme(context),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: SizedBox(
            width: 460,
            height: 480,
            child: PixelPanel.expanded(
              tileExtent: PixelUiMetrics.largeBorder,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Move slot ${slot + 1}',
                    style: TextStyle(
                      color: themeForSource(widget.creature.source).palette.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final move in moveCatalog)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: SizedBox(
                              height: 48,
                              child: PixelButton(
                                label: move.name,
                                expandToFill: true,
                                onPressed:
                                    _moves.asMap().entries.any(
                                      (e) =>
                                          e.key != slot &&
                                          e.value?.id == move.id,
                                    )
                                    ? null
                                    : () => Navigator.pop(context, move.id),
                              ),
                            ),
                          ),
                        SizedBox(
                          height: 48,
                          child: PixelButton(
                            label: 'EMPTY SLOT',
                            expandToFill: true,
                            onPressed: () => Navigator.pop(context, 'empty'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: PixelButton(
                      label: 'BACK',
                      expandToFill: true,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    setState(
      () => _moves[slot] = choice == 'empty'
          ? null
          : moveCatalog.firstWhere((m) => m.id == choice),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creature = widget.creature;
    return Theme(
      data: _sourceTheme(context),
      child: DefaultTextStyle(
        style: TextStyle(
          color: themeForSource(creature.source).palette.ink,
          fontFamily: 'monospace',
          fontSize: PixelUiMetrics.body,
        ),
        child: Material(
          color: themeForSource(creature.source).palette.canvas,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Expanded(
                  child: PixelPanel.expanded(
                    tileExtent: PixelUiMetrics.largeBorder,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      key: const ValueKey('creature-info-scroll'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 96,
                                height: 112,
                                child: PixelPanel.expanded(
                                  tileExtent: PixelUiMetrics.mediumBorder,
                                  role: PixelSurfaceRole.inset,
                                  padding: const EdgeInsets.all(8),
                                  child: PixelAssetSprite(
                                    assetPath: creature.species.frontAsset,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _name,
                                            style: const TextStyle(
                                              fontSize: PixelUiMetrics.title,
                                            ),
                                          ),
                                        ),
                                        if (!widget.readOnly)
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: PixelButton(
                                              key: const ValueKey(
                                                'rename-creature',
                                              ),
                                              label: '',
                                              semanticLabel: 'Rename creature',
                                              leading: Icon(
                                                Icons.edit,
                                                size: 16,
                                                color: themeForSource(
                                                  creature.source,
                                                ).palette.ink,
                                              ),
                                              tileExtent: 8,
                                              role: PixelSurfaceRole.inset,
                                              expandToFill: true,
                                              onPressed: _rename,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(creature.species.name),
                                    const SizedBox(height: 8),
                                    Text('Level ${creature.level}'),
                                    Text(creature.source.label),
                                    Text(
                                      widget.readOnly
                                          ? 'HP: ${creature.currentHp}/${creature.maxHp}'
                                          : 'Max HP: ${creature.baseStats.withExtra(_points).maxHp}',
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _InfoSection(
                            id: 'item',
                            title: 'EQUIPPED ITEM',
                            child: _Frame(child: Text('No item equipped.')),
                          ),
                          _InfoSection(
                            id: 'stats',
                            title: widget.readOnly
                                ? 'STATS (COMBAT)'
                                : 'STATS  $_allocated / ${creature.pointBudget}',
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final columns = constraints.maxWidth >= 520
                                    ? 2
                                    : 1;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final stat in statNames)
                                      SizedBox(
                                        width:
                                            (constraints.maxWidth -
                                                (columns - 1) * 8) /
                                            columns,
                                        child: _statRow(stat),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          _InfoSection(
                            id: 'abilities',
                            title: 'ABILITIES',
                            child: Column(
                              children: [
                                _InfoSection(
                                  id: 'innates',
                                  title: 'INNATES',
                                  child: LayoutBuilder(
                                    builder: (context, constraints) => Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (var i = 0; i < 4; i++)
                                          SizedBox(
                                            width: constraints.maxWidth >= 480
                                                ? (constraints.maxWidth - 8) / 2
                                                : constraints.maxWidth,
                                            child: _Frame(
                                              disabled: i > 0,
                                              child: Text(
                                                style: const TextStyle(
                                                  fontSize:
                                                      PixelUiMetrics.caption,
                                                ),
                                                i == 0
                                                    ? '${creature.species.innate?.name ?? 'No innate'}\n${creature.species.innate?.description ?? ''}'
                                                    : 'LOCKED\nUnlocks at level ${[1, 10, 20, 40][i]}',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                _InfoSection(
                                  id: 'moves',
                                  title: 'COMBAT MOVES',
                                  child: Column(
                                    children: [
                                      const Text(
                                        'Five move slots. Three moves are drawn each round. A used move sits out the next round.',
                                        style: TextStyle(
                                          fontSize: PixelUiMetrics.caption,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      for (var i = 0; i < 5; i++) _moveCard(i),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: PixelButton(
                          key: const ValueKey('info-back'),
                          label: 'BACK',
                          expandToFill: true,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                    if (!widget.readOnly) const SizedBox(width: 8),
                    if (!widget.readOnly)
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: PixelButton(
                            key: const ValueKey('info-save'),
                            label: 'SAVE',
                            expandToFill: true,
                            onPressed: () {
                              creature.saveBuild(_points, _moves, name: _name);
                              Navigator.pop(context, true);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statRow(String stat) {
    final extra = _points[stat] ?? 0;
    final base = widget.creature.baseStats.values[stat]!;
    if (widget.readOnly) {
      final delta = (widget.combatStats[stat] ?? base) - base;
      return _Frame(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$stat: ${widget.combatStats[stat]?.toString()}',
                key: ValueKey('combat-total-$stat'),
                style: TextStyle(
                  fontSize: PixelUiMetrics.body,
                  color: delta > 0
                      ? Colors.greenAccent
                      : delta < 0
                      ? Colors.redAccent
                      : themeForSource(widget.creature.source).palette.ink,
                ),
              ),
            ),
            if (delta != 0)
              Text(
                '$base' + (delta > 0 ? '+$delta' : '$delta'),
                key: ValueKey('combat-delta-$stat'),
                style: TextStyle(
                  fontSize: PixelUiMetrics.body,
                  color: delta > 0
                      ? Colors.greenAccent
                      : delta < 0
                      ? Colors.redAccent
                      : themeForSource(widget.creature.source).palette.mutedInk,
                ),
              ),
          ],
        ),
      );
    }

    return _Frame(
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$stat: $base + $extra',
              style: const TextStyle(fontSize: PixelUiMetrics.body),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: PixelButton(
              key: ValueKey('minus-$stat'),
              tileExtent: PixelUiMetrics.mediumBorder,
              role: PixelSurfaceRole.inset,
              label: '-',
              expandToFill: true,
              onPressed: extra == 0 ? null : () => _changePoint(stat, -1),
            ),
          ),
          SizedBox(
            width: 40,
            height: 40,
            child: PixelButton(
              key: ValueKey('plus-$stat'),
              tileExtent: PixelUiMetrics.mediumBorder,
              role: PixelSurfaceRole.inset,
              label: '+',
              expandToFill: true,
              onPressed:
                  _allocated >= widget.creature.pointBudget ||
                      ((stat == 'CRI' || stat == 'EVA') && base + extra >= 100)
                  ? null
                  : () => _changePoint(stat, 1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _moveCard(int index) {
    final move = _moves[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _Frame(
        disabled: move == null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              move?.name ?? 'EMPTY MOVE SLOT ${index + 1}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: PixelUiMetrics.body,
              ),
            ),
            if (move != null) ...[
              const SizedBox(height: 6),
              Text(
                '${move.split.name.toUpperCase()} | Potency: ${move.potency ?? '-'} | Priority: ${move.priority}',
                style: const TextStyle(fontSize: PixelUiMetrics.caption),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _TargetDiagram(move.target),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${move.targetLabel}\n${move.effectDescription}',
                      style: const TextStyle(fontSize: PixelUiMetrics.caption),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            if (!widget.readOnly)
              SizedBox(
                height: 40,
                child: PixelButton(
                  key: ValueKey('change-move-$index'),
                  tileExtent: PixelUiMetrics.mediumBorder,
                  role: PixelSurfaceRole.inset,
                  label: 'CHANGE',
                  expandToFill: true,
                  onPressed: () => _changeMove(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({required this.child, this.disabled = false});
  final Widget child;
  final bool disabled;
  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(
        child: IgnorePointer(
          child: ColorFiltered(
            colorFilter: ColorFilter.matrix(
              disabled
                  ? const [
                      .2126,
                      .7152,
                      .0722,
                      0,
                      0,
                      .2126,
                      .7152,
                      .0722,
                      0,
                      0,
                      .2126,
                      .7152,
                      .0722,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]
                  : const [
                      1,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ],
            ),
            child: const PixelPanel.expanded(
              role: PixelSurfaceRole.inset,
              tileExtent: PixelUiMetrics.mediumBorder,
              child: SizedBox.shrink(),
            ),
          ),
        ),
      ),
      Padding(padding: const EdgeInsets.all(12), child: child),
    ],
  );
}

class _InfoSection extends StatefulWidget {
  const _InfoSection({
    required this.id,
    required this.title,
    required this.child,
  });
  final String id;
  final String title;
  final Widget child;
  @override
  State<_InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends State<_InfoSection> {
  bool expanded = true;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: PixelButton(
            key: ValueKey('section-${widget.id}'),
            label: '${widget.title} ${expanded ? '[-]' : '[+]'}',
            expandToFill: true,
            onPressed: () => setState(() => expanded = !expanded),
          ),
        ),
        if (expanded)
          Padding(padding: const EdgeInsets.only(top: 8), child: widget.child),
      ],
    ),
  );
}

/// Positions mirror combat: enemies above, user bottom-left, ally bottom-right.
class _TargetDiagram extends StatelessWidget {
  const _TargetDiagram(this.target);
  final MoveTarget target;
  @override
  Widget build(BuildContext context) {
    final selected = switch (target) {
      MoveTarget.closestEnemy => {0},
      MoveTarget.furthestEnemy => {1},
      MoveTarget.healthiestEnemy => {0, 1},
      MoveTarget.self => {2},
      MoveTarget.bothAllies => {2, 3},
      MoveTarget.bothEnemies => {0, 1},
      MoveTarget.allOthers => {0, 1, 3},
    };
    return SizedBox(
      width: 72,
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (var i = 0; i < 4; i++)
            SizedBox(
              width: 32,
              height: 32,
              child: PixelPanel.expanded(
                tileExtent: PixelUiMetrics.mediumBorder,
                role: PixelSurfaceRole.inset,
                padding: const EdgeInsets.all(8),
                child: ColoredBox(
                  color: selected.contains(i)
                      ? (i < 2
                            ? const Color(0xFFB95C56)
                            : const Color(0xFF64AD80))
                      : const Color(0xFF555555),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.name});
  final String name;
  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final _controller = TextEditingController(text: widget.name);
  void _done() {
    final name = _controller.text.trim();
    if (name.isNotEmpty) Navigator.pop(context, name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    child: SingleChildScrollView(
      child: SizedBox(
        width: 360,
        height: 288,
        child: PixelPanel.expanded(
          tileExtent: 16,
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Creature name',
                style: TextStyle(
                  fontSize: 24,
                  color: PixelUiThemeData.of(context).palette.ink,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: PixelPanel.expanded(
                  role: PixelSurfaceRole.inset,
                  tileExtent: 8,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: TextField(
                    key: const ValueKey('creature-name-input'),
                    controller: _controller,
                    autofocus: true,
                    maxLength: 24,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(
                      fontSize: 16,
                      color: PixelUiThemeData.of(context).palette.ink,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _done(),
                  ),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: PixelButton(
                        label: 'BACK',
                        expandToFill: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: PixelButton(
                        key: const ValueKey('rename-done'),
                        label: 'DONE',
                        expandToFill: true,
                        onPressed: _controller.text.trim().isEmpty
                            ? null
                            : _done,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
