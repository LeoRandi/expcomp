import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/party/creature_info_page.dart';
import 'package:expcomp/party/creature_source_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('Info drafts, collapses, scrolls, and saves at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final creature = Creature(
        id: 'test',
        name: 'Pip',
        species: tinyBot,
        stats: tinyBot.baseStats,
        currentHp: 160,
        source: CreatureSource.koredull,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      body: SafeArea(
                        child: CreatureInfoPage(creature: creature),
                      ),
                    ),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      Future<void> tapKey(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        PixelUiThemeData.of(
          tester.element(find.byKey(const ValueKey('info-save'))),
        ).atlas,
        themeForSource(creature.source).atlas,
      );
      for (final button in tester.widgetList<PixelButton>(
        find.byType(PixelButton),
      )) {
        if (button.key == null) continue;
        final frame = find.descendant(
          of: find.byKey(button.key!),
          matching: find.byType(PixelPanel),
        );
        final size = tester.getSize(frame);
        expect(size.width % button.tileExtent, closeTo(0, .001));
        expect(size.height % button.tileExtent, closeTo(0, .001));
      }
      expect(
        tester
            .widget<PixelButton>(find.byKey(const ValueKey('info-save')))
            .tileExtent,
        16,
      );
      expect(
        tester
            .widget<PixelButton>(find.byKey(const ValueKey('plus-CON')))
            .tileExtent,
        8,
      );
      expect(
        tester
            .widget<PixelButton>(find.byKey(const ValueKey('change-move-0')))
            .role,
        PixelSurfaceRole.inset,
      );
      final saveRect = tester.getRect(find.byKey(const ValueKey('info-save')));
      await tapKey('plus-CON');
      expect(creature.stats.con, 16);
      await tapKey('section-stats');
      expect(find.byKey(const ValueKey('plus-CON')), findsNothing);
      await tapKey('section-stats');
      for (var i = 0; i < 9; i++) {
        await tapKey('plus-CON');
      }
      expect(
        tester
            .widget<PixelButton>(find.byKey(const ValueKey('plus-CON')))
            .onPressed,
        isNull,
      );
      await tapKey('minus-CON');
      await tapKey('plus-MPR');
      await tapKey('change-move-0');
      expect(
        PixelUiThemeData.of(tester.element(find.byType(Dialog))).atlas,
        themeForSource(creature.source).atlas,
      );
      await tester.scrollUntilVisible(
        find.text('EMPTY SLOT'),
        200,
        scrollable: find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('EMPTY SLOT'));
      await tester.pumpAndSettle();
      expect(find.text('EMPTY MOVE SLOT 1'), findsOneWidget);
      expect(creature.equippedMoves.first, isNotNull);
      expect(tester.getRect(find.byKey(const ValueKey('info-save'))), saveRect);
      await tapKey('info-back');
      expect(creature.extraPoints, isEmpty);
      expect(creature.equippedMoves.first, isNotNull);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tapKey('plus-CON');
      await tapKey('change-move-0');
      await tester.scrollUntilVisible(
        find.text('EMPTY SLOT'),
        200,
        scrollable: find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('EMPTY SLOT'));
      await tester.pumpAndSettle();
      await tapKey('info-save');
      expect(creature.stats.con, 17);
      expect(creature.equippedMoves.first, isNull);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Max HP: 170'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
