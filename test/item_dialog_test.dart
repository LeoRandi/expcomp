import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/creatures/showcase_party.dart';
import 'package:expcomp/exploration/exploration_page.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/inventory/inventory.dart';
import 'package:expcomp/inventory/inventory_menu.dart';
import 'package:expcomp/inventory/item_catalog.dart';
import 'package:expcomp/player/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets(
      'Item details, cancel, party choice and bag transfer at $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final bag = Inventory(items: {meat: 1, moonlessNecklace: 2});
        final party = [
          for (final c in showcaseParty)
            Creature(
              id: c.id,
              name: c.name,
              species: c.species,
              stats: c.baseStats,
              currentHp: c.baseStats.maxHp,
              source: c.source,
            ),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [SunderedKeepUi.theme]),
            home: Scaffold(
              body: InventoryMenu(inventory: bag, party: party, onClose: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> tap(String key) async {
          await tester.tap(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
        }

        await tap('inventory-item-meat');
        final dialog = find.byKey(const ValueKey('item-dialog'));
        expect(
          find.descendant(of: dialog, matching: find.text('Meat')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.byIcon(Icons.kebab_dining),
          ),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('equip-item')), findsNothing);
        await tap('close-item-dialog');
        await tap('inventory-tab-equipment');
        await tap('inventory-item-moonless_necklace');
        expect(find.text(moonlessNecklace.effectText), findsOneWidget);
        await tap('equip-item');
        await tap('close-item-dialog');
        expect(bag.quantityOf(moonlessNecklace), 2);
        expect(party.every((c) => c.equippedItem == null), isTrue);
        await tap('inventory-item-moonless_necklace');
        await tap('equip-item');
        await tap('equip-to-${party.first.id}');
        expect(dialog, findsNothing);
        expect(find.text('x1'), findsOneWidget);
        expect(party.first.equippedItem, moonlessNecklace);
        expect(party.last.equippedItem, isNull);
        await tap('inventory-item-moonless_necklace');
        await tap('equip-item');
        expect(
          tester
              .widget<PixelButton>(
                find.byKey(ValueKey('equip-to-${party.first.id}')),
              )
              .onPressed,
          isNull,
        );
        await tap('equip-to-${party.last.id}');
        expect(find.text('No items in this category.'), findsOneWidget);
        expect(bag.quantityOf(moonlessNecklace), 0);
        expect(party.last.stats.spe, party.last.baseStats.spe + 5);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Equipment persists into party details and nested dialogs close on switching',
    (tester) async {
      final player = Player.demo();
      final creature = showcaseParty.first;
      addTearDown(() => creature.unequipTo(player.inventory));
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: ExplorationPage(player: player),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      await tap('open-inventory');
      await tap('inventory-item-meat');
      await tap('open-party');
      expect(find.byKey(const ValueKey('item-dialog')), findsNothing);
      await tap('open-inventory');
      await tap('inventory-tab-equipment');
      await tap('inventory-item-moonless_necklace');
      await tap('equip-item');
      await tap('equip-to-${creature.id}');
      await tap('open-party');
      await tap('details-${creature.id}');
      expect(find.text('Max HP: ${creature.maxHp}'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('section-item')));
      await tap('section-item');
      expect(find.textContaining(moonlessNecklace.name), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('section-stats')));
      await tap('section-stats');
      expect(find.text('CON: ${creature.stats.con}'), findsOneWidget);
      expect(find.text('SPE: ${creature.stats.spe}'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
