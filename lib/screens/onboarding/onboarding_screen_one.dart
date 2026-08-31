import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/motion.dart';
import '../../widgets/blur_reveal.dart';
import '../../widgets/page_transitions.dart';
import 'onboarding_screen_two.dart';

/// Onboarding 01 — opens as the splash, then resolves into the welcome screen.
///
/// The wordmark blur-reveals large and centred, holds, then flies up and shrinks
/// into its header slot while the rest of the screen arrives behind it. This is
/// one continuous animation on one screen rather than a splash route handing
/// over to another — a route change in the middle would cut the very motion
/// that ties the two states together.
///
/// Layout is scaled from the 393pt Figma frame width. The vertical
/// relationships that carry the design are pinned to their Figma values; the
/// leftover height falls into a single flexible gap above the copy, where the
/// device's aspect ratio is invisible.
class OnboardingScreenOne extends StatefulWidget {
  const OnboardingScreenOne({super.key});

  @override
  State<OnboardingScreenOne> createState() => _OnboardingScreenOneState();
}

class _OnboardingScreenOneState extends State<OnboardingScreenOne>
    with SingleTickerProviderStateMixin {
  static const double _frameWidth = 393;

  // Figma coordinates: logo at y=62, illustration 150..453, glow frame at 496.
  static const double logoTop = 20;
  static const double logoWidth = 133;
  static const double logoHeight = 32;
  static const double _gapToArt = 56;
  static const double _artWidth = 402;
  static const double _artHeight = 303;

  /// Clear space between the illustration's opaque white base and the glow.
  /// Close this and the illustration's bottom edge cuts a visible seam across
  /// the blue — which is exactly what a derived-from-aspect height did.
  static const double _artToGlow = 43;

  /// The wordmark's splash size, before it settles into the header.
  static const double logoSplashWidth = 240;

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  Animation<double> _on(double begin, double end,
          {Curve curve = Motion.enter}) =>
      CurvedAnimation(
        parent: _entry,
        curve: Interval(begin, end, curve: curve),
      );

  /// Splash: the mark resolves out of blur, then holds while nothing else moves.
  late final Animation<double> _markReveal = _on(0.00, 0.22);

  /// The flight into the header. An in-place curve, not an entrance one — this
  /// is a single object moving, so it eases out of rest and back into it.
  late final Animation<double> _markFlight =
      _on(0.34, 0.60, curve: Motion.inPlace);

  /// Backdrop and artwork arrive underneath the mark as it travels.
  late final Animation<double> _backdrop = _on(0.48, 0.80);

  /// Copy resolves line by line on the shared stagger rhythm.
  late final Animation<double> _headline1 = _on(0.58, 0.80);
  late final Animation<double> _headline2 = _on(0.62, 0.84);
  late final Animation<double> _body1 = _on(0.66, 0.88);
  late final Animation<double> _body2 = _on(0.70, 0.92);

  /// The action always lands last.
  late final Animation<double> _button = _on(0.76, 1.00);

  @override
  void initState() {
    super.initState();
    // On a cold start Flutter paints its first frames into a surface Android
    // has not composited yet — measured on device, an immediate start plays
    // out entirely before anything reaches the screen.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 320));
      if (mounted) _entry.forward();
    });
  }

  @override
  void dispose() {
    _entry.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final s = media.size.width / _frameWidth;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;

    final glowTop = safeTop +
        (logoTop + logoHeight + _gapToArt + _artHeight + _artToGlow) * s;

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          FadeTransition(
            opacity: _backdrop,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [_Glow(scale: s, top: glowTop)],
            ),
          ),

          Column(
            children: [
              SizedBox(height: safeTop + logoTop * s),
              // Reserves the header slot. The live wordmark is painted in the
              // overlay below so it can travel outside this Column's flow.
              SizedBox(width: logoWidth * s, height: logoHeight * s),
              SizedBox(height: _gapToArt * s),
              BlurRevealTransition(
                animation: _backdrop,
                sigma: 0,
                rise: 18 * s,
                // Pinned to the Figma box. Letting the PNG's own aspect ratio
                // decide made it 7pt taller and pushed it into the glow.
                child: SizedBox(
                  width: _artWidth * s,
                  height: _artHeight * s,
                  // The artwork is an opaque white plate, so wherever it ends it
                  // cuts a hard step against the glow behind it. Feathering its
                  // bottom edge to transparent removes the boundary outright,
                  // instead of trying to keep the glow far enough away from it.
                  // Artwork ends at ~93% of the image, so the fade only eats
                  // empty white and the very tail of the ticket's shadow.
                  child: ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (rect) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.white, Colors.white, Colors.transparent],
                      stops: [0.0, 0.84, 1.0],
                    ).createShader(rect),
                    child: Image.asset(
                      'assets/images/onboarding_illustration.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              _Copy(
                scale: s,
                headline1: _headline1,
                headline2: _headline2,
                body1: _body1,
                body2: _body2,
              ),
              SizedBox(height: 40 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20 * s),
                // sigma 0 -> no blur layer at all, just the rise and fade.
                child: BlurRevealTransition(
                  animation: _button,
                  sigma: 0,
                  rise: Motion.surfaceRise * s,
                  child: _GetStartedButton(
                    scale: s,
                    onTap: () => Navigator.of(context).push(
                      FadeThroughRoute<void>(
                        child: const OnboardingScreenTwo(),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: safeBottom > 0 ? safeBottom + 10 * s : 37 * s,
              ),
            ],
          ),

          _FlyingWordmark(
            scale: s,
            safeTop: safeTop,
            viewport: media.size,
            reveal: _markReveal,
            flight: _markFlight,
          ),
        ],
      ),
    );
  }
}

