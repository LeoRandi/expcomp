import 'dart:ui' as ui;

import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PixelAtlasCache.clear);

  group('PixelGrid', () {
    test('snaps logical measurements to the tile rhythm', () {
      expect(PixelGrid.snapUp(420), 432);
      expect(PixelGrid.snapDown(420), 416);
      expect(PixelGrid.snapNearest(420), 416);
      expect(PixelGrid.isAligned(128), isTrue);
      expect(PixelGrid.isAligned(76), isFalse);
    });

    test('turns tile counts into logical dimensions', () {
      const size = PixelGridSize(columns: 32, rows: 16);

      expect(size.tileCount, 512);
      expect(size.logicalSize(), const Size(512, 256));
    });
  });

  group('PixelAtlasRegion', () {
    test('resolves tile coordinates into a source rectangle', () {
      const region = PixelAtlasRegion(
        column: 3,
        row: 4,
        widthInTiles: 2,
        heightInTiles: 3,
      );

      expect(region.sourceRect(16), const Rect.fromLTWH(48, 64, 32, 48));
    });
  });

  group('PixelPanelRecipe', () {
    const topLeft = PixelAtlasRegion(column: 0, row: 0);
    const top = PixelAtlasRegion(column: 1, row: 0);
    const topRight = PixelAtlasRegion(column: 2, row: 0);
    const left = PixelAtlasRegion(column: 0, row: 1);
    const fillA = PixelAtlasRegion(column: 1, row: 1);
    const fillB = PixelAtlasRegion(column: 2, row: 1);
    const right = PixelAtlasRegion(column: 3, row: 1);
    const bottomLeft = PixelAtlasRegion(column: 0, row: 2);
    const bottom = PixelAtlasRegion(column: 1, row: 2);
    const bottomRight = PixelAtlasRegion(column: 2, row: 2);
    final recipe = PixelPanelRecipe(
      topLeft: topLeft,
      top: PixelTileVariants.single(top),
      topRight: topRight,
      left: PixelTileVariants.single(left),
      fill: PixelTileVariants([fillA, fillB]),
      right: PixelTileVariants.single(right),
      bottomLeft: bottomLeft,
      bottom: PixelTileVariants.single(bottom),
      bottomRight: bottomRight,
    );

    test('selects the correct corners and edges', () {
      PixelAtlasRegion at(int column, int row) => recipe.regionForCell(
        column: column,
        row: row,
        columns: 5,
        rows: 4,
        seed: 7,
      );

      expect(at(0, 0), topLeft);
      expect(at(2, 0), top);
      expect(at(4, 0), topRight);
      expect(at(0, 2), left);
      expect(at(4, 2), right);
      expect(at(0, 3), bottomLeft);
      expect(at(2, 3), bottom);
      expect(at(4, 3), bottomRight);
    });

    test('selects fill variation deterministically', () {
      final first = recipe.regionForCell(
        column: 2,
        row: 2,
        columns: 6,
        rows: 6,
        seed: 91,
      );
      final second = recipe.regionForCell(
        column: 2,
        row: 2,
        columns: 6,
        rows: 6,
        seed: 91,
      );

      expect(first, second);
      expect([fillA, fillB], contains(first));
    });

    test('keeps orientation metadata with each frame cell', () {
      final transformedRecipe = PixelPanelRecipe(
        topLeft: topLeft,
        top: PixelTileVariants.single(top),
        topRight: topRight,
        left: PixelTileVariants.single(top),
        fill: PixelTileVariants.single(fillA),
        right: PixelTileVariants.single(top),
        bottomLeft: topLeft,
        bottom: PixelTileVariants.single(top),
        bottomRight: topRight,
        leftTransform: const PixelTileTransform(quarterTurns: 3),
        rightTransform: const PixelTileTransform(quarterTurns: 1),
        bottomTransform: const PixelTileTransform(flipVertically: true),
      );

      PixelPanelCell at(int column, int row) => transformedRecipe.cellFor(
        column: column,
        row: row,
        columns: 5,
        rows: 4,
        seed: 7,
      );

      expect(at(0, 2).transform.quarterTurns, 3);
      expect(at(4, 2).transform.quarterTurns, 1);
      expect(at(2, 3).transform.flipVertically, isTrue);
      expect(at(2, 2).transform, PixelTileTransform.identity);
    });

    test('edge sequences keep caps at the ends and repeat their middle', () {
      const start = PixelAtlasRegion(column: 5, row: 7);
      const middle = PixelAtlasRegion(column: 6, row: 7);
      const end = PixelAtlasRegion(column: 7, row: 7);
      final sequence = PixelTileVariants.sequence([
        start,
        middle,
        end,
      ], sequenceAxis: PixelTileSequenceAxis.horizontal);

      PixelAtlasRegion at(int column) =>
          sequence.select(column: column, row: 0, seed: 0, edgeLength: 6);

      expect(
        [for (var column = 1; column <= 6; column += 1) at(column)],
        [start, middle, middle, middle, middle, end],
      );
    });

    test('Sundered Keep uses V-shaped beam joints and a distinct center', () {
      final topLeft = SunderedKeepUi.woodPanel.cellFor(
        column: 0,
        row: 0,
        columns: 8,
        rows: 6,
        seed: 0,
      );
      final top = SunderedKeepUi.woodPanel.cellFor(
        column: 3,
        row: 0,
        columns: 8,
        rows: 6,
        seed: 0,
      );
      final topRight = SunderedKeepUi.woodPanel.cellFor(
        column: 7,
        row: 0,
        columns: 8,
        rows: 6,
        seed: 0,
      );
      final left = SunderedKeepUi.woodPanel.cellFor(
        column: 0,
        row: 2,
        columns: 8,
        rows: 6,
        seed: 0,
      );
      final right = SunderedKeepUi.woodPanel.cellFor(
        column: 7,
        row: 2,
        columns: 8,
        rows: 6,
        seed: 0,
      );

      expect(topLeft.region, const PixelAtlasRegion(column: 6, row: 8));
      expect(topLeft.transform.flipVertically, isTrue);
      expect(top.region, const PixelAtlasRegion(column: 6, row: 7));
      expect(topRight.region, const PixelAtlasRegion(column: 7, row: 8));
      expect(topRight.transform.flipVertically, isTrue);
      expect(left.region, const PixelAtlasRegion(column: 7, row: 5));
      expect(left.transform, PixelTileTransform.identity);
      expect(right.region, const PixelAtlasRegion(column: 7, row: 5));
      expect(right.transform.flipHorizontally, isTrue);
      expect(SunderedKeepUi.woodPanel.solidFillColor, isNotNull);
      expect(
        SunderedKeepUi.woodPanel.solidFillColor,
        isNot(SunderedKeepUi.stoneInset.solidFillColor),
      );
    });

    test('Raida uses capped palisade beams and transformed stake joints', () {
      PixelPanelCell at(int column, int row) => RaidaUi.panel.cellFor(
        column: column,
        row: row,
        columns: 6,
        rows: 6,
        seed: 0,
      );

      expect(
        RaidaUi.atlas.assetPath,
        'assets/pixel_ui/showcase/raida_palisade_atlas.png',
      );
      expect(at(0, 0).region, const PixelAtlasRegion(column: 0, row: 0));
      expect(at(1, 0).region, const PixelAtlasRegion(column: 1, row: 0));
      expect(at(2, 0).region, const PixelAtlasRegion(column: 2, row: 0));
      expect(at(4, 0).region, const PixelAtlasRegion(column: 0, row: 1));
      expect(at(0, 2).transform.quarterTurns, 1);
      expect(at(2, 5).transform.flipVertically, isTrue);
      expect(at(5, 5).transform.flipHorizontally, isTrue);
      expect(at(5, 5).transform.flipVertically, isTrue);
      expect(RaidaUi.panel.solidFillColor, const Color(0xFF19150D));
    });

    test('showcase skins expose distinct atlases and recipes', () {
      expect(PixelUiShowcaseSkins.skins, hasLength(5));
      expect(
        PixelUiShowcaseSkins.sciFiRecipe.topLeft,
        const PixelAtlasRegion(column: 0, row: 0),
      );
      expect(
        PixelUiShowcaseSkins.sciFiRecipe.fill.regions.single,
        const PixelAtlasRegion(column: 1, row: 1),
      );
      expect(
        PixelUiShowcaseSkins.skins.map((skin) => skin.atlas.assetPath).toSet(),
        hasLength(5),
      );
    });

    test('Falobris uses the coastal island frame', () {
      expect(
        FalobrisUi.panel.topLeft,
        const PixelAtlasRegion(column: 3, row: 0),
      );
      expect(
        FalobrisUi.panel.fill.regions.single,
        const PixelAtlasRegion(column: 4, row: 1),
      );
      expect(FalobrisUi.theme.palette.accent, const Color(0xFFFFD96D));
    });
  });

  testWidgets('Sundered Keep panel reserves one aligned content surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
        ),
        home: const Center(
          child: PixelPanel(
            key: ValueKey('pixel-panel'),
            gridSize: PixelGridSize(columns: 8, rows: 8),
            padding: EdgeInsets.all(16),
            child: SizedBox(key: ValueKey('panel-content')),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('pixel-panel'))),
      const Size(128, 128),
    );
    expect(find.byKey(const ValueKey('panel-content')), findsOneWidget);
  });

  testWidgets('expanded panels tile into responsive parent constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
        ),
        home: const Center(
          child: SizedBox(
            width: 333,
            height: 187,
            child: PixelPanel.expanded(
              key: ValueKey('expanded-pixel-panel'),
              child: SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('expanded-pixel-panel'))),
      const Size(333, 187),
    );
  });

  testWidgets('responsive beams keep end cells whole', (tester) async {
    const corner = PixelAtlasRegion(column: 0, row: 0);
    const start = PixelAtlasRegion(column: 1, row: 0);
    const middle = PixelAtlasRegion(column: 2, row: 0);
    const end = PixelAtlasRegion(column: 3, row: 0);
    const fill = PixelAtlasRegion(column: 0, row: 1);
    const verticalStart = PixelAtlasRegion(column: 0, row: 2);
    const verticalMiddle = PixelAtlasRegion(column: 0, row: 3);
    const verticalEnd = PixelAtlasRegion(column: 0, row: 4);
    final atlas = PixelAtlasDefinition(assetPath: 'test-atlas.png');
    final recipe = PixelPanelRecipe(
      topLeft: corner,
      top: PixelTileVariants.sequence(const [
        start,
        middle,
        end,
      ], sequenceAxis: PixelTileSequenceAxis.horizontal),
      topRight: corner,
      left: PixelTileVariants.sequence(const [
        verticalStart,
        verticalMiddle,
        verticalEnd,
      ], sequenceAxis: PixelTileSequenceAxis.vertical),
      fill: PixelTileVariants.single(fill),
      right: PixelTileVariants.single(fill),
      bottomLeft: corner,
      bottom: PixelTileVariants.single(fill),
      bottomRight: corner,
    );

    final atlasRecorder = ui.PictureRecorder();
    final atlasCanvas = Canvas(atlasRecorder);
    atlasCanvas.drawRect(
      const Rect.fromLTWH(16, 0, 16, 16),
      Paint()..color = const Color(0xFFFF0000),
    );
    atlasCanvas.drawRect(
      const Rect.fromLTWH(32, 0, 16, 16),
      Paint()..color = const Color(0xFF00FF00),
    );
    atlasCanvas.drawRect(
      const Rect.fromLTWH(48, 0, 16, 16),
      Paint()..color = const Color(0xFF0000FF),
    );
    atlasCanvas.drawRect(
      const Rect.fromLTWH(0, 32, 16, 16),
      Paint()..color = const Color(0xFFFFFF00),
    );
    atlasCanvas.drawRect(
      const Rect.fromLTWH(0, 48, 16, 16),
      Paint()..color = const Color(0xFF00FFFF),
    );
    atlasCanvas.drawRect(
      const Rect.fromLTWH(0, 64, 16, 16),
      Paint()..color = const Color(0xFFFF00FF),
    );
    final atlasImage = atlasRecorder.endRecording().toImageSync(64, 80);
    addTearDown(atlasImage.dispose);

    final outputRecorder = ui.PictureRecorder();
    final outputCanvas = Canvas(outputRecorder);
    PixelPanelPainter.expanded(
      image: atlasImage,
      atlas: atlas,
      recipe: recipe,
      tileExtent: 16,
      seed: 0,
    ).paint(outputCanvas, const Size(75, 75));
    final output = outputRecorder.endRecording().toImageSync(75, 75);
    addTearDown(output.dispose);
    final bytes = await tester.runAsync(
      () => output.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final pixels = bytes!.buffer.asUint8List();

    List<int> rgbaAt(int x, int y) {
      final offset = ((y * 75 + x) * 4);
      return pixels.sublist(offset, offset + 4);
    }

    expect(rgbaAt(16, 8), [255, 0, 0, 255]);
    expect(rgbaAt(31, 8), [255, 0, 0, 255]);
    expect(rgbaAt(43, 8), [0, 0, 255, 255]);
    expect(rgbaAt(58, 8), [0, 0, 255, 255]);
    expect(rgbaAt(8, 16), [255, 255, 0, 255]);
    expect(rgbaAt(8, 31), [255, 255, 0, 255]);
    expect(rgbaAt(8, 43), [255, 0, 255, 255]);
    expect(rgbaAt(8, 58), [255, 0, 255, 255]);
  });

  testWidgets('panel painter handles a 512-tile card as one paint object', (
    tester,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.brown, BlendMode.src);
    final atlasImage = recorder.endRecording().toImageSync(128, 256);
    addTearDown(atlasImage.dispose);

    final painter = PixelPanelPainter(
      image: atlasImage,
      atlas: SunderedKeepUi.atlas,
      recipe: SunderedKeepUi.woodPanel,
      gridSize: const PixelGridSize(columns: 32, rows: 16),
      tileExtent: 16,
      seed: 7,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: CustomPaint(
            key: const ValueKey('painted-512-tile-card'),
            size: const Size(512, 256),
            painter: painter,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('painted-512-tile-card'))),
      const Size(512, 256),
    );
    expect(
      tester
          .widget<CustomPaint>(
            find.byKey(const ValueKey('painted-512-tile-card')),
          )
          .painter,
      same(painter),
    );
  });

  testWidgets('panel solid fills stay inside the one-tile frame', (
    tester,
  ) async {
    final atlasRecorder = ui.PictureRecorder();
    Canvas(atlasRecorder);
    final transparentAtlas = atlasRecorder.endRecording().toImageSync(128, 256);
    addTearDown(transparentAtlas.dispose);

    final outputRecorder = ui.PictureRecorder();
    final canvas = Canvas(outputRecorder);
    final painter = PixelPanelPainter(
      image: transparentAtlas,
      atlas: SunderedKeepUi.atlas,
      recipe: SunderedKeepUi.woodPanel,
      gridSize: const PixelGridSize(columns: 4, rows: 4),
      tileExtent: 16,
      seed: 0,
    );
    painter.paint(canvas, const Size(64, 64));
    final output = outputRecorder.endRecording().toImageSync(64, 64);
    addTearDown(output.dispose);
    final bytes = await tester.runAsync(
      () => output.toByteData(format: ui.ImageByteFormat.rawRgba),
    );
    final pixels = bytes!.buffer.asUint8List();

    int alphaAt(int x, int y) => pixels[((y * 64 + x) * 4) + 3];

    expect(alphaAt(0, 0), 0);
    expect(alphaAt(15, 15), 0);
    expect(alphaAt(16, 16), 255);
    expect(alphaAt(47, 47), 255);
    expect(alphaAt(48, 48), 0);
    expect(alphaAt(63, 63), 0);
  });

  testWidgets('standalone pixel sprites retain crisp sampling', (tester) async {
    const iconPath =
        'assets/sundered_keep/icons/'
        '16x16_RPG_Items_items_f0_c1_01873.png';

    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: PixelAssetSprite(
            assetPath: iconPath,
            width: 48,
            height: 48,
            semanticLabel: 'Curated item icon',
          ),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.filterQuality, FilterQuality.none);
    expect(image.isAntiAlias, isFalse);
    expect(image.semanticLabel, 'Curated item icon');
  });

  testWidgets('decoded atlases survive keyed surface rebuilds', (tester) async {
    Widget surface(String key) {
      return MaterialApp(
        home: Center(
          child: PixelPanel(
            key: ValueKey(key),
            gridSize: const PixelGridSize(columns: 12, rows: 5),
            atlas: NeonBulkheadUi.atlas,
            recipe: NeonBulkheadUi.panel,
            tileExtent: NeonBulkheadUi.itemTileExtent,
            child: const SizedBox.shrink(),
          ),
        ),
      );
    }

    await tester.runAsync(
      () => PixelAtlasCache.load(
        bundle: rootBundle,
        assetPath: NeonBulkheadUi.atlas.assetPath,
      ),
    );
    await tester.pumpWidget(surface('first-item-surface'));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is PixelPanelPainter,
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(surface('rebuilt-item-surface'));

    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is CustomPaint && widget.painter is PixelPanelPainter,
      ),
      findsOneWidget,
    );
  });
}
