import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(PixelAtlasCache.clear);

  Widget testApp(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
      ),
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('PixelButton invokes actions and blocks its disabled state', (
    tester,
  ) async {
    var invocations = 0;
    await tester.pumpWidget(
      testApp(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelButton(
              key: const ValueKey('enabled-button'),
              label: 'Enter',
              onPressed: () => invocations += 1,
            ),
            const PixelButton(
              key: ValueKey('disabled-button'),
              label: 'Locked',
              onPressed: null,
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('enabled-button')));
    await tester.tap(find.byKey(const ValueKey('disabled-button')));

    expect(invocations, 1);
    expect(
      tester.getSize(find.byKey(const ValueKey('enabled-button'))),
      const Size(128, 48),
    );
  });

  testWidgets('buttons accept an explicit atlas and surface recipe', (
    tester,
  ) async {
    final skin = PixelUiShowcaseSkins.skins.first;
    await tester.pumpWidget(
      testApp(
        PixelButton(
          key: const ValueKey('skinned-button'),
          label: 'Console',
          atlas: skin.atlas,
          recipe: skin.recipe,
          onPressed: () {},
        ),
      ),
    );

    final panel = tester.widget<PixelPanel>(
      find.descendant(
        of: find.byKey(const ValueKey('skinned-button')),
        matching: find.byType(PixelPanel),
      ),
    );
    expect(panel.atlas, same(skin.atlas));
    expect(panel.recipe, same(skin.recipe));
  });

  testWidgets('experimental showcase atlases are bundled', (tester) async {
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    final bundle = DefaultAssetBundle.of(
      tester.element(find.byType(SizedBox).first),
    );

    for (final skin in PixelUiShowcaseSkins.skins.where(
      (skin) => skin.atlas.assetPath.startsWith('assets/pixel_ui/showcase/'),
    )) {
      final bytes = await bundle.load(skin.atlas.assetPath);
      expect(bytes.lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('PixelTabs reports selection without owning feature state', (
    tester,
  ) async {
    var selected = 0;
    await tester.pumpWidget(
      testApp(
        PixelTabs(
          tabs: const [
            PixelTabData(label: 'Pack'),
            PixelTabData(label: 'Gear'),
          ],
          selectedIndex: selected,
          onSelected: (value) => selected = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pixel-tab-1')));

    expect(selected, 1);
  });

  testWidgets('resource bars clamp visual progress and expose their value', (
    tester,
  ) async {
    const bar = PixelResourceBar(
      label: 'Health',
      value: 140,
      maximum: 100,
      columns: 12,
    );
    await tester.pumpWidget(testApp(bar));

    expect(bar.fraction, 1);
    expect(bar.valueText, '100/100');
    expect(tester.getSize(find.byType(PixelResourceBar)), const Size(192, 48));
  });

  testWidgets('expanded resource bars keep complete 32-pixel ends', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const SizedBox(
          width: 320,
          height: 64,
          child: PixelResourceBar.expanded(
            key: ValueKey('expanded-resource-bar'),
            value: 18,
            maximum: 25,
            tileExtent: 16,
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('expanded-resource-bar'))),
      const Size(320, 64),
    );
    final fill = find.byWidgetPredicate(
      (widget) =>
          widget is ColoredBox &&
          widget.color == SunderedKeepUi.theme.palette.health,
    );
    expect(tester.getSize(fill), const Size(204, 28));

    await tester.pumpWidget(
      testApp(
        const SizedBox(
          width: 320,
          height: 64,
          child: PixelResourceBar.expanded(
            value: 5,
            maximum: 25,
            tileExtent: 16,
          ),
        ),
      ),
    );
    expect(tester.getSize(fill), const Size(56, 28));

    await tester.pumpWidget(
      testApp(
        const SizedBox(
          width: 320,
          height: 64,
          child: PixelResourceBar.expanded(
            value: 25,
            maximum: 25,
            tileExtent: 16,
          ),
        ),
      ),
    );
    expect(tester.getSize(fill), const Size(284, 28));
  });

  testWidgets('inventory slots preserve their tile-grid geometry', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const PixelInventorySlot(
          key: ValueKey('valid-slot'),
          state: PixelInventorySlotState.validDrop,
          semanticLabel: 'Valid destination',
          child: SizedBox.shrink(),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('valid-slot'))),
      const Size(64, 64),
    );
    expect(find.bySemanticsLabel('Valid destination'), findsOneWidget);
  });

  testWidgets('PixelTextPlate fades only its backdrop', (tester) async {
    await tester.pumpWidget(
      testApp(
        const PixelTextPlate(
          key: ValueKey('text-plate'),
          child: Text('Readable label'),
        ),
      ),
    );

    final plate = find.byKey(const ValueKey('text-plate'));
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.descendant(
                    of: plate,
                    matching: find.byType(DecoratedBox),
                  ),
                )
                .decoration
            as BoxDecoration;

    expect(
      decoration.color,
      SunderedKeepUi.theme.palette.canvas.withValues(alpha: 0.55),
    );
    expect(
      find.descendant(of: plate, matching: find.byType(Opacity)),
      findsNothing,
    );
    expect(find.text('Readable label'), findsOneWidget);
  });

  testWidgets('showcase builds every primitive including the 512-tile card', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
        ),
        home: const PixelUiShowcasePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pixel-ui-showcase')), findsOneWidget);
    expect(find.byType(PixelButton), findsWidgets);
    expect(find.byType(PixelBadge), findsWidgets);
    expect(find.byType(PixelResourceBar), findsWidgets);
    expect(find.byType(PixelTabs), findsOneWidget);
    expect(find.byType(PixelInventorySlot), findsNWidgets(5));
    expect(find.byType(PixelItemTile), findsNWidgets(3));
    expect(find.byType(PixelDialogFrame), findsOneWidget);
    expect(find.byType(PixelTextPlate), findsWidgets);
    for (var index = 0; index < PixelUiShowcaseSkins.skins.length; index += 1) {
      expect(find.byKey(ValueKey('showcase-skin-$index')), findsOneWidget);
    }
    expect(
      tester.getSize(find.byKey(const ValueKey('showcase-512-tile-card'))),
      const Size(512, 256),
    );
  });
}
