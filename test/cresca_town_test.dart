import 'exploration_test_support.dart';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:expcomp/exploration/cresca_town.dart';
import 'package:expcomp/exploration/exploration_page.dart';
import 'package:expcomp/exploration/world_lighting.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/main.dart';
import 'package:expcomp/player/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PixelAtlasCache.clear);
  test(
    'Centered town in a 55 by 55 cavern with clear streets and roadside torches',
    () {
      final map = crescaTown;
      expect(
        Size(map.columns.toDouble(), map.rows.toDouble()),
        const Size(55, 55),
      );
      expect(map.columns * map.rows, 3025);
      expect(map.buildings.length, greaterThanOrEqualTo(7));
      final settlement = map.buildings
          .map((b) => b.bounds)
          .reduce((a, b) => a.expandToInclude(b));
      expect(
        (settlement.center.dx - map.columns / 2).abs(),
        lessThanOrEqualTo(.5),
      );
      expect(
        (settlement.center.dy - map.rows / 2).abs(),
        lessThanOrEqualTo(.5),
      );
      final visited = <Offset>{map.spawn};
      final queue = [map.spawn];
      for (var i = 0; i < queue.length; i++) {
        for (final d in const [
          Offset(1, 0),
          Offset(-1, 0),
          Offset(0, 1),
          Offset(0, -1),
        ]) {
          final next = queue[i] + d;
          if (!map.isSolid(next.dx.toInt(), next.dy.toInt()) &&
              visited.add(next)) {
            queue.add(next);
          }
        }
      }
      for (final house in map.buildings) {
        final doorstep = Offset(
          house.footprint.center.dx.floorToDouble(),
          house.footprint.bottom,
        );
        expect(visited, contains(doorstep), reason: house.id);
        expect(map.isRoad(doorstep.dx.toInt(), doorstep.dy.toInt()), isTrue);
        expect(
          map.isSolid(house.bounds.left.toInt(), house.bounds.top.toInt()),
          isFalse,
        );
        expect(
          map.isSolid(
            house.footprint.left.toInt(),
            house.footprint.top.toInt(),
          ),
          isTrue,
        );
      }
      for (final npc in map.npcs) {
        expect(visited, contains(npc.position), reason: npc.name);
        for (var i = 0; i < npc.route.length; i++) {
          final next = npc.route[(i + 1) % npc.route.length];
          final current = npc.route[i];
          expect(
            (next.dx - current.dx).abs() + (next.dy - current.dy).abs(),
            1,
          );
          expect(map.isSolid(current.dx.toInt(), current.dy.toInt()), isFalse);
        }
      }
      for (var y = 0; y < map.rows; y++) {
        for (var x = 0; x < map.columns; x++) {
          if (map.isRoad(x, y) && x >= 9 && x <= 44 && y >= 21 && y <= 33) {
            expect(
              worldDarknessAt(x, y, map.torches),
              0,
              reason: 'Unlit street at $x,$y',
            );
          }
        }
      }
      for (final torch in map.torches) {
        final x = torch.dx.toInt();
        final y = torch.dy.toInt();
        expect(map.isSolid(x, y), isFalse);
        expect(
          map.isRoad(x, y),
          isFalse,
          reason: 'Torch on the paving at $torch',
        );
        expect(
          map.isRoad(x - 1, y) ||
              map.isRoad(x + 1, y) ||
              map.isRoad(x, y - 1) ||
              map.isRoad(x, y + 1),
          isTrue,
        );
        expect(
          map.buildings.any(
            (b) => b.bounds.contains(torch + const Offset(.5, .5)),
          ),
          isFalse,
        );
        expect(map.props.any((p) => p.position == torch), isFalse);
      }
      expect(worldDarknessAt(0, 0, map.torches), 1);
      expect(worldDarknessAt(54, 54, map.torches), 1);
      expect(worldDarknessAt(29, 10, map.torches), 1);
      expect(worldDarknessAt(29, 45, map.torches), 1);
      final home = map.buildings.singleWhere((b) => b.id == 'home');
      expect(
        map.spawn,
        Offset(home.footprint.center.dx.floorToDouble(), home.footprint.bottom),
      );
      expect((map.npcs.first.position - map.spawn).distance, 1);
    },
  );

  testWidgets(
    'Area titles fade in and out over one second on a rounded translucent panel',
    (tester) async {
      await warmExplorationAssets(tester);
      await tester.pumpWidget(const MyApp());
      final title = find.byKey(const ValueKey('area-name'));
      final fade = find.byKey(const ValueKey('area-title-fade'));
      double opacity() => tester.widget<FadeTransition>(fade).opacity.value;
      final panel = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('area-title-panel')),
      );
      final decoration = panel.decoration as BoxDecoration;
      expect(decoration.color, Colors.black.withValues(alpha: .3));
      expect(decoration.borderRadius, BorderRadius.circular(12));
      expect(opacity(), 0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(opacity(), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), 1);
      await tester.pump(const Duration(milliseconds: 400));
      expect(opacity(), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(const Duration(milliseconds: 116));
      expect(title, findsNothing);
      for (final area in ['Testing grounds', 'Cresca']) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('travel-npc')));
        await finishAreaTransition(tester);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text(area), findsOneWidget);
        await tester.pump(const Duration(seconds: 1));
        expect(title, findsNothing);
        expect(find.text(area), findsNothing);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Stranger round trip preserves inventory and the battle interaction',
    (tester) async {
      await warmExplorationAssets(tester);
      final player = Player.demo();
      final inventory = player.inventory;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: ExplorationPage(player: player),
        ),
      );
      await tester.pumpAndSettle();
      final world = find.byKey(const ValueKey('world-grid'));
      final start = tester.getTopLeft(world);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('The Veiled Stranger'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world), start);
      await tester.tap(find.byKey(const ValueKey('travel-npc')));
      await finishAreaTransition(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(WorldArea.testing)), findsOneWidget);
      expect(find.byKey(const ValueKey('npc')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('npc-waykeeper')));
      await tester.pumpAndSettle();
      expect(find.text('The Waykeeper'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(find.text('Ready to meet your end?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('travel-npc')));
      await finishAreaTransition(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey(WorldArea.town)), findsOneWidget);
      expect(tester.getTopLeft(world), start);
      expect(player.inventory, same(inventory));
      await tester.tap(find.byKey(const ValueKey('open-inventory')));
      await tester.pumpAndSettle();
      expect(find.text('Meat'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Residents walk, pause during conversations and menus, and share lore',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      Offset ivo() {
        final p = tester.widget<AnimatedPositioned>(
          find.byKey(const ValueKey('npc-position-ivo')),
        );
        return Offset(p.left!, p.top!);
      }

      final start = ivo();
      await tester.pump(const Duration(milliseconds: 1600));
      expect(ivo(), isNot(start));
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.pumpAndSettle();
      final paused = ivo();
      await tester.pump(const Duration(seconds: 5));
      expect(ivo(), paused);
      await tester.tap(find.byKey(const ValueKey('close-npc-dialogue')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-party')));
      await tester.pumpAndSettle();
      final inMenu = ivo();
      await tester.pump(const Duration(seconds: 5));
      expect(ivo(), inMenu);
      await tester.tap(find.byKey(const ValueKey('close-party')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      for (var i = 0; i < 6; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
      }
      expect(find.text('Mara'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-npc-dialogue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Nessa trades herbs'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('next-npc-dialogue')));
      await tester.pumpAndSettle();
      expect(find.textContaining('towns south and east'), findsOneWidget);
      expect(find.byKey(const ValueKey('next-npc-dialogue')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Render starting town for visual review', (tester) async {
    await tester.runAsync(() async {
      // Optional local font makes Windows review captures readable. Tests also
      // work on other hosts using Flutter's standard test font.
      final fontFile = File('C:/Windows/Fonts/consola.ttf');
      if (await fontFile.exists()) {
        final font = FontLoader(
          'monospace',
        )..addFont(fontFile.readAsBytes().then((b) => ByteData.sublistView(b)));
        await font.load();
      }
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: const MyApp()));
    await tester.pumpAndSettle();
    final player = find.byKey(const ValueKey('player'));
    final world = find.byKey(const ValueKey('world-grid'));
    final viewport = find.byKey(const ValueKey('world-viewport'));
    final tile = tester.getSize(player).width;
    expect(tester.getSize(world), Size(tile * 55, tile * 55));
    // Check both collision at home and camera/player alignment during a step.
    final start = tester.getTopLeft(world);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(world), start);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 75));
    expect(
      (tester.getCenter(player) - tester.getCenter(viewport)).distance,
      lessThan(.001),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final element in find.byType(PixelAtlasBuilder).evaluate()) {
        final atlas = (element.widget as PixelAtlasBuilder).atlas;
        await PixelAtlasCache.load(
          bundle: DefaultAssetBundle.of(element),
          assetPath: atlas.assetPath,
        );
      }
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(widget.image, key.currentContext!);
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/cresca-start.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(
      (tester.getCenter(player) - tester.getCenter(viewport)).distance,
      lessThan(.001),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        'build/cresca-start-portrait.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.tap(find.byKey(const ValueKey('interact-npc')));
    await tester.pumpAndSettle();
    expect(find.text('The Veiled Stranger'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('travel-npc')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
