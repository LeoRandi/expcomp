# Four-layer text maps

Each area has four independent maps. These files are the runtime source of truth;
there are no parallel Dart copies of their layouts or NPC dialogue.

| Area | Objects and NPCs | Floor | Chests | Gates |
| --- | --- | --- | --- | --- |
| Cresca (55x55) | [objects](cresca/cresca-objects.txt) | [floor](cresca/cresca-floor.txt) | [chests](cresca/cresca-chests.txt) | [gates](cresca/cresca-gates.txt) |
| Cresca interiors (110x110) | [objects](cresca-indoors/cresca-indoors-objects.txt) | [floor](cresca-indoors/cresca-indoors-floor.txt) | [chests](cresca-indoors/cresca-indoors-chests.txt) | [gates](cresca-indoors/cresca-indoors-gates.txt) |
| Testing grounds (20x20) | [objects](testing/testing-objects.txt) | [floor](testing/testing-floor.txt) | [chests](testing/testing-chests.txt) | [gates](testing/testing-gates.txt) |
| Route 1 (55x55) | [objects](r1/r1-objects.txt) | [floor](r1/r1-floor.txt) | [chests](r1/r1-chests.txt) | [gates](r1/r1-gates.txt) |

One character is one tile. North is up. Coordinates are zero-based `[column, row]`
from the top-left. All four grids in an area must have the same dimensions, with
no spaces, row numbers, or blank lines inside a grid. A blank line followed by
`---` separates an object or gate grid from its JSON legend. Chest definitions
remain the existing plain-text numbered list below the chest grid.

Route 1 uses only the symbols belonging to each layer: no sand markings in its
objects map and no copied walls in its floor, chest, or gate maps. `-` means an
empty object/chest/gate cell, but normal stone ground in the floor map. Walls
belong only in the objects map; floor cells still exist underneath them.

| Layer | Authored symbols and purpose |
| --- | --- |
| Objects / NPCs | `X` walls, `-` no object, and the scenery/NPC symbols below. |
| Floor | `-` stone, `.` sand or worn path, `=` paved road, `W` interior wood, `#` black void. |
| Chests | `-` no chest assignment; `1` to `9` identify chests and their rewards. |
| Gates | `-` no gate; `1` to `9` identify gate regions and their destination legends. |

Numbers are independent between layers: chest `1`, NPC `1`, and gate `1` are
different entries. `C` in the objects map places the chest itself; its matching
number in the chest map assigns its contents. `G` places a closed scenery gate;
numbered gates in the fourth map control area changes.

## Objects and NPCs

Only the objects layer controls walls, scenery, grass, torches, and NPC positions.

| Symbol | Object |
| --- | --- |
| `X` | Solid cave wall. |
| `#` | Solid empty void outside interior rooms; use `#` in the floor map too for pure black with no ground or light spill. |
| `x` | Solid indoor masonry wall. Lowercase `x` differs from cave wall `X`. |
| `-` | No object; the floor layer is visible. |
| `.` | Accepted for older drafts as an empty marker; use `-` in new object maps. Sand belongs only in the floor map. |
| `i` | Torch and fixed light source. |
| `h` | House footprint, 2 rows by 3 columns. The roof projects one row above it. |
| `g` | Walkable grass. The player's attached cover hides its lower half while moving through it. |
| `r` | Solid rock, using the existing foliage-pack sprites; cannot be broken. |
| `C` | Solid chest; its identity and reward come from the chest layer. |
| `1` to `9` | NPC numbers, each occupying exactly one cell. |
| `f` | Fungus. |
| `u` | Rubble. |
| `v` | Flowers. |
| `c` | Crates. |
| `b` | Bench. |
| `w` | Well. |
| `s` | Market stall. |
| `p` | Garden. |
| `F` | Fence. |
| `G` | Closed farm gate (scenery, not an area transition). |
| `S` | Readable sign. |
| `T` | Solid wooden dining table. |
| `t` | Chair; distinct from uppercase `T`. Cresca interiors set `solid: false` in each chair's prop entry so the player can walk over it. |
| `k` | Walkable sleeping cushions, drawn beneath the player. |
| `R` | Walkable woven rug, drawn beneath actors. |
| `B` | Solid bookcase; distinct from lowercase `b` (bench). |
| `D` | Wooden doorway. Walkable by default for an exit gate; set `solid: true` for a closed, unconnected door. |

The JSON legend below the grid contains:

- `area`: `town`, `testing`, `routeOne`, or `crescaIndoors`; `name`, `subtitle`, and `spawn`.
- `light radius`: a positive number of tiles controlling the player's circular
  light, independently of torches. It is the outer reach: the inner half is
  fully lit; the next bands fade through 50%, 75%, and 90% darkness before
  reaching black at the radius. All bands scale with this setting. The default
  when omitted is `6`, preserving the original lighting. Cresca and testing
  explicitly use `6`, Route 1 uses `2`, and interiors use `100` to light the
  whole room. Black `#` void remains fully black regardless of the radius.
  For example, put `"light radius": 2,` alongside `"spawn"` in the JSON legend.
- `npcs`: entries keyed by their grid number, with `id`, `name`, `role`, `sprite`,
  `lines` (dialogue pages), `route` (patrol coordinates), optional `tint` (AARRGGBB),
  and `action` (`talk`, `battle`, or `travel`). A travel NPC's `gate` is the number
  of an interaction gate in the fourth map. NPCs use legend order for interaction
  priority; patrols retain their authored order.
- `buildings`: entries keyed by the footprint's top-left coordinate, such as
  `"19,23"`, with a stable `id` and `appearance` (`cottage` or `inn`).
