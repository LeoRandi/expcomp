import 'dart:ui';

/// Footprints include roofs and closed doors: these buildings are scenery.
const crescaHouses = [Rect.fromLTWH(5, 6, 3, 3), Rect.fromLTWH(12, 3, 3, 3)];

bool isHouseTile(int column, int row) =>
    crescaHouses.any((house) => house.contains(Offset(column + .5, row + .5)));

bool isRoadTile(int column, int row) =>
    !isHouseTile(column, row) &&
    ((column >= 9 && column <= 10 && row >= 3 && row <= 16) ||
        (row == 9 && column >= 6 && column <= 10) ||
        (row == 6 && column >= 9 && column <= 13));
