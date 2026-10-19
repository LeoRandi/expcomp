import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import '../battle/battle_page.dart';
import '../party/party_menu.dart';
import '../inventory/inventory_menu.dart';
import '../player/player.dart';
import '../creatures/showcase_party.dart';
import 'cresca_town.dart';
import 'area_arrival_title.dart';
import 'building_tile.dart';
import 'town_scenery.dart';
import 'world_layers.dart';
import 'world_lighting.dart';
import 'world_map.dart';

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
final _townRoadAtlas = PixelAtlasDefinition(assetPath: crescaPavingAsset);

class ExplorationPage extends StatefulWidget {
  const ExplorationPage({
    super.key,
    this.player,
    this.initialArea = WorldArea.town,
  });

  final Player? player;
  final WorldArea initialArea;

  @override
  State<ExplorationPage> createState() => _ExplorationPageState();
}

class _ExplorationPageState extends State<ExplorationPage> {
  static const visibleCells = 8.4;
  late ExplorationMap _map;
  late int _column;
  late int _row;
  final Map<String, Offset> _npcPositions = {};
  final Map<String, int> _routeSteps = {};
  late final Timer _routineTimer;
  int _routineTick = 0;
  bool _faceLeft = false;
  bool _dialogueOpen = false;
  _PlayerWindow? _window;
  GlobalKey<NavigatorState> _windowNavigator = GlobalKey<NavigatorState>();
  late final Player _player = widget.player ?? Player.demo();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _enterArea(widget.initialArea);
    _routineTimer = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (_dialogueOpen ||
          _window != null ||
          !mounted ||
          ModalRoute.of(context)?.isCurrent != true ||
          (WidgetsBinding.instance.lifecycleState != null &&
              WidgetsBinding.instance.lifecycleState !=
                  AppLifecycleState.resumed)) {
        return;
      }
      setState(() {
        _routineTick++;
        for (final npc in _map.npcs) {
          if (npc.route.isEmpty) continue;
          final step = ((_routeSteps[npc.id] ?? 0) + 1) % npc.route.length;
          final next = npc.route[step];
          if (next == Offset(_column.toDouble(), _row.toDouble()) ||
              _npcPositions.entries.any(
                (e) => e.key != npc.id && e.value == next,
              ) ||
              _map.isSolid(next.dx.toInt(), next.dy.toInt())) {
            continue;
          }
          _npcPositions[npc.id] = next;
          _routeSteps[npc.id] = step;
        }
      });
    });
  }

  void _enterArea(WorldArea area) {
    _map = area == WorldArea.town ? crescaTown : testingMap;
    _column = _map.spawn.dx.toInt();
    _row = _map.spawn.dy.toInt();
    _faceLeft = false;
    _routineTick = 0;
    _npcPositions
      ..clear()
      ..addEntries(_map.npcs.map((npc) => MapEntry(npc.id, npc.position)));
    _routeSteps.clear();
  }

  TownNpc? get _nearbyNpc {
    for (final npc in _map.npcs) {
      final position = _npcPositions[npc.id]!;
      if ((position.dx - _column).abs() + (position.dy - _row).abs() == 1) {
        return npc;
      }
    }
    return null;
  }

  MapProp? get _nearbySign {
    for (final prop in _map.props) {
      if (prop.isReadable &&
          (prop.position.dx - _column).abs() +
                  (prop.position.dy - _row).abs() ==
              1) {
        return prop;
      }
    }
    return null;
  }

  void _readSign(MapProp sign) {
    if ((sign.position.dx - _column).abs() + (sign.position.dy - _row).abs() !=
        1) {
      return;
    }
    _showDialogue(
      title: sign.label ?? 'Sign',
      role: 'Weathered sign',
      lines: sign.lines,
      isSign: true,
    );
  }

  void _interact() {
    if (_dialogueOpen || _window != null) return;
    final npc = _nearbyNpc;
    if (npc != null) {
      _showNpcDialogue(npc);
    } else {
      final sign = _nearbySign;
      if (sign != null) _readSign(sign);
    }
  }

  @override
  void dispose() {
    _routineTimer.cancel();
    _focus.dispose();
    super.dispose();
  }

  void _move(int dx, int dy) {
    if (_dialogueOpen || _window != null) return;
    _focus.requestFocus();
    final nextColumn = (_column + dx).clamp(0, _map.columns - 1);
    final nextRow = (_row + dy).clamp(0, _map.rows - 1);
    if (nextColumn == _column && nextRow == _row) return;
    for (final prop in _map.props) {
      if (prop.isReadable &&
          prop.position == Offset(nextColumn.toDouble(), nextRow.toDouble())) {
        _readSign(prop);
        return;
      }
    }
    if (_map.isSolid(nextColumn, nextRow)) return;
    for (final npc in _map.npcs) {
      if (_npcPositions[npc.id] ==
          Offset(nextColumn.toDouble(), nextRow.toDouble())) {
        _showNpcDialogue(npc);
        return;
      }
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
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.keyE ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _interact();
      return KeyEventResult.handled;
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

  Future<void> _showNpcDialogue(TownNpc npc) => _showDialogue(
    title: npc.name,
    role: npc.role,
    lines: npc.lines,
    portraitAsset: npc.asset,
    tint: npc.tint,
    action: npc.action,
  );

  Future<void> _showDialogue({
    required String title,
    required String role,
    required List<String> lines,
    String? portraitAsset,
    Color? tint,
    NpcAction action = NpcAction.talk,
    bool isSign = false,
  }) async {
    if (_dialogueOpen || _window != null) return;
    setState(() => _dialogueOpen = true);
    var page = 0;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialogue) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            alignment: Alignment.bottomCenter,
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.sizeOf(context).height * .8,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (portraitAsset != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 24, bottom: 8),
                        child: PixelAssetSprite(
                          key: const ValueKey('npc-portrait'),
                          assetPath: portraitAsset,
                          tint: tint,
                          tintBlendMode: BlendMode.modulate,
                          width: 80,
                          height: 80,
                          semanticLabel: '$title portrait',
                        ),
                      ),
                    SizedBox(
                      height: 320,
                      width: double.infinity,
                      child: PixelPanel.expanded(
                        role: PixelSurfaceRole.dialog,
                        padding: const EdgeInsets.all(20),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: _gold,
                                  fontSize: PixelUiMetrics.title,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                role,
                                style: const TextStyle(
                                  color: Color(0xFFA9A39A),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    for (final part
                                        in lines[page].split('~~').indexed)
                                      TextSpan(
                                        text: part.$2,
                                        style: part.$1.isOdd
                                            ? const TextStyle(
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              )
                                            : null,
                                      ),
                                  ],
                                ),
                                key: const ValueKey('dialogue-text'),
                                style: const TextStyle(
                                  color: Color(0xFFE5DAC5),
                                  fontSize: PixelUiMetrics.body,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (action != NpcAction.talk)
                                    PixelButton(
                                      key: ValueKey(
                                        action == NpcAction.battle
                                            ? 'start-battle'
                                            : 'travel-npc',
                                      ),
                                      label: switch (action) {
                                        NpcAction.battle => 'Yes',
                                        NpcAction.testing => 'Enter',
                                        _ => 'Return',
                                      },
                                      columns: 7,
                                      onPressed: () =>
                                          Navigator.pop(dialogContext, true),
                                    )
                                  else if (page < lines.length - 1)
                                    PixelButton(
                                      key: ValueKey(
                                        isSign
                                            ? 'next-sign-dialogue'
                                            : 'next-npc-dialogue',
                                      ),
                                      label: 'Next',
                                      columns: 6,
                                      onPressed: () =>
                                          updateDialogue(() => page++),
                                    ),
                                  const SizedBox(width: 8),
                                  PixelButton(
                                    key: ValueKey(
                                      isSign
                                          ? 'close-sign-dialogue'
                                          : 'close-npc-dialogue',
                                    ),
                                    label: isSign
                                        ? 'Close'
                                        : action == NpcAction.battle
                                        ? 'No'
                                        : 'Leave',
                                    columns: 6,
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      if (accepted == true && mounted) {
        switch (action) {
          case NpcAction.testing:
            setState(() => _enterArea(WorldArea.testing));
          case NpcAction.town:
            setState(() => _enterArea(WorldArea.town));
          case NpcAction.battle:
            await Navigator.of(
              context,
            ).push<void>(MaterialPageRoute(builder: (_) => const BattlePage()));
          case NpcAction.talk:
            break;
        }
      }
    } finally {
      if (mounted) {
        setState(() => _dialogueOpen = false);
        _focus.requestFocus();
      }
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
                  Positioned(
                    top: insets.top + 100,
                    left: insets.left + 16,
                    right: insets.right + 16,
                    child: IgnorePointer(
                      child: AreaArrivalTitle(
                        key: ValueKey('arrival-${_map.area.name}'),
                        name: _map.name,
                        subtitle: _map.subtitle,
                      ),
                    ),
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
                                Align(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    key: const ValueKey('interact-npc'),
                                    tooltip: _nearbySign != null
                                        ? 'Read sign (E / Space)'
                                        : 'Talk (E / Space)',
                                    onPressed:
                                        (_nearbyNpc == null &&
                                                _nearbySign == null) ||
                                            _dialogueOpen ||
                                            _window != null
                                        ? null
                                        : _interact,
                                    icon: const Icon(Icons.chat_bubble_outline),
                                    color: _gold,
                                    disabledColor: const Color(0xFF575157),
                                  ),
                                ),
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
                                party: showcaseParty,
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
              key: ValueKey(_map.area),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              left: playerLeft - _column * tile,
              top: playerTop - _row * tile,
              width: _map.columns * tile,
              height: _map.rows * tile,
              child: SizedBox(
                key: const ValueKey('world-grid'),
                child: WorldLayers(
                  entries: [
                    WorldEntry(
                      z: WorldZ.ground,
                      child: Positioned.fill(
                        child: PixelAtlasBuilder(
                          atlas: _groundAtlas,
                          builder: (context, image, error) =>
                              CustomPaint(painter: _GroundPainter(_map, image)),
                        ),
                      ),
                    ),
                    WorldEntry(
                      z: WorldZ.road,
                      child: Positioned.fill(
                        child: PixelAtlasBuilder(
                          atlas: _map.area == WorldArea.town
                              ? _townRoadAtlas
                              : SunderedKeepUi.theme.atlas,
                          builder: (context, image, error) => CustomPaint(
                            painter: _VillagePainter(_map, image),
                          ),
                        ),
                      ),
                    ),
                    WorldEntry(
                      z: WorldZ.road,
                      child: Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: TorchGlowPainter(_map, _routineTick),
                          ),
                        ),
                      ),
                    ),
                    for (final torch in _map.torches)
                      WorldEntry(
                        z: WorldZ.actor,
                        depth: torch.dy + 1,
                        child: Positioned(
                          key: ValueKey(
                            'torch-${torch.dx.toInt()}-${torch.dy.toInt()}',
                          ),
                          left: torch.dx * tile,
                          top: torch.dy * tile,
                          width: tile,
                          height: tile,
                          child: Image.asset(
                            'assets/overworld/torch.png',
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.contain,
                            semanticLabel: 'Lit torch',
                          ),
                        ),
                      ),
                    for (final building in _map.buildings)
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
                              child: _map.area == WorldArea.town
                                  ? BuildingTile(
                                      column: x,
                                      row: y,
                                      appearance: building.appearance,
                                    )
                                  : Image.asset(
                                      'assets/overworld/cottage/tile_${y}_$x.png',
                                      filterQuality: FilterQuality.none,
                                      fit: BoxFit.fill,
                                      excludeFromSemantics: true,
                                    ),
                            ),
                          ),
                    ...townSceneryEntries(_map, tile, onReadSign: _readSign),
                    for (final npc in _map.npcs)
                      WorldEntry(
                        z: WorldZ.actor,
                        depth: _npcPositions[npc.id]!.dy + 1,
                        child: AnimatedPositioned(
                          key: ValueKey('npc-position-${npc.id}'),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOut,
                          left: _npcPositions[npc.id]!.dx * tile,
                          top: _npcPositions[npc.id]!.dy * tile,
                          width: tile,
                          height: tile,
                          child: GestureDetector(
                            onTap: () {
                              final position = _npcPositions[npc.id]!;
                              if ((position.dx - _column).abs() +
                                      (position.dy - _row).abs() ==
                                  1) {
                                _showNpcDialogue(npc);
                              }
                            },
                            child: PixelAssetSprite(
                              key: ValueKey(
                                npc.id == 'trainer' ? 'npc' : 'npc-${npc.id}',
                              ),
                              assetPath: npc.asset,
                              tint: npc.tint,
                              tintBlendMode: BlendMode.modulate,
                              width: tile,
                              height: tile,
                              semanticLabel: '${npc.name}, ${npc.role}',
                            ),
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
                          container: true,
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
                            painter: _FloorPainter(_map, _column, _row),
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
  const _GroundPainter(this.map, this.image);
  final ExplorationMap map;
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
    final artTile = size.width / map.columns;
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (map.area == WorldArea.town) {
      paint.colorFilter = const ColorFilter.mode(
        Color(0xFFA2AA91),
        BlendMode.modulate,
      );
    }
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        canvas.drawImageRect(
          texture,
          const Rect.fromLTWH(0, 0, 16, 16),
          Rect.fromLTWH(x * artTile, y * artTile, artTile, artTile),
          paint,
        );
      }
    }
    final movementTile = artTile;
    paint.colorFilter = null;
    paint.color = Colors.black.withValues(alpha: .2);
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        if (map.area == WorldArea.testing && (x + y).isEven) {
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
    if (map.area == WorldArea.town) {
      // The refuge occupies a cavern, with impassable rock at its perimeter.
      for (var y = 0; y < map.rows; y++) {
        for (var x = 0; x < map.columns; x++) {
          if (!map.isCavernWall(x, y)) {
            continue;
          }
          final bounds = Rect.fromLTWH(
            x * artTile,
            y * artTile,
            artTile,
            artTile,
          );
          canvas.drawRect(bounds, Paint()..color = const Color(0xAA15141D));
          canvas.drawRect(
            Rect.fromLTWH(
              bounds.left + artTile * .1,
              bounds.top + artTile * .12,
              artTile * .76,
              artTile * .15,
            ),
            Paint()..color = const Color(0xFF55515C),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter oldDelegate) =>
      map != oldDelegate.map || image != oldDelegate.image;
}

class _VillagePainter extends CustomPainter {
  const _VillagePainter(this.map, this.image);
  final ExplorationMap map;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final atlas = image;
    if (atlas == null) return;
    final tile = size.width / map.columns;
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

    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        if (!map.isRoad(x, y)) continue;
        if (map.area == WorldArea.town) {
          stamp(0, 0, x * tile, y * tile);
        } else {
          stamp(4 + x % 2, 1, x * tile, y * tile);
        }
        if (map.area == WorldArea.testing && (x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(x * tile, y * tile, tile, tile),
            Paint()..color = Colors.black.withValues(alpha: .2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_VillagePainter oldDelegate) =>
      map != oldDelegate.map || image != oldDelegate.image;
}

class _FloorPainter extends CustomPainter {
  const _FloorPainter(this.map, this.playerColumn, this.playerRow);
  final ExplorationMap map;
  final int playerColumn;
  final int playerRow;

  @override
  void paint(Canvas canvas, Size size) {
    final tile = size.width / map.columns;
    final paint = Paint();
    final lights = [
      Offset(playerColumn.toDouble(), playerRow.toDouble()),
      ...map.torches,
    ];
    for (var y = 0; y < map.rows; y++) {
      for (var x = 0; x < map.columns; x++) {
        final darkness = worldDarknessAt(x, y, lights);
        if (darkness > 0) {
          paint.color = Colors.black.withValues(alpha: darkness);
          canvas.drawRect(Rect.fromLTWH(x * tile, y * tile, tile, tile), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FloorPainter oldDelegate) =>
      map != oldDelegate.map ||
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
