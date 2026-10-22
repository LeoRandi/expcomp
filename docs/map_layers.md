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
Four decorative torch sprites remain in the testing area, positioned by
`crescaTorches` in `lib/exploration/cresca_map.dart`. Both maps depth-sort their
own torches in the actor layer.
The atmosphere uses `worldDarknessAt` for both the player and torches: circular
rings use Euclidean distance between tile centers. Distances below 3 are clear,
3 to below 4 / 4 to below 5 / 5 to below 6 have opacity 0.5/0.75/0.9,
and 6+ is opaque. Entire tiles are shaded, preserving a stepped pixel-art edge.
The nearest source determines visibility, so overlapping lights
never darken each other and torches stay lit when the player walks away.
The torch PNG is generated pixel art with transparency.
House artwork comes exclusively from the existing Outdoors tileset;
tools/build_cottage_tiles.ps1 reproducibly assembles the individual PNGs.

For a new map, supply explicit layers for every entry, choose solid footprints
separately, and test passage beneath overhead art as well as blocked wall/door
cells. Do not append actors outside the layered stack.

## Starting town and travel

`ExplorationMap` in `world_map.dart` supplies rectangular map dimensions, spawn,
buildings, scenery, torches, NPCs, and roads. `crescaTown` in `cresca_town.dart`
occupies 55×55 cells (3025), compared with the original testing map's 20×20 (400).
The settlement's building bounds are centered at (27.5,27), within half a tile of
the cavern's center (27.5,27.5), with dark outskirts on every side.
It has nine cottages, seven NPCs, a market and well, herb beds, benches, signs,
cavern fungi, and rubble beside Junto's fenced farm to the west. Its rocky perimeter
and solid scenery have explicit collision, independent of their artwork.
Town streets use the existing `blocks__cobblestone_bricks.png.png` ground tile,
one 16×16 image per road cell, on the road layer above the rough granite floor.
The paving connects every doorstep, both main streets, and the market junction.

The player starts at zero-based (20,25), directly south of their home door. The
stranger at (21,25) offers travel to the testing grounds at (10,10). The Waykeeper
at (11,10) there offers the return trip. Travel changes the map within the same
exploration session, preserving the player and inventory. Each arrival resets
local residents to their initial routine positions. Houses remain closed.

Every street in the town core lies within a torch's fully visible radius without
relying on the player's light. The north, east, and south roads continue to the
map boundaries with no additional torches; their far ends are dark. Those road
openings pass through the cavern rim. The north road enters Route 1; the other
three town boundaries wrap to the opposite side as transition test points. Torches occupy
clear cells beside the paving, keeping every road cell free of torches. Outer
corners remain dark. Warm pools below actors alternate
slightly while the shared atmosphere retains the original stepped visibility.
Scenery is drawn on a 16px grid in `town_scenery.dart`; existing cottage and torch
assets are reused.

Four residents walk short loops every 1.6 seconds, avoiding solid cells, the
player, and each other. They pause during conversations, menus, other routes,
and while the app is inactive. Bumping an NPC, tapping an adjacent NPC, or using
Talk / E / Space opens dialogue. Residents have one to three pages; travel and
sparring require choosing their action button. Escape/back or Leave cancels.
Dialogue follows [the provisional story](story.md).
The area name and static subtitle appear for one second each time a map is
entered, including the initial spawn. No persistent location or NPC hint appears
below the header. The one-second arrival animation uses a 200ms fade-in, a 600ms pause, and a
200ms fade-out. Its black panel has 0.3 opacity and 12px rounded corners. A new
area restarts the animation; its controller is disposed with the widget.

Validation:

- flutter test test/cresca_town_test.dart test/town_outskirts_test.dart
- The outskirts tests write build/juntos-farm.png for visual review.
- flutter test test/cresca_map_test.dart test/widget_test.dart test/world_layers_test.dart
- The town test writes build/cresca-start.png and build/cresca-start-portrait.png.
- The integration test writes build/cresca-behind-house.png for visual review.
- Asset tests compare every tile pixel with the assembled source, including alpha.

## Road signs and Junto's farm

The old in-town signs have been removed. Three solid, readable signs sit beside
roughly the middle of the outer roads: north at (28,10), east at (49,25), and south
at (31,43). North reads TO LUBIA with that destination visibly crossed out, then
KEEP OUT. Its second page comments on the crossed-out text. East reads TO FERN;
south reads TO FURION. Bump a sign, tap it from an adjacent cell, or use the shared
interaction button / E / Space. Reading pauses movement and residents as talking
does; a sign can never be entered as a movement cell.

Junto's farm occupies a closed 4x5 fence perimeter from (10,17) through (13,21),
with a shut gate at (13,19), a solid two-page sign immediately outside at (14,19),
and nearby rubble. Fence rails connect through tile edges, including corners.
The gate remains solid. Its overgrown interior is inaccessible from outside.

## Town building facades

Town buildings use `BuildingTile` to recompose the existing cottage atlas at
render time. The complete 16x32 source doorway fits in the bottom 16x16 cell;
matching timber fills the former upper doorway cell. The source PNGs and the
testing area's original cottages retain their existing artwork. Solid footprints
and roof layering are unchanged.

The inn's explicit `BuildingAppearance.inn` uses violet walls, sea-green shingles,
a small glowing roof window, and a striped canopy. Its solid, readable sign at
(35,25) names THE RESTING LANTERN and advertises rooms and warm meals on page two.

## Area transitions

**Mandatory rule: screen-changing animations MUST ALWAYS play for every screen
or scene change.** This applies to cardinal area crossings, entering or leaving
buildings, teleports, scripted travel, respawns, loading another location, and
transitions to or from other gameplay screens. New travel and navigation code
must use the shared transition animations; never switch a screen, map, or player
location to another scene with an unanimated swap.