- `props`: optional entries keyed by coordinate, containing `label`, `solid`, and
  `lines` for signs. Flowers and gardens default to walkable; other props default
  to solid, except cushions, rugs, and doorways, which are also walkable.
  Explicit `solid` values override those defaults.

The full existing NPC names, dialogue, sprites, tints, actions, and patrol routes
are stored in the Cresca and testing object legends. Route 1 currently has no NPCs.
Dialogue follows [the provisional story](../../docs/story.md).

## Floor

| Symbol | Ground |
| --- | --- |
| `-` | Normal granite tunnel floor. |
| `.` | Sand or worn path. |
| `=` | Paved road: cobblestone in Cresca, the original road art in testing. |
| `W` | Wooden floor in the interior map, including beneath furniture and walls; distinct from object `w` (well). |
| `#` | No ground: opaque black void. Impassable and always black, even near a torch or the player. |
| `X`, `0` | Accepted for older drafts as alignment markers; resolve to granite. Use `-` instead when authoring floor maps. |

Floor cells render beneath rocks, chests, torches, houses, and gates. They never
change collision except for `#`, which makes empty void impassable. For example,
a `.` beneath an `r` continues the sandy path under
that rock. Grass from the object map renders above its underlying floor.

## Chests

A chest's unique number sits at exactly its `C` coordinate in the object grid.
Use `-` for unassigned cells. Older `X` wall-alignment markers are still accepted,
but do not add collision. Below the grid, assign one definition per number:

```text
1: None
2: Meat x 2
3: Necklace item
```

Amounts default to one. Catalog IDs and display names are accepted; `Necklace item`
is the existing Moonless necklace. Route 1 has Meat x2 in chest 2 and Moonless
necklace x1 in chest 3; the other six are empty. Cresca and testing currently have
empty chest maps, ready for future additions.

Bump a chest, tap it from an adjacent tile, or use the interaction button / E /
Space. The first interaction opens its sprite and grants its contents once,
showing `You got a <item name> x <amount>`. Empty and already opened chests show
`It's empty...`. Opened IDs, such as `r1:2`, belong to the Player and survive
travel and exploration recreation with the same Player. A new Player starts with
an empty inventory and unopened chests; there is no disk-save system yet.

## Gates

Use `1` to `9` to mark each gate. Repeated cells of the same number form one filled
rectangle, allowing a two- or three-tile entrance. `-` is unassigned; older `X`
wall-alignment markers are accepted but do not add collision. The gate legend is
JSON keyed by gate number:

```json
{
  "1": {
    "id": "north",
    "destination": "routeOne",
    "arrival": [27, 53],
    "style": "north",
    "mode": "walk"
  }
}
```

- `destination` is the target area's ID: `town` (Cresca), `testing`, `routeOne`, or `crescaIndoors`.
- `arrival` is the destination's `[column, row]`.
- `style` is `north`, `east`, `south`, `west`, or `circle`.
- `mode: "walk"` triggers when entering the marked cells.
- `mode: "interact"` is invoked by a travel NPC referencing this gate's number;
  it does not trigger just by walking over the cell.
- `mode: "door"` adds an adjacent door interaction: tap the doorway, bump into it,
  or use the interaction button / E / Space. The gate can overlap a solid house
  footprint, so its `h` cells and collision stay intact. It does not need an NPC.
- `enabled: false` documents a future gate without activating it. Route 1's Lubia
  and Route 2 exits use this, with their future destination names in the legend.

Cresca's gate 5 belongs to the Veiled Stranger and leads to testing. Testing's
interaction gate 1 belongs to the Waykeeper and returns to Cresca. Route 1 gate 1
returns south to Cresca; gates 2 and 3 document Lubia and Route 2. Boundary wraps,
NPC teleports, destinations, arrival coordinates, and transition styles are all
configured in these gate files.

## Cresca interiors

The four `cresca-indoors` maps are 110x110: twice Cresca's width and height.
Nine rooms each enclose a 12x12 floor, with 21 empty tiles between their outer
walls. Each has cushions, tables, chairs, rugs, storage, and torches. Black `#`
surrounds them; other homes remain out of sight and cannot be reached on foot.
Only the player's home is connected; the other eight doors are solid placeholders.
Its objects legend sets `"light radius": 100` so the whole home stays lit.
Indoor crates, flowers, benches, doors, wood, and walls use existing imported
assets. Tables, chairs, cushions, rugs, and bookcases have plain squares labeled
with their names until suitable sprites are available. Labels also have
screen-reader semantics. Chair walkability comes from the map's explicit
`solid: false` entries, while tables and bookcases remain solid.

The new-game spawn is `[16,16]`, on cushions in the northwest corner beside the
father's sleeping cushions. The first room's walls span `[14,14]` to `[27,27]`.
Interior walk gate `1` at `[20,27]` leads to Cresca `[20,25]`, directly outside
the player's house. Cresca door gate `6` at `[20,24]` returns to interior
`[20,26]`, inside the door and clear of the exit trigger. Both links use `circle`
and the mandatory full cover/swap/reveal sequence. Add future home connections
in the gate maps without adding travel coordinates to Dart code.

**Every active gate must ALWAYS use the full screen-changing animation:** close,
swap only under full black, then play the opposing reveal. The mask covers all UI
and blocks input throughout. See [the transition rules](../../docs/map_layers.md#area-transitions).

## Shared implementation

`world_maps.dart` supplies the folder/prefix catalog and caches loaded maps.
`text_map_loader.dart` reads and validates all four layer types for every area.
It checks dimensions, NPC and gate legends, house footprints, chest coordinates
and rewards, and walkable spawns/NPCs/active walk gates. `world_map.dart` stores the
parsed data; rendering and interaction use it without area-specific layout logic.
The older Cresca/testing accessors and `route_one.dart` are thin compatibility
wrappers over this shared data, not separate layouts or parsers.
