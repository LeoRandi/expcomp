# expcomp

Flutter tile-based RPG prototype with the Sundered Keep pixel UI. The game opens
in **Cresca**, the protagonist's underground hometown.

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

The provisional world outline is in [docs/story.md](docs/story.md). Town layout,
residents and dialogue live in `lib/exploration/cresca_town.dart`; the original
20×20 testing map remains in `cresca_map.dart`, with its NPCs in `world_map.dart`.

Cresca sits in the middle of a 40×40 cavern, four times the testing area's surface.
Torches stand beside the cobblestone roads. Start outside your
home and speak to the veiled stranger immediately to your right for transport to
the testing grounds. Speak to the Waykeeper there to return home. The original
battle interaction remains with the testing grounds' villager.

Use arrow keys or the direction buttons to move. Walk into an NPC, tap an adjacent
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
