# expcomp

Flutter app with the tile-based pixel UI from `pixel_ui_bundle` integrated as
application source. The app opens the interactive showcase with the default
Sundered Keep theme installed.

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
describe the original game; this app opens the showcase directly as its home.
Asset provenance notes are preserved in the READMEs under `assets/`.

The original transfer bundle remains in `pixel_ui_bundle/`; edit the integrated
files under the application root for further development.

```sh
flutter test
flutter analyze lib test
```
