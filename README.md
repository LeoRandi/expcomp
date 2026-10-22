# expcomp

Flutter tile-based RPG prototype with the Sundered Keep pixel UI. The game opens
inside the protagonist's home in **Cresca**, their underground hometown.

```sh
flutter pub get
flutter run
```

Import the controls and all five themes with:

```dart
import 'package:expcomp/global_presentation/pixel_ui/pixel_ui.dart';
```

The library lives in `lib/global_presentation/pixel_ui/`, with its original
asset paths preserved under the root `assets/`. The runtime asset declarations
come from the bundle manifest. Additional raw sheets and nested tile folders
must be declared in `pubspec.yaml` before use.

See [the foundation reference](docs/pixel_ui_foundation.md) for rendering and
component details. Its game-specific item integrations and debug-only route
describe the UI components used by the game.
Asset provenance notes are preserved in the READMEs under `assets/`.

The provisional world outline is in [docs/story.md](docs/story.md). All areas use
[four independent text maps](assets/text-maps/README.md): objects/NPCs, floor,
chests, and gates. Cresca, Cresca interiors, testing, and Route 1 have folders under
`assets/text-maps/`, loaded through one shared parser. NPC legends contain names,
dialogue, sprites, tints, patrols, and actions; gate legends own all travel links.
New players start with an empty inventory.

Cresca sits in the middle of a 55×55 cavern (3,025 tiles).
Torches stand beside the cobblestone roads. Start on the sleeping cushions shared
with your dad in a furnished home with wooden floors. Walk through the front door
to reach the doorstep, then speak to the veiled stranger immediately to your right for transport to
the testing grounds. Speak to the Waykeeper there to return home. The original
battle interaction remains with the testing grounds' villager.

Use arrow keys or the direction buttons to move. Pressing a direction button takes
one step immediately. Hold it for half a second to enable repeated steps every
200 milliseconds (the first extra step is at 0.7 seconds). Releasing or dragging
off the button stops movement, as do menus, dialogue, area changes, and app focus loss.
Walk into an NPC, tap an adjacent
NPC, or press the central Talk button / E / Space to converse. Residents have
one to three dialogue pages. Menus and conversations pause their walking routines.
Area names and subtitles fade in and out over one second on arrival, on a
rounded black panel at 30% opacity.

Unlit roads reach the north, east, and south zone boundaries. Read their roadside
signs for Lubia (crossed out with a warning), Fern, and Furion. Junto's neglected,
fenced farm sits west of town. Signs are solid: bump into one, tap an adjacent
sign, or use E / Space / the interaction button to read it.

```sh
flutter test
flutter analyze lib test
```

Town cottage doors are one movement tile tall. The Resting Lantern inn has
violet timber, a sea-green roof, a striped canopy, and a readable name sign.
The player's home door is interactive: bump it, tap it while adjacent, or use
E / Space / the interaction button to enter. Both directions use circular
transitions. The [interior maps](assets/text-maps/README.md#cresca-interiors)
span 110x110 cells with nine separated 12x12 rooms surrounded by black void;
only the player's home is accessible for now.

Cresca's north road enters Route 1, loaded directly from
[the object map](assets/text-maps/r1/r1-objects.txt) and
[floor layer](assets/text-maps/r1/r1-floor.txt). Its southern gate returns to town.
Travel destinations and arrival coordinates come from
[the gate map](assets/text-maps/r1/r1-gates.txt).
The route includes cave walls, sand paths, grass that covers the player's lower
half throughout movement, a closed cottage, foliage-pack rock sprites, and chests with one-time rewards.
Sand paths continue beneath props and gates. Chest rewards come from
[the numbered chest map](assets/text-maps/r1/r1-chests.txt); opened chests stay empty.
Rocks and the house have no interactions; the other route gates are placeholders.
The east, south, and west town boundaries still wrap to the opposite town edge.
Each crossing has a 1.2-second directional blackout followed by a 1.2-second opposing reveal. The stranger and Waykeeper use a circular close/reopen instead.
The entire screen, including the header and controls, is covered; input and NPC
routines stay paused until the reveal finishes. Arrival titles play afterward.

**Screen-changing animations must ALWAYS play for every screen or scene change.**
Use the shared close/swap-under-black/opposing-reveal sequence for all travel and
gameplay screen changes. See [the mandatory transition rules](docs/map_layers.md#area-transitions).
