import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'cresca_map.dart';

final _cottageAtlas = PixelAtlasDefinition(
  assetPath: 'assets/overworld/cottage/cottage.png',
);

/// Recompose the existing cottage art without changing its solid footprint.
class BuildingTile extends StatelessWidget {
  const BuildingTile({
    super.key,
    required this.column,
    required this.row,
    required this.appearance,
  });

  final int column;
  final int row;
  final BuildingAppearance appearance;

  @override
  Widget build(BuildContext context) => PixelAtlasBuilder(
    atlas: _cottageAtlas,
    builder: (context, image, error) => CustomPaint(
      painter: _BuildingTilePainter(image, column, row, appearance),
    ),
  );
}

class _BuildingTilePainter extends CustomPainter {
  const _BuildingTilePainter(
    this.image,
    this.column,
    this.row,
    this.appearance,
  );
  final ui.Image? image;
  final int column;
  final int row;
  final BuildingAppearance appearance;

  @override
  void paint(Canvas canvas, Size size) {
    final source = image;
    if (source == null) return;
    canvas.save();
    canvas.scale(size.width / 16, size.height / 16);
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (appearance == BuildingAppearance.inn) {
      // Sea-green shingles and violet timber retain the source's shading.
      paint.colorFilter = ColorFilter.matrix(
        row == 0
            ? const [
                .3,
                0,
                0,
                0,
                8,
                0,
                .8,
                .2,
                0,
                0,
                0,
                .4,
                .6,
                0,
                0,
                0,
                0,
                0,
                1,
                0,
              ]
            : const [
                .65,
                0,
                .25,
                0,
                12,
                .25,
                .4,
                0,
                0,
                4,
                .65,
                0,
                .45,
                0,
                15,
                0,
                0,
                0,
                1,
                0,
              ],
      );
    }
    var region = Rect.fromLTWH(column * 16.0, row * 16.0, 16, 16);
    if (column == 1 && row == 1) {
      // Fill the former upper half of the doorway with matching timber wall.
      region = const Rect.fromLTWH(4, 16, 10, 16);
    } else if (column == 1 && row == 2) {
      // The complete door now occupies only the bottom movement cell.
      region = const Rect.fromLTWH(16, 16, 16, 32);
    }
    canvas.drawImageRect(
      source,
      region,
      const Rect.fromLTWH(0, 0, 16, 16),
      paint,
    );
    if (appearance == BuildingAppearance.inn) {
      void block(double x, double y, double w, double h, int color) {
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()..color = Color(color),
        );
      }

      if (row == 1) {
        // A striped canopy distinguishes the facade as well as its palette.
        block(0, 12, 16, 4, 0xFFD4B476);
        for (var x = 0; x < 16; x += 8) {
          block(x.toDouble(), 12, 4, 4, 0xFF604971);
        }
        block(0, 15, 16, 1, 0xFF42334F);
      }
      if (row == 0 && column == 1) {
        block(5, 6, 6, 7, 0xFF3F304C);
        block(6, 7, 4, 5, 0xFFE9C273);
        block(7, 7, 1, 5, 0xFF675056);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BuildingTilePainter oldDelegate) =>
      image != oldDelegate.image ||
      column != oldDelegate.column ||
      row != oldDelegate.row ||
      appearance != oldDelegate.appearance;
}
