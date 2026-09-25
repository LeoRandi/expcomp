import 'dart:io';
import 'dart:ui' as ui;

import 'package:expcomp/exploration/cresca_map.dart';
import 'package:expcomp/exploration/world_layers.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Layers sort by z, then baseline, preserving ties', (
    tester,
  ) async {
    Widget box(String id) => SizedBox(key: ValueKey(id));
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: WorldLayers(
          entries: [
            WorldEntry(z: WorldZ.roof, child: box('roof')),
            WorldEntry(z: WorldZ.actor, depth: 9, child: box('south')),
            WorldEntry(z: WorldZ.ground, child: box('ground')),
            WorldEntry(z: WorldZ.actor, depth: 2, child: box('north')),
            WorldEntry(z: WorldZ.actor, depth: 9, child: box('tie')),
          ],
        ),
      ),
    );
    final stack = tester.widget<Stack>(find.byType(Stack));
    expect(stack.children.map((w) => (w.key! as ValueKey).value), [
      'ground',
      'north',
      'south',
      'tie',
      'roof',
    ]);
  });

  testWidgets('Both roof projections are walkable and paint over the player', (
    tester,
  ) async {
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundaryKey, child: const MyApp()),
    );
    await tester.pumpAndSettle();
    var column = 10;
    var row = 10;
    Future<void> step(LogicalKeyboardKey key, int dx, int dy) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
      column += dx;
      row += dy;
      expect(
        find.bySemanticsLabel('Player at column ${column + 1}, row ${row + 1}'),
        findsOneWidget,
      );
    }

    final semantics = tester.ensureSemantics();

    // Approach west cottage from the side, then cross its roof projection.
    for (var i = 0; i < 6; i++) {
      await step(LogicalKeyboardKey.arrowLeft, -1, 0);
    }
    for (var i = 0; i < 4; i++) {
      await step(LogicalKeyboardKey.arrowUp, 0, -1);
    }
    for (var i = 0; i < 2; i++) {
      await step(LogicalKeyboardKey.arrowRight, 1, 0);
      expect(isHouseTile(column, row), isFalse);
    }
    final stack = tester.widget<Stack>(
      find
          .descendant(
            of: find.byType(WorldLayers),
            matching: find.byType(Stack),
          )
          .first,
    );
    final playerIndex = stack.children.indexWhere(
      (w) => w.key == const ValueKey('player-position'),
    );
    expect(
      stack.children.indexWhere(
        (w) => w.key == const ValueKey('house-west-1-0'),
      ),
      greaterThan(playerIndex),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('house-west-1-0'))),
      tester.getSize(find.byKey(const ValueKey('player'))),
    );
    expect(crescaBuildings.first.bounds.size, const Size(3, 3));
    // Save a review image from the actual Flutter renderer.
    await tester.runAsync(() async {
      final context = boundaryKey.currentContext!;
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(widget.image, context);
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();
    final boundary =
        boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final screenshot = await boundary.toImage();
      final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      final output = File('build/cresca-behind-house.png');
      await output.writeAsBytes(bytes!.buffer.asUint8List());
      screenshot.dispose();
    });
    // East cottage, also approached from its western side.
    for (var i = 0; i < 5; i++) {
      await step(LogicalKeyboardKey.arrowRight, 1, 0);
    }
    for (var i = 0; i < 3; i++) {
      await step(LogicalKeyboardKey.arrowUp, 0, -1);
    }
    for (var i = 0; i < 2; i++) {
      await step(LogicalKeyboardKey.arrowRight, 1, 0);
      expect(isHouseTile(column, row), isFalse);
    }
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });

  testWidgets('Cottage PNG tiles preserve source pixels and transparency', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final sourceData = await rootBundle.load(
        'assets/overworld/cottage/cottage.png',
      );
      final sourceCodec = await ui.instantiateImageCodec(
        sourceData.buffer.asUint8List(),
      );
      final source = (await sourceCodec.getNextFrame()).image;
      final sourcePixels = (await source.toByteData())!;
      var transparentPixels = 0;
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final data = await rootBundle.load(
            'assets/overworld/cottage/tile_${y}_$x.png',
          );
          final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(),
          );
          final image = (await codec.getNextFrame()).image;
          expect(image.width, 16);
          expect(image.height, 16);
          final pixels = (await image.toByteData())!;
          for (var py = 0; py < 16; py++) {
            for (var px = 0; px < 16; px++) {
              final local = (py * 16 + px) * 4;
              final original = ((y * 16 + py) * 48 + x * 16 + px) * 4;
              expect(pixels.getUint32(local), sourcePixels.getUint32(original));
              if (pixels.getUint8(local + 3) == 0) transparentPixels++;
            }
          }
          image.dispose();
          codec.dispose();
        }
      }
      expect(transparentPixels, greaterThan(0));
      source.dispose();
      sourceCodec.dispose();
    });
  });
}
