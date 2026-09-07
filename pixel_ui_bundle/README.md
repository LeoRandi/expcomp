# Portable pixel UI bundle

This folder contains copies of the complete original `assets/` directory and
`lib/global_presentation/pixel_ui/` library: tiled panels, sprites, controls,
all five themes, and the interactive showcase. The library depends only on
Flutter. Original asset notes and foundation documentation are included.

## Move into another Flutter project

1. Copy this entire folder wherever you want to keep the transfer bundle.
2. Merge its `assets/` into your destination project's root `assets/` folder and
   its `lib/global_presentation/pixel_ui/` into the same path under that project's
   `lib/`. Review any existing files with matching names before overwriting them.
3. Merge the `flutter:` section from this bundle's `pubspec.yaml` into your
   project's existing section. Keep your project's name, dependencies, and other
   settings. The included manifest registers the assets used by the components;
   additional raw sheets and individual tiles are also copied but need their own
   asset declarations if you use them. Flutter directory entries include only
   files directly within that directory, not all nested directories.
4. Run `flutter pub get` in the destination project. The source project's Dart
   SDK constraint is `^3.9.2`, also retained in the bundle manifest.
5. Import the library using your destination project's package name:

   ```dart
   import 'package:your_project/global_presentation/pixel_ui/pixel_ui.dart';
   ```

This is a source-copy bundle. Merge the files into the application as above;
using this folder directly as a path dependency would require adapting asset
loading to Flutter's package asset namespace. Keep `assets/` at the application
root because the copied components retain their original asset paths.

## Try the showcase

After merging, this minimal `lib/main.dart` example installs the default theme
and displays the included controls and alternative skins:

```dart
import 'package:flutter/material.dart';
import 'global_presentation/pixel_ui/pixel_ui.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
        extensions: <ThemeExtension<dynamic>>[SunderedKeepUi.theme],
      ),
      home: const PixelUiShowcasePage(),
    ),
  );
}
```

The original project's debug showcase route is not copied; this example opens
the page directly. `docs/pixel_ui_foundation.md` is copied reference material
and also describes integrations specific to the original game.

## Verify the bundle

From this folder, run:

```sh
flutter pub get
flutter test
flutter analyze lib test
```

The two existing pixel UI test files are included, with their imports changed
to relative paths so they also work when copied into another project's `test/`.
The assets and library source files are unchanged copies. Asset provenance notes
are preserved in the README files inside `assets/`.
