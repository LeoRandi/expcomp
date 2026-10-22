# Curated visual assets

The runtime visual library is intentionally narrow:

- `sundered_keep/tiles/` contains the warm castle atlas used by the UI skin.
- `sundered_keep/icons/` contains 139 compatible 16x16 RPG icons retained for
  the item-icon atlas.
- `monsters/` contains 370 character and monster sprites whose four corner
  pixels are transparent. Opaque preview tiles and baked backgrounds were
  removed from the project.
- `pixel_ui/showcase/` contains three compact experimental atlases used only
  by the debug UI skin lab: purple sci-fi, amethyst dungeon, and cave masonry.

Only add an asset when it matches the active game direction or has a clear UI
exploration/gameplay role. Experimental styles stay isolated under
`pixel_ui/showcase/`. Prefer atlases at runtime; standalone files remain
supported for characters that have not been packed yet.

Exploration also reuses the existing imported tiles under
`pixel_ui/showcase/tiles_16x16/`: Idylwild's `foliage_pack` tiles `(7,6)` and
`(8,6)` for rocks, `(13,6)` for crates, and `(14,15)` for flowers, plus Puny World
tile `(22,27)` for indoor wooden panels. Coordinates are `(column,row)` in the
source tile names. Indoor masonry and benches use the castle atlas; doors use
the cottage atlas. `lib/exploration/stock_prop_sprite.dart` owns the shared prop
lookup. Furniture without suitable existing artwork uses plain labeled tiles.

The imported source collection did not include license or attribution files.
Provenance and redistribution rights must be recorded before release.
