import 'package:flutter/widgets.dart';

/// Shared map layers. Visual height is independent of ground collision.
abstract final class WorldZ {
  static const ground = 0;
  static const road = 10;
  static const actor = 20;
  static const roof = 30;
  static const atmosphere = 100;
}

class WorldEntry {
  const WorldEntry({required this.z, required this.child, this.depth = 0});
  final int z;

  /// Feet/baseline in map coordinates; southern objects paint last.
  final double depth;
  final Widget child;
}

/// Stable z/depth ordering for terrain, actors, scenery and effects.
class WorldLayers extends StatelessWidget {
  const WorldLayers({super.key, required this.entries});
  final List<WorldEntry> entries;

  @override
  Widget build(BuildContext context) {
    final ordered = entries.indexed.toList()
      ..sort((a, b) {
        final z = a.$2.z.compareTo(b.$2.z);
        if (z != 0) return z;
        final depth = a.$2.depth.compareTo(b.$2.depth);
        return depth != 0 ? depth : a.$1.compareTo(b.$1);
      });
    return Stack(children: [for (final entry in ordered) entry.$2.child]);
  }
}
