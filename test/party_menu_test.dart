import 'package:expcomp/main.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:expcomp/creatures/creature.dart';
import 'package:expcomp/party/creature_source_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Party shows two companions, four empty slots and blocks world input',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      final world = find.byKey(const ValueKey('world-grid'));
      final before = tester.getTopLeft(world);
      await tester.tap(find.byKey(const ValueKey('open-party')));
      await tester.pumpAndSettle();
      expect(find.text('Pip'), findsOneWidget);
      expect(find.text('Cinder'), findsNothing);
      expect(find.text('RAIDA'), findsNothing);
      expect(find.text('UNDIRIA'), findsNothing);
      for (final entry in {'tiny_bot_01': CreatureSource.koredull}.entries) {
        final card = tester.element(find.byKey(ValueKey('party-${entry.key}')));
        expect(
          PixelUiThemeData.of(card).atlas,
          themeForSource(entry.value).atlas,
        );
      }
      for (var i = 2; i < 6; i++) {
        expect(find.byKey(ValueKey('empty-party-slot-$i')), findsOneWidget);
      }
      expect(
        tester
            .widget<PixelButton>(
              find.byKey(const ValueKey('details-tiny_bot_01')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('details-tiny_bot_01')));
      await tester.pumpAndSettle();
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.byKey(const ValueKey('open-party')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('info-back')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('party-menu')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world), before);
      await tester.tap(find.byKey(const ValueKey('close-party')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('party-menu')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(world).dy, lessThan(before.dy));
      expect(tester.takeException(), isNull);
    },
  );
}
