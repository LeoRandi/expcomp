import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/inventory/inventory.dart';
import 'package:expcomp/inventory/item.dart';
import 'package:expcomp/party/creature_info_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('Totals and breakdown reflect draft points and gear at $size', (
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
        currentHp: tinyBot.baseStats.maxHp,
        source: CreatureSource.koredull,
      );
      creature.equipFrom(
        Inventory(items: {moonlessNecklace: 1}),
        moonlessNecklace,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: Scaffold(body: CreatureInfoPage(creature: creature)),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        final finder = find.byKey(ValueKey(key));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      await tap('section-stats');
      await tap('plus-CON');
      final base = creature.baseStats.con;
      expect(find.text('CON: ${base + 6}'), findsOneWidget);
      expect(find.textContaining('allocating'), findsNothing);
      await tap('stat-info-CON');
      expect(find.text('CON breakdown'), findsNothing);
      final breakdown = find.byKey(const ValueKey('stat-breakdown-CON'));
      for (final text in [
        'base',
        '$base',
        'allocating',
        '+1',
        'Equipment',
        '+5',
      ]) {
        expect(
          find.descendant(of: breakdown, matching: find.text(text)),
          findsOneWidget,
        );
      }
      final divider = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(Divider),
      );
      final total = find.byKey(const ValueKey('stat-breakdown-total-CON'));
      expect(tester.widget<Text>(total).data, '${base + 6}');
      expect(
        tester.getTopLeft(total).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(divider).dy),
      );
      await tap('close-stat-dialog');
      expect(find.byKey(const ValueKey('stat-dialog-CON')), findsNothing);
      expect(creature.extraPoints, isEmpty);
      for (final stat in statNames) {
        await tap('stat-info-$stat');
        expect(find.byKey(ValueKey('stat-breakdown-$stat')), findsOneWidget);
        await tap('close-stat-dialog');
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'Combat snapshot breakdown retains base, allocation and equipment sources',
    (tester) async {
      final stats = tinyBot.baseStats.withExtra({'CON': 8, 'SPE': 5});
      final snapshot = Creature(
        id: 'snapshot',
        name: 'Pip',
        species: tinyBot,
        stats: stats,
        currentHp: stats.maxHp,
        source: CreatureSource.koredull,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: Scaffold(
            body: CreatureInfoPage(
              creature: snapshot,
              readOnly: true,
              baseStats: tinyBot.baseStats,
              allocatedPoints: const {'CON': 3},
              equippedItem: moonlessNecklace,
              combatStats: {...stats.values, 'CON': stats.con - 2},
              statChanges: const {
                'CON': {'Draining Touch': -2, 'Cancelled effect': 0},
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('section-stats')));
      await tester.pumpAndSettle();
      expect(find.text('CON: ${stats.con - 2}'), findsOneWidget);
      expect(find.byKey(const ValueKey('plus-CON')), findsNothing);
      await tester.tap(find.byKey(const ValueKey('stat-info-CON')));
      await tester.pumpAndSettle();
      expect(find.text('Draining Touch'), findsOneWidget);
      expect(find.text('-2'), findsOneWidget);
      expect(find.text('Cancelled effect'), findsNothing);
      expect(find.text('Combat'), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('stat-breakdown-total-CON')),
            )
            .data,
        '${stats.con - 2}',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
