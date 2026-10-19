import 'dart:io';
import 'dart:ui' as ui;

import 'package:expcomp/exploration/cresca_town.dart';
import 'package:expcomp/exploration/world_lighting.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _steps = [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)];

Map<Offset, Offset?> _paths(Offset start, {Set<Offset> avoid = const {}}) {
  final paths = <Offset, Offset?>{start: null};
  final queue = [start];
  for (var i = 0; i < queue.length; i++) {
    for (final direction in _steps) {
      final next = queue[i] + direction;
      if (!crescaTown.isSolid(next.dx.toInt(), next.dy.toInt()) &&
          !avoid.contains(next) &&
          !paths.containsKey(next)) {
        paths[next] = queue[i];
        queue.add(next);
      }
    }
  }
  return paths;
}

Offset _playerTile(WidgetTester tester) {
  final player = tester.widget<AnimatedPositioned>(
    find.byKey(const ValueKey('player-position')),
  );
  return Offset(
    (player.left! / player.width!).roundToDouble(),
    (player.top! / player.height!).roundToDouble(),
  );
}

Future<void> _step(WidgetTester tester, Offset delta) async {
  await tester.sendKeyEvent(switch (delta) {
    Offset(dx: 1) => LogicalKeyboardKey.arrowRight,
    Offset(dx: -1) => LogicalKeyboardKey.arrowLeft,
    Offset(dy: 1) => LogicalKeyboardKey.arrowDown,
    _ => LogicalKeyboardKey.arrowUp,
  });
  await tester.pumpAndSettle();
}

