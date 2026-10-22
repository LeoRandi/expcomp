import 'dart:ui';
import 'world_map.dart';
import 'world_maps.dart';

const crescaPavingAsset =
    'assets/pixel_ui/showcase/sheets_16grid/07_overworld_mixto/'
    '16x16_Block_Texture_Set/blocks__cobblestone_bricks.png.png';

ExplorationMap get crescaTown => loadedWorldMap(WorldArea.town);

Rect get crescaFarmBounds {
  final fences = crescaTown.props.where((prop) => prop.isFence);
  return fences
      .map((prop) => prop.position & const Size(1, 1))
      .reduce((a, b) => a.expandToInclude(b));
}
