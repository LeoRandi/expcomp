import 'package:flutter/services.dart';
import 'text_map_loader.dart';
import 'world_maps.dart';
import 'world_map.dart';

String get routeOneTextAsset => worldMapAsset(WorldArea.routeOne, 'objects');
String get routeOneFloorAsset => worldMapAsset(WorldArea.routeOne, 'floor');
String get routeOneChestsAsset => worldMapAsset(WorldArea.routeOne, 'chests');
String get routeOneGatesAsset => worldMapAsset(WorldArea.routeOne, 'gates');

Future<ExplorationMap> loadRouteOne(AssetBundle bundle) =>
    loadWorldMap(WorldArea.routeOne, bundle);

ExplorationMap parseRouteOne(
  String source, {
  required String floorSource,
  required String chestSource,
  required String gateSource,
}) => parseTextMap(
  areaId: 'r1',
  objectSource: source,
  floorSource: floorSource,
  chestSource: chestSource,
  gateSource: gateSource,
);