/// The wordmark, painted over the layout so it can travel from the centre of
/// the screen into the header slot without being constrained by the Column.
class _FlyingWordmark extends StatelessWidget {
  const _FlyingWordmark({
    required this.scale,
    required this.safeTop,
    required this.viewport,
    required this.reveal,
    required this.flight,
  });

  final double scale;
  final double safeTop;
  final Size viewport;
  final Animation<double> reveal;
  final Animation<double> flight;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    const ratio = _OnboardingScreenOneState.logoHeight /
        _OnboardingScreenOneState.logoWidth;

    final smallW = _OnboardingScreenOneState.logoWidth * s;
    final smallH = _OnboardingScreenOneState.logoHeight * s;
    final bigW = _OnboardingScreenOneState.logoSplashWidth * s;
    final bigH = bigW * ratio;

    final headerLeft = (viewport.width - smallW) / 2;
    final headerTop = safeTop + _OnboardingScreenOneState.logoTop * s;

    // Sits slightly above true centre — optically centred reads better than
    // mathematically centred for a lone mark.
    final splashLeft = (viewport.width - bigW) / 2;
    final splashTop = viewport.height * 0.44 - bigH / 2;

    return AnimatedBuilder(
      animation: flight,
      builder: (context, _) {
        final t = flight.value;
        final w = lerpDouble(bigW, smallW, t)!;
        final h = lerpDouble(bigH, smallH, t)!;

        return Positioned(
          left: lerpDouble(splashLeft, headerLeft, t)!,
          top: lerpDouble(splashTop, headerTop, t)!,
          width: w,
          height: h,
          child: BlurRevealTransition(
            animation: reveal,
            sigma: 22,
            rise: 10,
            child: SvgPicture.asset(
              'assets/logo/layover_wordmark.svg',
              width: w,
              height: h,
            ),
          ),
        );
      },
    );
  }
}

/// Three overlapping circles under a single layer blur at 90% opacity — the
/// same construction as the Figma frame, not a LinearGradient.
class _Glow extends StatelessWidget {
  const _Glow({required this.scale, required this.top});

  final double scale;
  final double top;

  /// The blur needs room to bleed past the circles, so the painted box is
  /// inflated and the circles shifted to compensate.
  static const double _pad = 140;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final pad = _pad * s;

    return Positioned(
      left: -126 * s - pad,
      top: top - pad,
      width: 646 * s + pad * 2,
      height: 646 * s + pad * 2,
      child: Opacity(
        opacity: 0.9,
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 47 * s, sigmaY: 47 * s),
          child: Stack(
            children: [
              _Circle(size: 646 * s, left: pad, top: pad, color: AppColors.glowOuter),
              _Circle(size: 464 * s, left: 91 * s + pad, top: 91 * s + pad, color: AppColors.glowMid),
              _Circle(size: 347 * s, left: 150 * s + pad, top: 150 * s + pad, color: AppColors.glowCore),
            ],
          ),
        ),
      ),
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

class _Copy extends StatelessWidget {
  const _Copy({
    required this.scale,
    required this.headline1,
    required this.headline2,
    required this.body1,
    required this.body2,
  });

  final double scale;
  final Animation<double> headline1;
  final Animation<double> headline2;
  final Animation<double> body1;
  final Animation<double> body2;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final head = interTight(
      size: 32 * s,
      weight: 600,
      height: 1.2,
      letterSpacing: -0.5 * s,
      color: AppColors.onInk,
    );
    final body = interTight(
      size: 18 * s,
      weight: 400,
      height: 1.2,
      letterSpacing: -0.1 * s,
      color: AppColors.onInk,
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Line(animation: headline1, text: 'Wherever you’re stuck,', style: head),
          _Line(animation: headline2, text: 'you’re not alone.', style: head),
          SizedBox(height: 16 * s),
          _Line(
            animation: body1,
            text: 'Connect with people stuck in the same limbo,',
            style: body,
            sigma: Motion.textSigma - 3,
          ),
          _Line(
            animation: body2,
            text: 'for as long as it lasts.',
            style: body,
            sigma: Motion.textSigma - 3,
          ),
        ],
      ),
    );
  }
}

/// A single line of copy that resolves out of blur on its own timeline.
///
/// The lines are separate widgets rather than one `Text` with a newline so each
/// can carry its own stagger — the reference motion resolves line by line, not
/// as one block.
class _Line extends StatelessWidget {
  const _Line({
    required this.animation,
    required this.text,
    required this.style,
    this.sigma = Motion.textSigma,
  });

  final Animation<double> animation;
  final String text;
  final TextStyle style;
  final double sigma;

  @override
  Widget build(BuildContext context) {
    return BlurRevealTransition(
      animation: animation,
      sigma: sigma,
      // Barely any travel: it should read as coming into focus, not sliding in.
      rise: Motion.textRise,
      child: Text(text, textAlign: TextAlign.center, style: style),
    );
  }
}

class _GetStartedButton extends StatelessWidget {
  const _GetStartedButton({required this.scale, required this.onTap});

  final double scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    // Painted white by the DecoratedBox with the Material kept transparent, so
    // Material 3's elevation tint can never grey the surface.
    return SizedBox(
      height: 54 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get Started',
                  style: interTight(
                    size: 18 * s,
                    weight: 600,
                    height: 1.2,
                    letterSpacing: -0.5 * s,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(width: 12 * s),
                // Exported from Figma: a 40%-opacity shaft plus a solid,
                // curved arrowhead — not a stroked line and chevron.
                SvgPicture.asset(
                  'assets/icons/arrow_right.svg',
                  width: 20 * s,
                  height: 20 * s,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
