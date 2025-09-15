import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PageTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const PageTransition({
    super.key,
    required this.child,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Animate(
      effects: [
        ScaleEffect(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: 300.ms,
          curve: Curves.easeOutQuart,
        ),
        FadeEffect(
          begin: 0.0,
          end: 1.0,
          duration: 300.ms,
          curve: Curves.easeOutQuart,
        ),
      ],
      child: child,
    );
  }
}
