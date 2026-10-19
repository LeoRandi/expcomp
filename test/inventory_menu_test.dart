import 'package:expcomp/exploration/exploration_page.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/inventory/item.dart';
import 'package:expcomp/player/player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(800, 600)]) {
    testWidgets('App bar switches windows and nested details at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: ExplorationPage(player: Player.demo()),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> tap(String key) async {
        await tester.tap(find.byKey(ValueKey(key)));
        await tester.pumpAndSettle();
      }

      final world = find.byKey(const ValueKey('world-grid'));
      final before = tester.getTopLeft(world);
      await tap('open-inventory');
      await tap('open-inventory');
      expect(find.byKey(const ValueKey('inventory-menu')), findsNothing);
      await tap('open-party');
      await tap('open-party');
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      await tap('open-party');
      await tap('details-tiny_bot_01');
      await tap('open-party');
      expect(find.byKey(const ValueKey('info-back')), findsNothing);
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Youngest of Cresca'), findsNothing);
      await tap('open-party');
      await tap('open-inventory');
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      expect(find.text('Meat'), findsOneWidget);
      await tap('open-party');
      expect(find.byKey(const ValueKey('inventory-menu')), findsNothing);
      expect(find.text('Pip'), findsOneWidget);
      await tap('details-tiny_bot_01');
      await tap('rename-creature');
      // Even a nested editor stays below the app bar and is discarded on switch.
      await tap('open-inventory');
      expect(find.byType(TextField), findsNothing);
      expect(find.byKey(const ValueKey('info-back')), findsNothing);
      expect(find.text('Meat'), findsOneWidget);
      await tap('open-party');
      await tap('details-tiny_bot_01');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('info-back')), findsNothing);
      expect(find.byKey(const ValueKey('party-menu')), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.text('Youngest of Cresca'), findsOneWidget);
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      await tap('open-inventory');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world), before);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('inventory-menu')), findsNothing);
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world).dy, lessThan(before.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Inventory layout, movement lock and quantities at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final player = Player.demo();
      const ration = Item(
        id: 'ration',
        name: 'Ration',
        icon: ItemIcon.meat,
        category: ItemCategory.items,
      );
      player.inventory.add(ration);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [SunderedKeepUi.theme]),
          home: ExplorationPage(player: player),
        ),
      );
      await tester.pumpAndSettle();
      final world = find.byKey(const ValueKey('world-grid'));
      final before = tester.getTopLeft(world);
      await tester.tap(find.byKey(const ValueKey('open-inventory')));
      await tester.pumpAndSettle();
      expect(find.text('Meat'), findsOneWidget);
      expect(find.text('Inventory'), findsNothing);
      expect(find.text('Moonless necklace'), findsNothing);
      expect(find.text('x1'), findsNWidgets(2));
      expect(find.text('x2'), findsNothing);
      final first = find.byKey(const ValueKey('inventory-item-meat'));
      final second = find.byKey(const ValueKey('inventory-item-ration'));
      expect(tester.getSize(first).height, 64);
      expect(tester.getSize(second).height, 64);
      expect(tester.getTopLeft(second).dy - tester.getBottomLeft(first).dy, 2);
      final square = find.descendant(
        of: first,
        matching: find.byType(PixelPanel),
      );
      expect(tester.getSize(square), const Size(48, 48));
      expect(tester.getTopLeft(square).dy - tester.getTopLeft(first).dy, 8);
      expect(
        tester.getBottomLeft(first).dy - tester.getBottomLeft(square).dy,
        8,
      );
      await tester.tap(find.byKey(const ValueKey('inventory-tab-equipment')));
      await tester.pumpAndSettle();
      expect(find.text('Moonless necklace'), findsOneWidget);
      expect(find.text('x2'), findsOneWidget);
      expect(find.text('Meat'), findsNothing);
      expect(
        tester
            .widget<PixelButton>(
              find.byKey(const ValueKey('inventory-tab-equipment')),
            )
            .selected,
        isTrue,
      );
      await tester.tap(find.byKey(const ValueKey('inventory-tab-key')));
      await tester.pumpAndSettle();
      expect(find.text('No items in this category.'), findsOneWidget);
      expect(find.text('Moonless necklace'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('inventory-tab-items')));
      await tester.pumpAndSettle();
      expect(find.text('Meat'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world), before);
      await tester.tap(find.byKey(const ValueKey('close-inventory')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world).dy, lessThan(before.dy));
      player.inventory.add(meat, 2);
      await tester.tap(find.byKey(const ValueKey('open-inventory')));
      await tester.pumpAndSettle();
      expect(find.text('x3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
