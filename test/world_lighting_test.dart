import 'package:expcomp/exploration/cresca_map.dart';
import 'package:expcomp/exploration/world_lighting.dart';
import 'package:expcomp/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Rounded auras use the reduced radius along each axis', () {
    const light = Offset(10, 10);
    const expected = [0.0, 0.0, 0.0, 0.5, 0.75, 0.9, 1.0, 1.0];
    for (var distance = 0; distance < expected.length; distance++) {
      expect(worldDarknessAt(10 + distance, 10, [light]), expected[distance]);
      expect(worldDarknessAt(10, 10 - distance, [light]), expected[distance]);
    }
  });

  test('Light expands radially with rounded tile rings in every quadrant', () {
    const light = Offset(10, 10);
    for (final dx in [-1, 1]) {
      for (final dy in [-1, 1]) {
        expect(worldDarknessAt(10 + 2 * dx, 10 + 2 * dy, [light]), 0);
        expect(worldDarknessAt(10 + 2 * dx, 10 + 3 * dy, [light]), .5);
        expect(worldDarknessAt(10 + 3 * dx, 10 + 3 * dy, [light]), .75);
        expect(worldDarknessAt(10 + 3 * dx, 10 + 4 * dy, [light]), .9);
        expect(worldDarknessAt(10 + 4 * dx, 10 + 5 * dy, [light]), 1);
        expect(worldDarknessAt(10 + 5 * dx, 10 + 5 * dy, [light]), 1);
      }
    }
  });

  test('Torch light persists when the player leaves; overlaps stay clear', () {
    for (final torch in crescaTorches) {
      final x = torch.dx.toInt();
      final y = torch.dy.toInt();
      expect(worldDarknessAt(x, y, [Offset.zero, ...crescaTorches]), 0);
      expect(worldDarknessAt(x, y, [torch, ...crescaTorches]), 0);
      expect(isHouseTile(x, y), isFalse);
    }
    expect(worldDarknessAt(4, 0, [Offset.zero, const Offset(8, 0)]), .75);
    expect(worldDarknessAt(0, 0, []), 1);
  });

  testWidgets('Testing area loads four torch sprites', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    for (final torch in crescaTorches) {
      final placed = find.byKey(
        ValueKey('torch-${torch.dx.toInt()}-${torch.dy.toInt()}'),
      );
      expect(placed, findsOneWidget);
      final sprite = tester.widget<Image>(
        find.descendant(of: placed, matching: find.byType(Image)),
      );
      expect(
        (sprite.image as AssetImage).assetName,
        'assets/overworld/torch.png',
      );
      expect(sprite.filterQuality, FilterQuality.none);
    }
    expect(tester.takeException(), isNull);
  });
}
