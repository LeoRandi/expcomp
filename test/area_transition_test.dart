import 'dart:ui' as ui;

import 'package:expcomp/exploration/area_transition.dart';
import 'package:expcomp/exploration/cresca_town.dart';
import 'package:expcomp/exploration/exploration_page.dart';
import 'package:expcomp/exploration/world_map.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/inventory/inventory_menu.dart';
import 'package:expcomp/main.dart';
import 'package:expcomp/party/party_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'exploration_test_support.dart';

AreaTransitionPainter _mask(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.byKey(const ValueKey('area-transition-mask')),
            )
            .painter!
        as AreaTransitionPainter;

AreaTransitionOverlay _overlay(WidgetTester tester) =>
    tester.widget<AreaTransitionOverlay>(
      find.byKey(const ValueKey('area-transition-overlay')),
    );

Future<void> _blackoutBoundary(WidgetTester tester) async {
  // Allow the last closing frame to paint and the destination to paint behind it.
  for (var i = 0; i < 8 && !_overlay(tester).revealing; i++) {
    await tester.pump(const Duration(milliseconds: 1));
  }
  expect(_overlay(tester).revealing, isTrue);
  expect(_mask(tester).progress, 1);
}

Future<void> _unlock(WidgetTester tester) async {
  for (
    var i = 0;
    i < 8 && find.byType(AreaTransitionOverlay).evaluate().isNotEmpty;
    i++
  ) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  expect(find.byType(AreaTransitionOverlay), findsNothing);
}

Future<void> _tryBlockedInput(WidgetTester tester, Offset expected) async {
  for (final key in [
    'open-party',
    'open-inventory',
    'move-up',
    'interact-npc',
  ]) {
    await tester.tapAt(tester.getCenter(find.byKey(ValueKey(key))));
  }
  await tester.tapAt(tester.getCenter(find.byIcon(Icons.close)));
  for (final key in [
    LogicalKeyboardKey.arrowDown,
    LogicalKeyboardKey.keyE,
    LogicalKeyboardKey.tab,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.escape,
  ]) {
    await tester.sendKeyEvent(key);
  }
  await tester.pump();
  expect(explorationPlayerTile(tester), expected);
  expect(find.byType(PartyMenu), findsNothing);
  expect(find.byType(InventoryMenu), findsNothing);
  expect(find.byKey(const ValueKey('close-player-info')), findsNothing);
  expect(find.byType(Dialog), findsNothing);
}

Map<String, Offset> _residents(WidgetTester tester) => {
  for (final npc in crescaTown.npcs)
    npc.id: (() {
      final p = tester.widget<AnimatedPositioned>(
        find.byKey(ValueKey('npc-position-${npc.id}')),
      );
      return Offset(p.left!, p.top!);
    })(),
};

