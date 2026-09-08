import 'package:expcomp/battle/battle_page.dart';
import 'package:expcomp/battle/combatant_motion.dart';
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Attacker lunges before the target recoils at 200 milliseconds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [SunderedKeepUi.theme]),
        home: const BattlePage(),
      ),
    );
    await tester.pumpAndSettle();
    Finder option(int ally, int move) => find.descendant(
      of: find.byKey(ValueKey('ally-hexagon-$ally')),
      matching: find.byKey(ValueKey('move-option-$move')),
    );
    await tester.tap(option(0, 1)); // PSYCLASH hits unguarded enemy 2.
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-move')));
    await tester.pumpAndSettle();
    await tester.tap(option(1, 2));
    await tester.pumpAndSettle();
    final attacker = find.byKey(const ValueKey('ally-0'));
    final target = find.byKey(const ValueKey('enemy-1'));
    final start = tester.getCenter(attacker);
    final targetStart = tester.getCenter(target);
    await tester.tap(find.byKey(const ValueKey('confirm-move')));
    await tester.pump();
    // Enemy 1's priority +2 ward completes before Briar's priority 0 action.
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getCenter(attacker).dy, lessThan(start.dy));
    expect(tester.getCenter(target), targetStart);
    await tester.pump(const Duration(milliseconds: 149));
    final motion = find.byKey(const ValueKey('motion-enemy-1'));
    expect(tester.widget<CombatantMotion>(motion).hitPulse, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.widget<CombatantMotion>(motion).hitPulse, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 45));
    expect(tester.getCenter(target).dx, isNot(closeTo(targetStart.dx, .01)));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
