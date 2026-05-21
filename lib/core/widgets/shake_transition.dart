import 'dart:math' as math;
import 'package:flutter/material.dart';

class ShakeTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double offset;
  final int shakes;

  const ShakeTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 10.0,
    this.shakes = 4,
  });

  @override
  State<ShakeTransition> createState() => ShakeTransitionState();
}

class ShakeTransitionState extends State<ShakeTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void shake() {
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // We'll use a sequence or simple sine curve
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double progress = _controller.value;
        if (progress == 0) return child!;

        // Simple shake math: sin(progress * shakes * 2pi) * offset
        // As progress goes from 0 to 1, we want it to shake and then settle.
        final double sineValue = math.sin(progress * widget.shakes * 2 * math.pi);
        
        return Transform.translate(
          offset: Offset(widget.offset * (1 - progress) * sineValue, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
