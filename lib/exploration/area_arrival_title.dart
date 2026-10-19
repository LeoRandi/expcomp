import 'package:flutter/material.dart';

/// One second in total: a short fade at either end and a readable pause.
class AreaArrivalTitle extends StatefulWidget {
  const AreaArrivalTitle({
    super.key,
    required this.name,
    required this.subtitle,
  });

  final String name;
  final String subtitle;

  @override
  State<AreaArrivalTitle> createState() => _AreaArrivalTitleState();
}

class _AreaArrivalTitleState extends State<AreaArrivalTitle>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  late final _opacity = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.0,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 20,
    ),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 20,
    ),
  ]).animate(_controller);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => _controller.isCompleted
        ? const SizedBox.shrink()
        : FadeTransition(
            key: const ValueKey('area-title-fade'),
            opacity: _opacity,
            child: child,
          ),
    child: DecoratedBox(
      key: const ValueKey('area-title-panel'),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.name,
              key: const ValueKey('area-name'),
              style: const TextStyle(
                color: Color(0xFFE5DAC5),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.subtitle,
              style: const TextStyle(color: Color(0xFFC3B79E), fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
