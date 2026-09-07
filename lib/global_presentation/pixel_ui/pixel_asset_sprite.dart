import 'package:flutter/material.dart';

/// Renders a standalone pixel-art asset without interpolation.
///
/// Prefer [PixelSprite] for regions that have already been packed into an
/// atlas. This widget keeps curated, standalone character frames usable while
/// they are waiting to be packed.
class PixelAssetSprite extends StatelessWidget {
  const PixelAssetSprite({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.flipHorizontally = false,
    this.flipVertically = false,
    this.opacity = 1,
    this.tint,
    this.tintBlendMode = BlendMode.srcATop,
    this.semanticLabel,
    this.placeholder = const SizedBox.shrink(),
  }) : assert(assetPath.length > 0),
       assert(width == null || width > 0),
       assert(height == null || height > 0),
       assert(opacity >= 0 && opacity <= 1);

  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool flipHorizontally;
  final bool flipVertically;
  final double opacity;
  final Color? tint;
  final BlendMode tintBlendMode;
  final String? semanticLabel;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      color: tint,
      colorBlendMode: tint == null ? null : tintBlendMode,
      opacity: AlwaysStoppedAnimation(opacity),
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );

    if (flipHorizontally || flipVertically) {
      image = Transform(
        alignment: Alignment.center,
        transform: Matrix4.diagonal3Values(
          flipHorizontally ? -1 : 1,
          flipVertically ? -1 : 1,
          1,
        ),
        child: image,
      );
    }
    return image;
  }
}
