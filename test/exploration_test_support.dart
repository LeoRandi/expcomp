import 'package:expcomp/exploration/cresca_town.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/exploration/route_one.dart';
import 'package:expcomp/exploration/route_one_scenery.dart';
import 'package:expcomp/exploration/world_maps.dart';
import 'package:expcomp/exploration/indoor_scenery.dart';
import 'package:expcomp/player/player.dart';
import 'package:expcomp/inventory/item_catalog.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void setupExplorationMaps() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => loadAllWorldMaps(rootBundle));
}

Player playerWithTestItems() => Player()
  ..inventory.add(meat)
  ..inventory.add(moonlessNecklace, 2);

/// Decode real bundled art outside the widget test's fake clock, as the game
/// does while its covering animation runs in real time.
Future<void> warmExplorationAssets(WidgetTester tester) async {
  await tester.runAsync(() async {
    await loadAllWorldMaps(rootBundle);
    await rootBundle.loadString(routeOneTextAsset);
    await rootBundle.loadString(routeOneFloorAsset);
    await rootBundle.loadString(routeOneChestsAsset);
    await rootBundle.loadString(routeOneGatesAsset);
    final paths = {
      SunderedKeepUi.theme.atlas.assetPath,
      crescaPavingAsset,
      'assets/overworld/cottage/cottage.png',
      'assets/overworld/torch.png',
      ...routeOneArtAssets,
      ...indoorArtAssets,
      'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
          '16x16_Block_Texture_Set/blocks__granite.png.png',
      for (final map in [crescaTown, testingMap])
        for (final npc in map.npcs) npc.asset,
      for (var y = 0; y < 3; y++)
        for (var x = 0; x < 3; x++) 'assets/overworld/cottage/tile_${y}_$x.png',
    };
    await Future.wait(
      paths.map(
        (path) => PixelAtlasCache.load(bundle: rootBundle, assetPath: path),
      ),
    );
  });
}

Future<void> finishAreaTransition(WidgetTester tester) async {
  final overlay = find.byKey(const ValueKey('area-transition-overlay'));
  var seen = overlay.evaluate().isNotEmpty;
  var flushedAssets = false;
  for (var i = 0; i < 65; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (overlay.evaluate().isNotEmpty) {
      seen = true;
      if (!flushedAssets) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        flushedAssets = true;
      }
    } else if (seen) {
      return;
    }
  }
  fail('Area transition did not finish');
}

Offset explorationPlayerTile(WidgetTester tester) {
  final player = tester.widget<AnimatedPositioned>(
    find.byKey(const ValueKey('player-position')),
  );
  return Offset(
    (player.left! / player.width!).roundToDouble(),
    (player.top! / player.height!).roundToDouble(),
  );
}

Future<void> stepExploration(WidgetTester tester, Offset direction) async {
  await tester.sendKeyEvent(switch (direction) {
    Offset(dx: 1) => LogicalKeyboardKey.arrowRight,
    Offset(dx: -1) => LogicalKeyboardKey.arrowLeft,
    Offset(dy: 1) => LogicalKeyboardKey.arrowDown,
    _ => LogicalKeyboardKey.arrowUp,
  });
  await tester.pumpAndSettle();
}

Future<void> walkExplorationTo(
  WidgetTester tester,
  Offset target, {
  ExplorationMap? map,
}) async {
  map ??= crescaTown;
  final start = explorationPlayerTile(tester);
  final blockedActors = {
    for (final npc in map.npcs) ...[npc.position, ...npc.route],
  };
  const directions = [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)];
  final parents = <Offset, Offset?>{start: null};
  final queue = [start];
  for (var i = 0; i < queue.length; i++) {
    for (final direction in directions) {
      final next = queue[i] + direction;
      if (map.isSolid(next.dx.toInt(), next.dy.toInt()) ||
          blockedActors.contains(next) ||
          parents.containsKey(next) ||
          map.exits.any(
            (e) => e.trigger.contains(next + const Offset(.5, .5)),
          )) {
        continue;
      }
      parents[next] = queue[i];
      queue.add(next);
    }
  }
  expect(parents.containsKey(target), isTrue, reason: 'No route to $target');
  final route = <Offset>[];
  var current = target;
  while (current != start) {
    route.add(current);
    current = parents[current]!;
  }
  for (final next in route.reversed) {
    await stepExploration(tester, next - explorationPlayerTile(tester));
    expect(explorationPlayerTile(tester), next);
  }
}
