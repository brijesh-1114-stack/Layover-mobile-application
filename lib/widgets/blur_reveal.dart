import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Reveal defaults, delegated to the app's motion vocabulary so a reveal here
/// resolves at the same rate as every other arriving element.
class BlurRevealSpec {
  const BlurRevealSpec._();

  static const double sigma = Motion.textSigma;
  static const double rise = Motion.textRise;
  static const Duration duration = Motion.morph;
  static const Curve curve = Motion.enter;
}

/// Paints [child] blurred and offset, resolving to sharp as [t] goes 0 -> 1.
///
/// The blur is dropped entirely below a threshold: a sigma of ~0 still forces
/// Flutter to allocate and composite a filter layer every frame, which is
/// wasted work once the text is visually sharp.
class _BlurRevealPainter extends StatelessWidget {
  const _BlurRevealPainter({
    required this.t,
    required this.sigma,
    required this.rise,
    required this.child,
  });

  final double t;
  final double sigma;
  final double rise;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final clamped = t.clamp(0.0, 1.0);
    final blur = sigma * (1 - clamped);

    Widget content = child;
    if (blur > 0.25) {
      content = ImageFiltered(
        // decal stops the blur smearing against the layer edge, which reads as
        // a grey halo around the text on a light background.
        imageFilter: ImageFilter.blur(
          sigmaX: blur,
          sigmaY: blur,
          tileMode: TileMode.decal,
        ),
        child: content,
      );
    }

    return Opacity(
      opacity: clamped,
      child: Transform.translate(
        offset: Offset(0, rise * (1 - clamped)),
        child: content,
      ),
    );
  }
}

/// Blur reveal driven by an external animation - used for entry sequences
/// where several elements resolve against one shared timeline.
class BlurRevealTransition extends StatelessWidget {
  const BlurRevealTransition({
    super.key,
    required this.animation,
    required this.child,
    this.sigma = BlurRevealSpec.sigma,
    this.rise = BlurRevealSpec.rise,
  });

  final Animation<double> animation;
  final Widget child;
  final double sigma;
  final double rise;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) => _BlurRevealPainter(
        t: animation.value,
        sigma: sigma,
        rise: rise,
        child: inner!,
      ),
      child: child,
    );
  }
}

/// Blur reveal that replays whenever [revealed] flips to true.
///
/// While not revealed the child renders sharp and untouched - an inactive step
/// should look settled, not permanently out of focus.
class BlurRevealOnActivate extends StatefulWidget {
  const BlurRevealOnActivate({
    super.key,
    required this.revealed,
    required this.child,
    this.sigma = BlurRevealSpec.sigma,
    this.rise = BlurRevealSpec.rise,
    this.duration = BlurRevealSpec.duration,
  });

  final bool revealed;
  final Widget child;
  final double sigma;
  final double rise;
  final Duration duration;

  @override
  State<BlurRevealOnActivate> createState() => _BlurRevealOnActivateState();
}

class _BlurRevealOnActivateState extends State<BlurRevealOnActivate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.revealed ? 1 : 1,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: BlurRevealSpec.curve,
  );

  @override
  void didUpdateWidget(covariant BlurRevealOnActivate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revealed && !oldWidget.revealed) {
      _controller.forward(from: 0);
    } else if (!widget.revealed && oldWidget.revealed) {
      // Settle instantly rather than blurring back out - only the arriving
      // step should draw attention.
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, inner) => _BlurRevealPainter(
        t: _t.value,
        sigma: widget.sigma,
        rise: widget.rise,
        child: inner!,
      ),
      child: widget.child,
    );
  }
}
