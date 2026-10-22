import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Mandatory for every screen/scene change: close, swap under full black, reveal.
/// Use cardinal curtains for crossings and the iris for all other changes.
/// See docs/map_layers.md for the required transition lifecycle.
enum AreaTransitionStyle { north, east, south, west, circle }

const areaTransitionDuration = Duration(milliseconds: 1200);
const _reboundStart = 500 / 1200;
const _reboundEnd = 700 / 1200;

AreaTransitionStyle opposingTransition(AreaTransitionStyle style) =>
    switch (style) {
      AreaTransitionStyle.north => AreaTransitionStyle.south,
      AreaTransitionStyle.east => AreaTransitionStyle.west,
      AreaTransitionStyle.south => AreaTransitionStyle.north,
      AreaTransitionStyle.west => AreaTransitionStyle.east,
      AreaTransitionStyle.circle => AreaTransitionStyle.circle,
    };

double _segment(double begin, double end, double t) {
  // Preserve exact milestone radii despite floating-point division at phase boundaries.
  if (t <= 1e-9) return begin;
  if (t >= 1 - 1e-9) return end;
  return begin + (end - begin) * Curves.easeInOut.transform(t);
}

/// Travel-facing curtain coverage: 0 -> .55 -> .45 -> 1 in .5/.2/.5s.
double curtainCoverage(double progress) {
  final t = progress.clamp(0.0, 1.0);
  if (t <= _reboundStart) return _segment(0, .55, t / _reboundStart);
  if (t <= _reboundEnd) {
    return _segment(
      .55,
      .45,
      (t - _reboundStart) / (_reboundEnd - _reboundStart),
    );
  }
  return _segment(.45, 1, (t - _reboundEnd) / (1 - _reboundEnd));
}

/// The aperture stays centered on the player's actual screen position.
double transitionApertureRadius({
  required Size size,
  required Offset center,
  required double tileExtent,
  required double progress,
}) {
  final farthestX = math.max(center.dx, size.width - center.dx);
  final farthestY = math.max(center.dy, size.height - center.dy);
  final openRadius =
      math.sqrt(farthestX * farthestX + farthestY * farthestY) + 1;
  final t = progress.clamp(0.0, 1.0);
  if (t <= _reboundStart) {
    return _segment(openRadius, 2.5 * tileExtent, t / _reboundStart);
  }
  if (t <= _reboundEnd) {
    return _segment(
      2.5 * tileExtent,
      3.5 * tileExtent,
      (t - _reboundStart) / (_reboundEnd - _reboundStart),
    );
  }
  return _segment(3.5 * tileExtent, 0, (t - _reboundEnd) / (1 - _reboundEnd));
}

class AreaTransitionPainter extends CustomPainter {
  const AreaTransitionPainter({
    required this.style,
    required this.progress,
    required this.playerCenter,
    required this.tileExtent,
  });

  final AreaTransitionStyle style;
  final double progress;
  final Offset playerCenter;
  final double tileExtent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black;
    if (style == AreaTransitionStyle.circle) {
      final radius = transitionApertureRadius(
        size: size,
        center: playerCenter,
        tileExtent: tileExtent,
        progress: progress,
      );
      if (radius <= 0) {
        canvas.drawRect(Offset.zero & size, paint);
      } else {
        final mask = Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addOval(Rect.fromCircle(center: playerCenter, radius: radius));
        canvas.drawPath(mask, paint);
      }
      return;
    }
    final coverage = curtainCoverage(progress);
    final rect = switch (style) {
      AreaTransitionStyle.north => Rect.fromLTWH(
        0,
        size.height * (1 - coverage),
        size.width,
        size.height * coverage,
      ),
      AreaTransitionStyle.south => Rect.fromLTWH(
        0,
        0,
        size.width,
        size.height * coverage,
      ),
      AreaTransitionStyle.east => Rect.fromLTWH(
        0,
        0,
        size.width * coverage,
        size.height,
      ),
      AreaTransitionStyle.west => Rect.fromLTWH(
        size.width * (1 - coverage),
        0,
        size.width * coverage,
        size.height,
      ),
      AreaTransitionStyle.circle => throw StateError('Circle handled above'),
    };
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(AreaTransitionPainter oldDelegate) =>
      style != oldDelegate.style ||
      progress != oldDelegate.progress ||
      playerCenter != oldDelegate.playerCenter ||
      tileExtent != oldDelegate.tileExtent;
}

/// The barrier blocks the entire UI even where the animated mask is still clear.
class AreaTransitionOverlay extends StatelessWidget {
  const AreaTransitionOverlay({
    super.key,
    required this.animation,
    required this.style,
    required this.playerCenter,
    required this.tileExtent,
    this.revealing = false,
  });
  final Animation<double> animation;
  final AreaTransitionStyle style;
  final Offset playerCenter;
  final double tileExtent;
  final bool revealing;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ModalBarrier(
        dismissible: false,
        color: Colors.transparent,
        semanticsLabel: 'Changing area',
        barrierSemanticsDismissible: false,
      ),
      IgnorePointer(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) => CustomPaint(
            key: const ValueKey('area-transition-mask'),
            painter: AreaTransitionPainter(
              style: revealing ? opposingTransition(style) : style,
              progress: revealing ? 1 - animation.value : animation.value,
              playerCenter: playerCenter,
              tileExtent: tileExtent,
            ),
          ),
        ),
      ),
    ],
  );
}
