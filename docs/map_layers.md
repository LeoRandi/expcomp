# Map rendering and collision

All exploration maps must compose terrain, roads, actors, buildings and effects
through WorldLayers in lib/exploration/world_layers.dart. Every WorldEntry requires
an explicit z value. Higher z values paint later, above lower values. Entries at
the same z sort by depth (the object's foot/baseline row), then insertion order.

| Content | z |
| --- | --- |
| Ground | 0 |
| Roads / ground decoration | 10 |
| Actors and building walls | 20 |
| Roofs / overhead scenery | 30 |
| Atmosphere / visibility | 100 |

Use MapBuilding.bounds for the visual projection and MapBuilding.footprint for
solid ground collision. Never derive collision from the sprite rectangle or its
alpha channel. Roof coverage is not a solid footprint. Closed doors remain solid;
enterable doors will need an explicit interaction/transition.

Every movement cell uses one 16 by 16 tile image per visual layer, drawn across
the full cell. Ground and roads are no longer subdivided into 2 by 2 art tiles.

Cresca's cottages occupy 3 by 3 visual cells, each using nine individual 16 by 16
RGBA PNGs. The top row renders overhead and is walkable; the bottom two rows
are solid walls. A one-tile-wide, two-tile-tall door occupies the center column
of those wall rows. Front edges remain at the roads. All house pieces come from the Outdoors tileset, with a blue roof, red timber walls and a wooden door.
The player participates in the world stack. Matching, opposite camera and actor
animations keep the player centered while scenery moves behind and above it.
The player has no opaque debug tile background.
House artwork comes exclusively from the existing Outdoors tileset;
tools/build_cottage_tiles.ps1 reproducibly assembles the individual PNGs.

For a new map, supply explicit layers for every entry, choose solid footprints
separately, and test passage beneath overhead art as well as blocked wall/door
cells. Do not append actors outside the layered stack.

Validation:
- flutter test test/cresca_map_test.dart test/widget_test.dart test/world_layers_test.dart
- The integration test writes build/cresca-behind-house.png for visual review.
- Asset tests compare every tile pixel with the assembled source, including alpha.




