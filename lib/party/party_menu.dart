import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../creatures/creature.dart';
import '../creatures/showcase_party.dart';
import '../global_presentation/pixel_ui/pixel_ui.dart';
import 'creature_source_theme.dart';
import 'creature_info_page.dart';

class PartyMenu extends StatelessWidget {
  const PartyMenu({super.key, required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey('party-menu'),
    color: Colors.transparent,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Expanded(
            child: PixelPanel.expanded(
              tileExtent: PixelUiMetrics.largeBorder,
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final rowHeight = math.max(
                    112.0,
                    (constraints.maxHeight - 40) / 6,
                  );
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: 6,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) => SizedBox(
                      height: rowHeight,
                      child: index < showcaseParty.length
                          ? _PartySlot(creature: showcaseParty[index])
                          : Semantics(
                              label: 'Empty party slot ${index + 1}',
                              enabled: false,
                              // Bound each filter to its own slot. A saturation
                              // blend can flood the viewport on mobile renderers.
                              child: ClipRect(
                                child: ColorFiltered(
                                  colorFilter: const ColorFilter.matrix([
                                    .1063,
                                    .3576,
                                    .0361,
                                    0,
                                    0,
                                    .1063,
                                    .3576,
                                    .0361,
                                    0,
                                    0,
                                    .1063,
                                    .3576,
                                    .0361,
                                    0,
                                    0,
                                    0,
                                    0,
                                    0,
                                    1,
                                    0,
                                  ]),
                                  child: PixelPanel.expanded(
                                    key: ValueKey('empty-party-slot-$index'),
                                    role: PixelSurfaceRole.inset,
                                    tileExtent: 8,
                                    child: const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            width: double.infinity,
            child: PixelButton(
              key: const ValueKey('close-party'),
              label: 'BACK',
              expandToFill: true,
              onPressed: onClose,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PartySlot extends StatefulWidget {
  const _PartySlot({required this.creature});
  final Creature creature;
  @override
  State<_PartySlot> createState() => _PartySlotState();
}

class _PartySlotState extends State<_PartySlot> {
  Creature get creature => widget.creature;
  @override
  Widget build(BuildContext context) {
    final sourceTheme = themeForSource(
      creature.source,
    ).copyWith(tileExtent: PixelUiMetrics.largeBorder);
    return Theme(
      data: Theme.of(context).copyWith(extensions: [sourceTheme]),
      child: Builder(
        builder: (context) => PixelPanel.expanded(
          key: ValueKey('party-${creature.id}'),
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final portraitSize = math.min(
                constraints.maxHeight,
                constraints.maxWidth * .22,
              );
              return Row(
                children: [
                  SizedBox(
                    width: portraitSize,
                    height: portraitSize,
                    child: CustomPaint(
                      foregroundPainter: _PortraitOutline(),
                      child: ClipPath(
                        clipper: _PortraitClipper(),
                        child: ColoredBox(
                          color: sourceTheme.palette.canvas,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: PixelAssetSprite(
                              assetPath: creature.species.frontAsset,
                              semanticLabel: creature.species.name,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          creature.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: sourceTheme.palette.ink,
                            fontSize: PixelUiMetrics.title,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 32,
                          child: PixelResourceBar.expanded(
                            value: creature.currentHp.toDouble(),
                            maximum: creature.maxHp.toDouble(),
                            showValues: false,
                            tileExtent: PixelUiMetrics.mediumBorder,
                            semanticLabel: '${creature.name} HP',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: PixelButton(
                      key: ValueKey('details-${creature.id}'),
                      label: '...',
                      tileExtent: PixelUiMetrics.mediumBorder,
                      role: PixelSurfaceRole.inset,
                      semanticLabel: 'Open creature details',
                      expandToFill: true,
                      onPressed: () async {
                        await showGeneralDialog<bool>(
                          context: context,
                          barrierColor: Colors.transparent,
                          pageBuilder: (context, _, _) => SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 88),
                              child: CreatureInfoPage(creature: creature),
                            ),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

Path _portraitPath(Size size) => Path()
  ..addPolygon([
    Offset(size.width / 2, 0),
    Offset(size.width, size.height * .25),
    Offset(size.width, size.height * .75),
    Offset(size.width / 2, size.height),
    Offset(0, size.height * .75),
    Offset(0, size.height * .25),
  ], true);

class _PortraitClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => _portraitPath(size);
  @override
  bool shouldReclip(_PortraitClipper oldClipper) => false;
}

class _PortraitOutline extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    _portraitPath(size),
    Paint()
      ..color = const Color(0xFFAA8C59)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2,
  );
  @override
  bool shouldRepaint(_PortraitOutline oldDelegate) => false;
}
