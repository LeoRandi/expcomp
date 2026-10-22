# Text maps

[r1.txt](r1.txt) defines Route 1's objects, grass, walls, and gates.
[r1-floor.txt](r1-floor.txt) defines the ground beneath them. The game loads both
files directly through `lib/exploration/route_one.dart` when entering Route 1.

Each character is one tile. Route 1 uses an intended 55-column, 55-row grid.
North is up. Coordinates below are zero-based `(column, row)`, starting at the
top-left. Keep map files rectangular, with no spaces, row numbers, or annotations.

The house at columns `18..20`, rows `14..15`, spans 2 rows by 3 columns,
matching the 2×3 block in the legend.

## Legend

| Symbol | Meaning |
| --- | --- |
| `X` | Solid wall; impassable terrain and area boundary. |
| `0` | Area-changing gate (digit zero). Adjacent zeros form one wider entrance. |
| `-` | Empty, walkable ground. |
| `.` | Walkable sand or worn path. Render it distinctly from the normal cave floor (`-`). |
| `h` | A house like those in Cresca, represented by a 2×3 block of `h` tiles. |
| `i` | Torch or other fixed light source. |
| `r` | Solid rock obstacle. Impassable for now; rock breaking is a much later mechanic. |
| `g` | Walkable grass. Grass should cover the lower half of the player's sprite; monster encounters are planned for later. |
| `C` | Solid chest. Currently scenery only; item rewards and interaction are planned for later. |

## Floor layer

Both files share the same 55×55 coordinates. In `r1-floor.txt`, `-` means normal
stone tunnel floor and `.` means sand or worn path. This layer controls ground
textures even beneath rocks, torches, chests, the house, and gates; those objects
do not replace the floor. `X` and the remaining `0` are alignment/reference
markers in the floor draft and resolve to stone ground. Only `r1.txt` determines
walls, collision, grass, and gate connections. Both grids must remain rectangular
and have matching dimensions.

## Route 1 layout

The southern entrance comes from Cresca. The old western road leads north to
Lubia, but rumblings have sealed it. The eastern detour offers supplies and no
onward exit. A narrow, dark crevice off the middle branch is the way forward to
Route 2 and, eventually, the Needle entrance. This is map-design knowledge;
townsfolk do not yet know the Needle is there. See [the story](../../docs/story.md).

| Feature | Tiles / layout |
| --- | --- |
| Return to Cresca | `(26..28, 54)`, southern gate. |
| Road to Lubia | `(26..28, 0)`, northern gate; unreachable initially. |
| Route 2 | `(54, 4)`, eastern gate near the top-right. |
| Main collapse | Rocks seal the western road at columns `2..6`, rows `25..27`; no walkable bypass to Lubia. |
| Lower collapse | The original rock barrier at columns `1..5`, row `41`, remains. The middle branch reaches the old road above it through the existing junction around rows `34..35`. |
| Early cross-link | Rows `48..49` connect the lower middle and western branches; loose rocks can be walked around here. |
| Crevice | A narrow eastward opening off the middle branch. Its winding passage bends north to the Route 2 gate; keep this connection small and easy to overlook. |
| Eastern dead end | Ends at row `27`, roughly halfway up the map, with a chest at `(44, 28)`. It never joins the crevice. |

The western road is lit regularly, including its upper bend toward Lubia, and
its worn surface is marked with `.`. The broader eastern branch is more dimly
lit. The middle branch and crevice are mostly dark. Grass grows in irregular
patches around fields, damp pockets, and bends; scattered rocks leave a route
around them except at the intended collapses. Houses use `h` blocks; optional
side pockets and chambers contain chests.

The chest at `(34, 1)` remains beyond the sealed Lubia road; the chamber at
`(43, 19)` and the chest at `(23, 43)` are also currently sealed off.

Movement between tiles is cardinal; diagonal gaps do not connect paths. Treat
`-`, `.`, and `g` as walkable ground. Houses occupy their marked cells, and both
`X` and `r` block movement. Check that each available
chest has a reachable adjacent approach. From Cresca, the Route 2 gate must be
reachable, the Lubia gate must be unreachable, and closing the crevice entrance
must remove the only route to Route 2.

## Current playable template

Cresca's north gate leads to Route 1 at `(27,53)`. The southern three-tile gate
returns to Cresca at `(29,1)`. Both directions use the mandatory
[screen-changing animation sequence](../../docs/map_layers.md#area-transitions):
close, swap under full black, then play the opposing reveal, with the entire UI
covered and input blocked throughout.

The Lubia and Route 2 openings remain unconnected placeholders. The house is
closed, rocks cannot be broken, chests have no interaction or rewards, and grass
causes no encounters. `X`, `r`, `h`, and `C` block movement; torches cast the same
light as Cresca's. The `h` cells define the solid 3-column, 2-row footprint; a
roof row projects one tile above it using the existing town cottage art.

`route_one_scenery.dart` draws cave-sheet rock walls, pale sand paths, grass, and
the closed chest sprite from the existing castle atlas. Normal `-` ground uses
the shared granite floor. Large, faceted rock sprites use a 16×20 pixel grid with
jagged edges and pointed peaks; stable coordinate-based variants avoid identical
silhouettes. Their peaks extend a quarter tile above their solid one-tile footprint.

Grass is painted on the ground. When the player's destination is `g`, a grass
cover is attached inside the player's moving sprite and hides its lower half.
It remains attached throughout movement between grass cells and is removed on
leaving grass. It is not a fixed overlay on world cells, so vertical movement
cannot expose the legs between tiles. Roofs and lighting still render above it.
