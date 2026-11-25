import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Honor the system preference, including screen readers requesting less motion.
bool reduceMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return (media?.disableAnimations ?? false) ||
      (media?.accessibleNavigation ?? false);
}

Duration motionDuration(BuildContext context, int milliseconds) =>
    reduceMotion(context) ? Duration.zero : Duration(milliseconds: milliseconds);

/// Finite entrance animation: no periodic timers and no idle animation loops.
/// Implicit animation state survives rebuilds while the child is being edited.
class MotionReveal extends StatelessWidget {
  const MotionReveal({super.key, required this.child, this.delay = 0});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final reduced = reduceMotion(context);
    final total = 480 + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduced ? 1 : 0, end: 1),
      duration: motionDuration(context, total),
      curve: Interval(delay / total, 1, curve: Curves.easeOutCubic),
      child: child,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 14 * (1 - value)),
          child: Transform.scale(scale: 0.985 + value * 0.015, child: child),
        ),
      ),
    );
  }
}

/// Stagger form fields and actions without replacing controllers or focus nodes.
class MotionColumn extends StatelessWidget {
  const MotionColumn({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++)
            MotionReveal(delay: math.min(i * 38, 250), child: children[i]),
        ],
      );
}
