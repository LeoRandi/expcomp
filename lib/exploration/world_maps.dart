import 'package:flutter/services.dart';
import 'text_map_loader.dart';
import 'world_map.dart';

const mapPrefixes = {
  WorldArea.town: 'cresca',
  WorldArea.testing: 'testing',
  WorldArea.routeOne: 'r1',
};
const mapLayers = ['objects', 'floor', 'chests', 'gates'];
final _pending = <(AssetBundle, WorldArea), Future<ExplorationMap>>{};
final _loaded = <WorldArea, ExplorationMap>{};

String worldMapAsset(WorldArea area, String layer) {
  final prefix = mapPrefixes[area]!;
  return 'assets/text-maps/$prefix/$prefix-$layer.txt';
}

Future<ExplorationMap> loadWorldMap(WorldArea area, AssetBundle bundle) =>
    _pending.putIfAbsent((bundle, area), () async {
      final layers = await Future.wait([
        for (final layer in mapLayers)
          bundle.loadString(worldMapAsset(area, layer)),
      ]);
      final map = parseTextMap(
        areaId: mapPrefixes[area]!,
        objectSource: layers[0],
        floorSource: layers[1],
        chestSource: layers[2],
        gateSource: layers[3],
      );
      if (map.area != area) {
        throw const FormatException(
          'Object legend area does not match its folder.',
        );
      }
      _loaded[area] = map;
      return map;
    });

Future<void> loadAllWorldMaps(AssetBundle bundle) async {
  await Future.wait([
    for (final area in WorldArea.values) loadWorldMap(area, bundle),
  ]);
}

ExplorationMap loadedWorldMap(WorldArea area) =>
    _loaded[area] ??
    (throw StateError(
      'Load ${area.name} text maps before reading its layout.',
    ));

ExplorationMap? cachedWorldMap(WorldArea area) => _loaded[area];

ExplorationMap get testingMap => loadedWorldMap(WorldArea.testing);