Always close the view, swap the scene only under full black, then play the
opposing reveal. Use the matching cardinal curtain for directional crossings
and the player-centered circular iris for every other kind of change. Both
phases cover the entire UI and block all input, including the app bar and
buttons. The shared exploration travel path is `_travel` in
`lib/exploration/exploration_page.dart`; other gameplay screens must follow the
same lifecycle using `area_transition.dart`.

The direction pad moves once on pointer down. After a half-second hold window,
it repeats that movement every 200ms (first repeat at 0.7s). Releasing, pointer
cancellation, dragging off the diamond, or losing app focus cancels the hold.
Opening a menu, dialogue, or area transition also cancels it, so closing that
screen requires a fresh press to move again. A new direction replaces the held
direction; releasing the older pointer cannot cancel the newer one.

`area_transition.dart` supplies four directional curtains and a circular iris.
Each closing phase lasts exactly 1.2 seconds: 0.5s to 55% covered, 0.2s back to
45%, then 0.5s to full black. North covers bottom to top; east left to right;
south top to bottom; west right to left. Each segment eases at its endpoints.

For circular travel, the clear aperture is centered on the player's viewport
position. It shrinks from the farthest screen corner to a 2.5-tile radius in 0.5s,
expands to 3.5 tiles in 0.2s, then closes to zero in 0.5s.

The destination's art preloads during the cover. Once a fully black frame has
painted, the destination is positioned behind that mask without a camera tween.
The opening phase lasts another 1.2 seconds, reversing the opposing direction's
mask. Eastward travel therefore reveals left to right. The iris opens with the
reverse radius sequence: zero to 3.5 tiles, back to 2.5, then fully open.
If asset loading takes longer than the cover, the black mask waits for it.

The mask is above all exploration content, including the header, direction pad,
and menu windows. Its modal barrier blocks the entire viewport even during a
partial mask. Keyboard movement, interaction, menus, back navigation, and repeated
travel requests are guarded too. NPC routines pause throughout both phases.
Teleport dialogues finish closing before the mask starts. Arrival titles restart
after the reveal; disposing exploration cancels the in-flight animation safely.

`ExplorationMap.exits` defines each trigger, destination, arrival, and style.
The prototype's four two-cell openings are marked by ground arrows:

| Exit | Trigger cells | Arrival cell | Effect |
| --- | --- | --- | --- |
| North | (29,0), (30,0) | Route 1 (27,53) | Upward curtain |
| East | (54,26), (54,27) | (1,26) | Rightward curtain |
| South | (29,54), (30,54) | (29,1) | Downward curtain |
| West | (0,26), (0,27) | (53,26) | Leftward curtain |

The west end of the main street now reaches the boundary as well. Each arrival
is one cell inside its edge to avoid immediate retriggering. Same-map crossings
preserve residents' positions; cross-map travel preserves the player and their
inventory. The stranger and Waykeeper use the shared travel function's default
circle effect, which is also available for future indoor transitions.

Validation: `flutter test test/area_transition_test.dart` checks exact timing,
pixel coverage of all five masks, opposing reveals, the three town wrap crossings at desktop
and portrait sizes, input blocking during both halves, NPC/inventory preservation,
and disposal. It also reads back actual rendered frames at the swap to verify
every screen pixel is black, including the header and buttons.

## Route 1 template

`route_one.dart` loads `assets/text-maps/r1.txt` for objects and
`assets/text-maps/r1-floor.txt` for ground, validates matching rectangular grids
and 2-row by 3-column house footprints, and builds the map's collision, torches,
props, and return gate. Text cells are available through
`ExplorationMap.tileAt`; `X`, `r`, `h`, and `C` are solid. The house uses the same
3x3 cottage art as Cresca, with its roof projected above the 3x2 `h` footprint.

`ExplorationMap.floorAt` reads the independent floor layer: `.` is sand and `-`
is granite. Floor draft `X`/`0` markers normalize to granite; they never add walls
or gates. Sand is drawn below props and gates even when the object layer contains
`r`, `C`, `i`, or `0` at that coordinate. Collision depends only on the object map.

`route_one_scenery.dart` uses cave-sheet rock for walls, the castle atlas's closed
chest, and the imported sand and grass tiles. Boulders are large, jagged sprites
drawn on a 16×20 pixel grid with stable shape variants. Their visuals overhang a
quarter tile upward while collision remains one cell and depth uses their feet.

Ground grass sits at z=10. `GrassCoveredSprite` attaches the lower-half grass
cover inside the player's animated bounds at the actor layer. The cover remains
present between grass destinations, follows every movement frame, and disappears
on leaving grass. Do not restore a fixed grass foreground on world tiles: that
exposes the player's legs when moving vertically between them. Roofs and lighting
remain above the complete player sprite and its cover.

Cresca's north exit arrives at (27,53). Route 1's southern gate at (26..28,54)
returns to (29,1) in Cresca. Both use the full cover/swap/reveal lifecycle. Text
and art preload during the cover; the black frame waits until they are ready.
The other `0` openings are inactive placeholders. Rocks and chests are solid
scenery, the house stays closed, and no encounters or item rewards are attached.

Validation: `flutter test test/route_one_test.dart` covers text/collision parity,
house geometry, inert props, both travel directions at desktop and portrait
sizes, independent sand beneath props/gates, lower-half grass pixels, and cover
alignment throughout vertical movement into, between, and out of grass cells. It
also writes `build/route1-grass.png`, `build/route1-chest.png`, and
`build/route1-house.png`, and `build/route1-rocks.png` for visual review.
