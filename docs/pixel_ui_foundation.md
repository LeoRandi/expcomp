# Pixel UI foundation

The pixel UI layer paints visual chrome and leaves interaction, text, focus,
semantics, drag targets, and scrolling to normal Flutter widgets.

## Core pieces

- `PixelGrid` snaps measurements to the 16-pixel rhythm.
- `PixelAtlasDefinition` gives names to source rectangles in an atlas.
- `PixelAtlasBuilder` resolves an atlas once and reuses the decoded image
  synchronously when a surface is moved or rebuilt.
- `PixelPanelRecipe` describes corners, repeating edges, center variants, and
  optional decorative stamps.
- `PixelTileTransform` rotates or flips an atlas cell so one real beam can
  continue cleanly along every side of a frame.
- `PixelPanelPainter` draws every tile into one canvas.
- `PixelPanel` layers semantic Flutter content over that canvas.
- `PixelSprite` draws a region from an atlas.
- `PixelAssetSprite` draws a curated standalone frame until it is packed.
- `PixelUiThemeData` provides the active atlas, palette, and surface recipes.
- `PixelButton`, `PixelBadge`, `PixelResourceBar`, `PixelTabs`,
  `PixelInventorySlot`, `PixelItemTile`, and `PixelDialogFrame` are the first
  reusable controls composed on top of the tiled surfaces.
- `PixelTextPlate` places a translucent themed backdrop behind arbitrary text
  while keeping the text itself fully opaque.

The application installs `SunderedKeepUi.theme`, so most components only need
to select a surface role. Item tiles and item information dialogs explicitly
resolve their visual skin from the item's domain-level `ItemSource`.

Current item sources map to pixel UI recipes as follows:

- `Raida` uses a moss-bound, spiked war-palisade assembled from Greenlands
  terrain and prop tiles.
- `Undiria` uses warm cave blocks.
- `Sunderkeep` uses the wooden beam frame.
- `Koredull` uses the sci-fi Neon Bulkhead frame.
- `Falobris` uses foamy shallows, sand, and island grass from the coastal
  tileset.

Every item preset has a non-empty `List<ItemTag>`. Its source tag is followed by
any behavior tags (`Attacker` for damage and `Healer` for healing or healing
boosts), and the item information dialog scrolls that list horizontally when
it exceeds the available width. Both source and tags are retained by `copyWith`
and `asTemplate`, so bought, moved, rotated, and enemy-owned item instances
preserve their visual identity and metadata.

Item information dialogs reserve the full source-specific pixel frame for the
outer dialog. Their icon, tags, and cooldown use thin square borders in the
source accent color, avoiding nested full-size tile frames while retaining each
source's palette and the existing layout dimensions.

```dart
PixelPanel(
  gridSize: const PixelGridSize(columns: 32, rows: 16),
  role: PixelSurfaceRole.panel,
  padding: const EdgeInsets.all(32),
  semanticLabel: 'Inventory',
  child: inventoryContent,
)
```

This produces a 512x256 card from 512 tile cells while keeping a single
painted background in the render tree.

Game surfaces that inherit a responsive layout use `PixelPanel.expanded`.
It anchors the corners and the start/end cells of every beam. When a parent is
not tile-aligned, only the repeat cells immediately after and before those beam
ends are clipped; the distinctive caps therefore stay complete at every size.
The same mode is available through `PixelResourceBar.expanded`. Game health
bars keep the standard 16-pixel tile scale, combining each corner and adjacent
beam tile into a complete 32-pixel end along the upper and lower frame. The
track spans the full interior between the 16-pixel side rails. The game health
bar is 64 pixels tall, leaving a 32-pixel-high interior track.

## Rendering rules

1. Keep source and destination rectangles aligned to whole pixels.
2. Use `FilterQuality.none` and disable antialiasing for raster art.
3. Give procedural variants a stable seed so rebuilds never make tiles jump.
4. Keep frequently changing content outside the background repaint boundary.
5. Prefer named atlas regions over asset paths in feature widgets.
6. Add source attribution and redistribution terms before shipping an asset.

## Sundered Keep panel anatomy

The active frame uses the V-shaped beam joints at atlas cells `(7, 8)` and
`(6, 8)`, immediately to the right of the chair sprites. Their source order is
diagonally inverted for a panel: the top corners are vertically flipped, while
the corresponding unflipped cells form the opposite bottom corners. The blue
atlas strips supply purpose-built beams: `(5, 7)` through `(7, 7)` horizontally
and `(7, 4)` through `(7, 6)` vertically. Each strip is treated as a start,
repeatable middle, and end sequence, so its caps remain next to the corners at
any panel size. The right beam is mirrored and the bottom beam is flipped to
keep their lighting facing into the frame. Since these source cells contain
transparency, the painter lays down a simple solid interior first and then
paints the timber frame over it.

Panel fills and fallback colors are restricted to the grid inside the
one-tile frame. `PixelPanelInterior` applies the same boundary to state tints
and other colored child layers, leaving every transparent corner and edge
pixel clear while text and interaction content can still use the full widget.

`woodPanel` uses a dark charcoal-brown center. `stoneInset` uses a warmer brown
center, so nested controls remain visually distinct without introducing a
second noisy tile pattern.

```dart
PixelTextPlate(
  backgroundOpacity: 0.55,
  child: Text('Readable over detailed pixel art'),
)
```

## Development showcase

In a debug build, launch the component showcase directly with:

```text
flutter run --route /pixel-ui-showcase
```

The route is deliberately absent from release builds. It is an interactive
workbench for buttons, badges, resource bars, tabs, inventory states, crisp
standalone sprites, dialog composition, and the 512x256 / 512-tile stress card.
Production screens do not depend on the showcase.

The showcase now exercises the primary V-joint timber frame plus four
alternative panel/widget directions:

- the true 3x3 purple sci-fi bulkhead used by Koredull items;
- the mossy war-palisade used by Raida items;
- warm cavern blocks used by Undiria items;
- the tidal island frame used by Falobris items;
- plus the earlier brick-joint timber treatment as an explicit fallback.

Alternate buttons and badges pass their atlas and recipe directly to
`PixelPanel`, so their interactions remain identical while their raster skin
changes.
