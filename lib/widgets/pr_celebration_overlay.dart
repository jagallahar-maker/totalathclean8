import 'package:flutter/material.dart';
import 'dart:math' as math;

/// PR Celebration Overlay Widget
/// Shows a glow animation using the theme's primary accent color
class PrCelebrationOverlay extends StatefulWidget {
  final Color glowColor;
  final VoidCallback? onComplete;

  const PrCelebrationOverlay({
    super.key,
    required this.glowColor,
    this.onComplete,
  });

  @override
  State<PrCelebrationOverlay> createState() => _PrCelebrationOverlayState();
}

class _PrCelebrationOverlayState extends State<PrCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Fade in, hold, fade out
    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.6)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.6),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.6, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);

    // Pulse scale animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.1)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
    ]).animate(_controller);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    widget.glowColor.withOpacity(_opacityAnimation.value * 0.3),
                    widget.glowColor.withOpacity(_opacityAnimation.value * 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.glowColor.withOpacity(_opacityAnimation.value * 0.8),
                          blurRadius: 100 * _scaleAnimation.value,
                          spreadRadius: 30 * _scaleAnimation.value,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Show PR celebration overlay
void showPrCelebration(BuildContext context, Color glowColor) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => PrCelebrationOverlay(
      glowColor: glowColor,
      onComplete: () {
        overlayEntry.remove();
      },
    ),
  );

  overlay.insert(overlayEntry);
}