void main() {
  setupExplorationMaps();
  setUp(PixelAtlasCache.clear);

  test('Exact cover and aperture milestones use .5/.2/.5 seconds', () {
    for (final sample in [
      (0, 0.0),
      (250, .275),
      (500, .55),
      (600, .5),
      (700, .45),
      (950, .725),
      (1200, 1.0),
    ]) {
      expect(curtainCoverage(sample.$1 / 1200), closeTo(sample.$2, .00001));
    }
    double radius(double p) => transitionApertureRadius(
      size: const Size(800, 600),
      center: const Offset(400, 300),
      tileExtent: 32,
      progress: p,
    );
    expect(radius(0), greaterThan(500));
    expect(radius(500 / 1200), closeTo(80, .00001));
    expect(radius(700 / 1200), closeTo(112, .00001));
    expect(radius(1), 0);
    expect(radius(1 - 500 / 1200), closeTo(112, .00001));
    expect(radius(1 - 700 / 1200), closeTo(80, .00001));
    expect(areaTransitionDuration, const Duration(milliseconds: 1200));
  });

  testWidgets(
    'All five masks paint the correct sides and completely cover the UI',
    (tester) async {
      await tester.runAsync(() async {
        Future<List<int>> samples(
          AreaTransitionStyle style,
          double progress,
        ) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          const size = Size(100, 80);
          canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
          AreaTransitionPainter(
            style: style,
            progress: progress,
            playerCenter: const Offset(50, 40),
            tileExtent: 8,
          ).paint(canvas, size);
          final picture = recorder.endRecording();
          final image = await picture.toImage(100, 80);
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final result = [
            for (final p in const [
              Offset(10, 40),
              Offset(90, 40),
              Offset(50, 10),
              Offset(50, 70),
              Offset(50, 40),
            ])
              data.getUint8((p.dy.toInt() * 100 + p.dx.toInt()) * 4),
          ];
          image.dispose();
          picture.dispose();
          return result;
        }

        for (final style in AreaTransitionStyle.values) {
          expect(await samples(style, 0), everyElement(255));
          expect(await samples(style, 1), everyElement(0));
        }
        expect(await samples(AreaTransitionStyle.north, 500 / 1200), [
          0,
          0,
          255,
          0,
          0,
        ]);
        expect(await samples(AreaTransitionStyle.south, 500 / 1200), [
          0,
          0,
          0,
          255,
          0,
        ]);
        expect(await samples(AreaTransitionStyle.east, 500 / 1200), [
          0,
          255,
          0,
          0,
          0,
        ]);
        expect(await samples(AreaTransitionStyle.west, 500 / 1200), [
          255,
          0,
          0,
          0,
          0,
        ]);
        expect(await samples(AreaTransitionStyle.circle, 500 / 1200), [
          0,
          0,
          0,
          0,
          255,
        ]);
        // Going east reveals from the left, by reversing the west mask.
        expect(
          await samples(
            opposingTransition(AreaTransitionStyle.east),
            700 / 1200,
          ),
          [255, 0, 255, 255, 255],
        );
      });
    },
  );

  for (final size in [const Size(800, 600), const Size(390, 844)]) {
    testWidgets(
      'Town wrap crossings lock the full UI, swap under black and reveal at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await warmExplorationAssets(tester);
        final screenKey = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(key: screenKey, child: const MyApp()),
        );
        await tester.pumpAndSettle();
        for (final exit in crescaTown.exits.where(
          (exit) => exit.destination == WorldArea.town,
        )) {
          final (start, key, inward) = switch (exit.style) {
            AreaTransitionStyle.north => (
              const Offset(29, 1),
              LogicalKeyboardKey.arrowUp,
              const Offset(0, -1),
            ),
            AreaTransitionStyle.east => (
              const Offset(53, 26),
              LogicalKeyboardKey.arrowRight,
              const Offset(1, 0),
            ),
            AreaTransitionStyle.south => (
              const Offset(29, 53),
              LogicalKeyboardKey.arrowDown,
              const Offset(0, 1),
            ),
            AreaTransitionStyle.west => (
              const Offset(1, 26),
              LogicalKeyboardKey.arrowLeft,
              const Offset(-1, 0),
            ),
            _ => throw StateError('Cardinal test only'),
          };
          await walkExplorationTo(tester, start);
          final residents = _residents(tester);
          await tester.sendKeyEvent(key);
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          expect(_overlay(tester).revealing, isFalse);
          expect(_mask(tester).style, exit.style);
          expect(tester.getSize(find.byType(AreaTransitionOverlay)), size);
          expect(find.byKey(const ValueKey('area-name')), findsNothing);
          await _tryBlockedInput(tester, start);
          await tester.pump(const Duration(milliseconds: 500));
          expect(curtainCoverage(_mask(tester).progress), closeTo(.55, .00001));
          await tester.pump(const Duration(milliseconds: 200));
          expect(curtainCoverage(_mask(tester).progress), closeTo(.45, .00001));
          await tester.pump(const Duration(milliseconds: 499));
          expect(explorationPlayerTile(tester), start);
          await tester.pump(const Duration(milliseconds: 1));
          await _blackoutBoundary(tester);
          // Verify the real composited screen, including the header and D-pad,
          // contains no non-black pixels at the scene swap.
          await tester.runAsync(() async {
            final boundary =
                screenKey.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            final pixels = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            var nonBlack = 0;
            for (var i = 0; i < pixels.lengthInBytes; i += 4) {
              if (pixels.getUint8(i) != 0 ||
                  pixels.getUint8(i + 1) != 0 ||
                  pixels.getUint8(i + 2) != 0) {
                nonBlack++;
              }
            }
            expect(nonBlack, 0);
            image.dispose();
          });
          expect(explorationPlayerTile(tester), exit.arrival);
          expect(_mask(tester).style, opposingTransition(exit.style));
          expect(_residents(tester), residents);
          await _tryBlockedInput(tester, exit.arrival);
          await tester.pump(const Duration(milliseconds: 500));
          expect(curtainCoverage(_mask(tester).progress), closeTo(.45, .00001));
          await tester.pump(const Duration(milliseconds: 200));
          expect(curtainCoverage(_mask(tester).progress), closeTo(.55, .00001));
          await tester.pump(const Duration(milliseconds: 500));
          await _unlock(tester);
          expect(explorationPlayerTile(tester), exit.arrival);
          expect(find.byKey(const ValueKey('area-name')), findsOneWidget);
          // The arrival lies inside the edge, and continuing inward cannot loop.
          await stepExploration(tester, inward);
          expect(explorationPlayerTile(tester), exit.arrival + inward);
          expect(find.byType(AreaTransitionOverlay), findsNothing);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Both NPC teleports close and reopen around the player, preserving inventory',
    (tester) async {
      await warmExplorationAssets(tester);
      final player = playerWithTestItems();
      final inventory = player.inventory;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: ExplorationPage(player: player),
        ),
      );
      await tester.pumpAndSettle();
      for (final area in [WorldArea.testing, WorldArea.town]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('travel-npc')));
        for (
          var i = 0;
          i < 8 && find.byType(AreaTransitionOverlay).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        expect(_mask(tester).style, AreaTransitionStyle.circle);
        expect(find.byType(Dialog), findsNothing);
        final painter = _mask(tester);
        final center = tester.getCenter(find.byKey(const ValueKey('player')));
        expect((painter.playerCenter - center).distance, lessThan(.001));
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          transitionApertureRadius(
            size: const Size(800, 600),
            center: center,
            tileExtent: painter.tileExtent,
            progress: _mask(tester).progress,
          ),
          closeTo(painter.tileExtent * 2.5, .001),
        );
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          transitionApertureRadius(
            size: const Size(800, 600),
            center: center,
            tileExtent: painter.tileExtent,
            progress: _mask(tester).progress,
          ),
          closeTo(painter.tileExtent * 3.5, .001),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await _blackoutBoundary(tester);
        expect(find.byKey(ValueKey(area)), findsOneWidget);
        expect(_mask(tester).style, AreaTransitionStyle.circle);
        await _tryBlockedInput(
          tester,
          area == WorldArea.town ? crescaTown.spawn : testingMap.spawn,
        );
        await tester.pump(const Duration(milliseconds: 1200));
        await _unlock(tester);
        await tester.pumpAndSettle();
      }
      expect(player.inventory, same(inventory));
      await tester.tap(find.byKey(const ValueKey('open-inventory')));
      await tester.pumpAndSettle();
      expect(find.text('Meat'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  for (final duringReveal in [false, true]) {
    testWidgets(
      'Disposing exploration during ${duringReveal ? 'reveal' : 'cover'} cancels travel cleanly',
      (tester) async {
        await warmExplorationAssets(tester);
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('travel-npc')));
        for (
          var i = 0;
          i < 8 && find.byType(AreaTransitionOverlay).evaluate().isEmpty;
          i++
        ) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        if (duringReveal) {
          await tester.pump(const Duration(milliseconds: 1200));
          await _blackoutBoundary(tester);
        }
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
