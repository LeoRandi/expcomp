import 'package:flutter/material.dart';

/// A pixel-aligned underline that leaves the sprite's layout unchanged.
class ActiveAllyBorder extends StatefulWidget {
  const ActiveAllyBorder({
    super.key,
    required this.color,
    this.semanticLabel = 'Choosing this creature?s move',
  });
  final Color color;
  final String semanticLabel;
  @override
  State<ActiveAllyBorder> createState() => _ActiveAllyBorderState();
}

class _ActiveAllyBorderState extends State<ActiveAllyBorder>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final _opacity = Tween<double>(
    begin: .3,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Choosing this creature’s move',
    child: Center(
      child: FractionallySizedBox(
        widthFactor: .65,
        child: FadeTransition(
          opacity: _opacity,
          child: SizedBox(height: 4, child: ColoredBox(color: widget.color)),
        ),
      ),
    ),
  );
}
