import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Separate pulses keep the lunge and delayed recoil independent.
class CombatantMotion extends StatefulWidget {
  const CombatantMotion({
    super.key,
    required this.actionPulse,
    required this.hitPulse,
    required this.allied,
    required this.child,
  });
  final int actionPulse;
  final int hitPulse;
  final bool allied;
  final Widget child;
  @override
  State<CombatantMotion> createState() => _CombatantMotionState();
}

class _CombatantMotionState extends State<CombatantMotion>
    with TickerProviderStateMixin {
  late final _action = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final _hit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  @override
  void didUpdateWidget(CombatantMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.actionPulse > 0 && widget.actionPulse != oldWidget.actionPulse) {
      _action.forward(from: 0);
    }
    if (widget.hitPulse > 0 && widget.hitPulse != oldWidget.hitPulse) {
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _action.dispose();
    _hit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([_action, _hit]),
    child: widget.child,
    builder: (context, child) {
      final lunge =
          math.sin(_action.value * math.pi) * 10 * (widget.allied ? -1 : 1);
      final recoil = math.sin(_hit.value * math.pi * 4) * (1 - _hit.value) * 8;
      return Transform.translate(offset: Offset(recoil, lunge), child: child);
    },
  );
}
