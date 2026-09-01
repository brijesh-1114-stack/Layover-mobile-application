import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The blue hero used at the top of every "welcome" style screen.
///
/// Three overlapping circles under a single layer blur, anchored above the
/// frame so only their lower edge bleeds down into the page. A LinearGradient
/// cannot stand in for this: a gradient fades along one axis and reads as a
/// flat band, while the circles fall off radially and keep a bright core, which
/// is what makes the top of the screen look lit rather than painted.
class TopGlow extends StatelessWidget {
  const TopGlow({super.key, required this.scale});

  /// Layout scale, the same `width / 393` factor every screen uses.
  final double scale;

  /// Slack around the circles so the blur bleeds instead of clipping against
  /// the layer edge.
  static const double pad = 140;

  /// Nominal size of the glow box, before [pad] is added on each side.
  static const double box = 646;

  /// Where the glow sits relative to the screen's top-left corner.
  static const Offset anchor = Offset(-126, -323);

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final p = pad * s;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 47 * s, sigmaY: 47 * s),
      child: Stack(
        children: [
          _Circle(
            size: 646 * s,
            left: p,
            top: p,
            color: AppColors.glowTopOuter,
          ),
          _Circle(
            size: 464 * s,
            left: 91 * s + p,
            top: 91 * s + p,
            color: AppColors.glowTopMid,
          ),
          _Circle(
            size: 347 * s,
            left: 150 * s + p,
            top: 150 * s + p,
            color: AppColors.glowTopCore,
          ),
        ],
      ),
    );
  }
}

/// [TopGlow] already positioned for a full-bleed screen hero.
///
/// Wrapped in a RepaintBoundary because the blur is expensive to rasterise and
/// nothing above it animates - without the boundary every countdown tick would
/// redraw the glow.
class TopGlowHero extends StatelessWidget {
  const TopGlowHero({super.key, required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    const pad = TopGlow.pad;
    return Positioned(
      left: TopGlow.anchor.dx * s - pad * s,
      top: TopGlow.anchor.dy * s - pad * s,
      width: TopGlow.box * s + pad * s * 2,
      height: TopGlow.box * s + pad * s * 2,
      child: RepaintBoundary(child: TopGlow(scale: s)),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({
    required this.size,
    required this.left,
    required this.top,
    required this.color,
  });

  final double size;
  final double left;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