Future<void> _walkTo(WidgetTester tester, Offset target) async {
  final start = _playerTile(tester);
  final paths = _paths(
    start,
    avoid: {
      for (final npc in crescaTown.npcs) ...[npc.position, ...npc.route],
    },
  );
  expect(
    paths.containsKey(target),
    isTrue,
    reason: 'No public route to $target',
  );
  final route = <Offset>[];
  var cursor = target;
  while (cursor != start) {
    route.add(cursor);
    cursor = paths[cursor]!;
  }
  for (final tile in route.reversed) {
    await _step(tester, tile - _playerTile(tester));
    expect(_playerTile(tester), tile);
  }
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUp(PixelAtlasCache.clear);

  test(
    'Outer roads reach dark boundary openings; farm is a closed enclosure',
    () {
      final map = crescaTown;
      final reachable = _paths(map.spawn);
      for (final edge in const [
        Offset(20, 0),
        Offset(21, 0),
        Offset(39, 19),
        Offset(39, 20),
        Offset(20, 39),
        Offset(21, 39),
      ]) {
        expect(map.isRoad(edge.dx.toInt(), edge.dy.toInt()), isTrue);
        expect(reachable.containsKey(edge), isTrue);
        expect(
          worldDarknessAt(edge.dx.toInt(), edge.dy.toInt(), map.torches),
          1,
        );
      }
      // Light falls away along all three outer roads.
      for (final p in const [Offset(21, 7), Offset(38, 19), Offset(21, 33)]) {
        expect(
          worldDarknessAt(p.dx.toInt(), p.dy.toInt(), map.torches),
          greaterThanOrEqualTo(.9),
        );
      }
      final signs = map.props.where((p) => p.kind == PropKind.sign).toList();
      expect(signs, hasLength(5));
      for (final sign in signs) {
        expect(sign.solid && sign.isReadable, isTrue);
        expect(
          map.isRoad(sign.position.dx.toInt(), sign.position.dy.toInt()),
          isFalse,
        );
        expect(
          _steps.any((d) => reachable.containsKey(sign.position + d)),
          isTrue,
        );
      }
      expect(crescaFarmBounds.size, const Size(4, 5));
      for (var y = 10; y <= 14; y++) {
        for (var x = 1; x <= 4; x++) {
          final tile = Offset(x.toDouble(), y.toDouble());
          if (x == 1 || x == 4 || y == 10 || y == 14) {
            expect(
              map.props.any((p) => p.isFence && p.solid && p.position == tile),
              isTrue,
            );
            expect(map.isSolid(x, y), isTrue);
          } else {
            expect(reachable.containsKey(tile), isFalse);
          }
        }
      }
      expect(
        map.props.any((p) => p.kind == PropKind.rubble && p.position.dx < 3),
        isTrue,
      );
      final guard = map.npcs.singleWhere((n) => n.id == 'tamsin');
      expect(guard.position.dy, inInclusiveRange(13, 15));
      expect(guard.lines.join(' '), contains('Lubia'));
      expect(map.npcs.any((n) => n.id == 'oren'), isFalse);
      expect(
        map.npcs
            .expand((n) => n.lines)
            .any((line) => line.toLowerCase().contains('oren')),
        isFalse,
      );
    },
  );

  for (final size in [const Size(800, 600), const Size(390, 844)]) {
    testWidgets(
      'Road and farm signs block movement, show pages and respond to touch and E at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        if (size.width == 800) {
          await tester.runAsync(() async {
            for (final path in [
              SunderedKeepUi.theme.atlas.assetPath,
              crescaPavingAsset,
              'assets/overworld/cottage/cottage.png',
              'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
                  '16x16_Block_Texture_Set/blocks__granite.png.png',
            ]) {
              await PixelAtlasCache.load(bundle: rootBundle, assetPath: path);
            }
          });
        }
        final boundaryKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(key: boundaryKey, child: const MyApp()),
        );
        await tester.pumpAndSettle();
        for (final sign in crescaTown.props.where((p) => p.isReadable)) {
          final approach = sign.position + const Offset(1, 0);
          await _walkTo(tester, approach);
          await _step(tester, const Offset(-1, 0));
          expect(_playerTile(tester), approach);
          expect(
            find.text(sign.lines.first.replaceAll('~~', '')),
            findsOneWidget,
          );
          expect(find.byKey(const ValueKey('npc-portrait')), findsNothing);
          if (sign.lines.first.contains('~~')) {
            final text = tester.widget<Text>(
              find.byKey(const ValueKey('dialogue-text')),
            );
            final spans = (text.textSpan! as TextSpan).children!;
            expect(
              spans.whereType<TextSpan>().any(
                (s) =>
                    s.text == 'TO LUBIA' &&
                    s.style?.decoration == TextDecoration.lineThrough,
              ),
              isTrue,
            );
          }
          await _step(tester, const Offset(0, 1));
          expect(_playerTile(tester), approach);
          for (final page in sign.lines.skip(1)) {
            await tester.tap(find.byKey(const ValueKey('next-sign-dialogue')));
            await tester.pumpAndSettle();
            expect(find.text(page), findsOneWidget);
          }
          expect(
            find.byKey(const ValueKey('next-sign-dialogue')),
            findsNothing,
          );
          await tester.tap(find.byKey(const ValueKey('close-sign-dialogue')));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
          await tester.pumpAndSettle();
          expect(
            find.text(sign.lines.first.replaceAll('~~', '')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const ValueKey('close-sign-dialogue')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(
              ValueKey('prop-sign-${sign.position.dx}-${sign.position.dy}'),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(sign.lines.first.replaceAll('~~', '')),
            findsOneWidget,
          );
          await tester.tap(find.byKey(const ValueKey('close-sign-dialogue')));
          await tester.pumpAndSettle();
          if (size.width == 800 && sign.label == 'The Resting Lantern') {
            await _capture(
              tester,
              boundaryKey,
              'build/resting-lantern-inn.png',
            );
          }
        }
        await _walkTo(tester, const Offset(5, 11));
        await _step(tester, const Offset(-1, 0));
        expect(_playerTile(tester), const Offset(5, 11));
        expect(find.byKey(const ValueKey('dialogue-text')), findsNothing);
        expect(tester.takeException(), isNull);
        if (size.width == 800) {
          await _capture(tester, boundaryKey, 'build/juntos-farm.png');
        }
      },
    );
  }
}
