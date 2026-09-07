import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

@immutable
class PixelAtlasRegion {
  const PixelAtlasRegion({
    required this.column,
    required this.row,
    this.widthInTiles = 1,
    this.heightInTiles = 1,
  }) : assert(column >= 0),
       assert(row >= 0),
       assert(widthInTiles > 0),
       assert(heightInTiles > 0);

  final int column;
  final int row;
  final int widthInTiles;
  final int heightInTiles;

  ui.Rect sourceRect(double sourceTileExtent) {
    if (!sourceTileExtent.isFinite || sourceTileExtent <= 0) {
      throw ArgumentError.value(
        sourceTileExtent,
        'sourceTileExtent',
        'Must be finite and greater than zero.',
      );
    }

    return ui.Rect.fromLTWH(
      column * sourceTileExtent,
      row * sourceTileExtent,
      widthInTiles * sourceTileExtent,
      heightInTiles * sourceTileExtent,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PixelAtlasRegion &&
        other.column == column &&
        other.row == row &&
        other.widthInTiles == widthInTiles &&
        other.heightInTiles == heightInTiles;
  }

  @override
  int get hashCode => Object.hash(column, row, widthInTiles, heightInTiles);
}

@immutable
class PixelAtlasDefinition {
  PixelAtlasDefinition({
    required this.assetPath,
    this.sourceTileExtent = 16,
    Map<String, PixelAtlasRegion> regions = const {},
  }) : assert(assetPath.isNotEmpty),
       assert(sourceTileExtent > 0),
       regions = Map.unmodifiable(regions);

  final String assetPath;
  final double sourceTileExtent;
  final Map<String, PixelAtlasRegion> regions;

  PixelAtlasRegion region(String name) {
    final region = regions[name];
    if (region == null) {
      throw ArgumentError.value(
        name,
        'name',
        'No region named "$name" exists in $assetPath.',
      );
    }
    return region;
  }
}

typedef PixelAtlasWidgetBuilder =
    Widget Function(BuildContext context, ui.Image? image, Object? error);

/// Resolves and decodes an atlas once per [AssetBundle] and asset path.
class PixelAtlasBuilder extends StatefulWidget {
  const PixelAtlasBuilder({
    super.key,
    required this.atlas,
    required this.builder,
  });

  final PixelAtlasDefinition atlas;
  final PixelAtlasWidgetBuilder builder;

  @override
  State<PixelAtlasBuilder> createState() => _PixelAtlasBuilderState();
}

class _PixelAtlasBuilderState extends State<PixelAtlasBuilder> {
  AssetBundle? _bundle;
  ui.Image? _image;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (identical(bundle, _bundle)) {
      return;
    }
    _bundle = bundle;
    _resolve(bundle);
  }

  @override
  void didUpdateWidget(covariant PixelAtlasBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.atlas.assetPath != widget.atlas.assetPath) {
      final bundle = _bundle;
      if (bundle != null) {
        _resolve(bundle);
      }
    }
  }

  void _resolve(AssetBundle bundle) {
    final generation = ++_loadGeneration;
    _error = null;
    final cachedImage = PixelAtlasCache.imageFor(
      bundle: bundle,
      assetPath: widget.atlas.assetPath,
    );
    if (cachedImage != null) {
      _image = cachedImage;
      return;
    }

    _image = null;
    _load(bundle, generation);
  }

  Future<void> _load(AssetBundle bundle, int generation) async {
    try {
      final image = await PixelAtlasCache.load(
        bundle: bundle,
        assetPath: widget.atlas.assetPath,
      );
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _image = image;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) {
        return;
      }
      setState(() {
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _image, _error);
  }
}

abstract final class PixelAtlasCache {
  static final Map<AssetBundle, Map<String, Future<ui.Image>>> _images =
      Map.identity();
  static final Map<AssetBundle, Map<String, ui.Image>> _resolvedImages =
      Map.identity();

  static ui.Image? imageFor({
    required AssetBundle bundle,
    required String assetPath,
  }) {
    return _resolvedImages[bundle]?[assetPath];
  }

  static Future<ui.Image> load({
    required AssetBundle bundle,
    required String assetPath,
  }) {
    final bundleImages = _images.putIfAbsent(bundle, () => {});
    return bundleImages.putIfAbsent(assetPath, () async {
      final image = await _decode(bundle, assetPath);
      final resolvedBundleImages = _resolvedImages.putIfAbsent(
        bundle,
        () => {},
      );
      resolvedBundleImages[assetPath] = image;
      return image;
    });
  }

  @visibleForTesting
  static void clear() {
    _images.clear();
    _resolvedImages.clear();
  }

  static Future<ui.Image> _decode(AssetBundle bundle, String assetPath) {
    final completer = Completer<ui.Image>();
    final stream = AssetImage(
      assetPath,
      bundle: bundle,
    ).resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (imageInfo, synchronousCall) {
        if (!completer.isCompleted) {
          completer.complete(imageInfo.image);
        }
        stream.removeListener(listener);
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
        stream.removeListener(listener);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
