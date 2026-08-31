import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/motion.dart';
import '../../auth/mock_auth_service.dart';
import '../../widgets/blur_reveal.dart';
import '../../widgets/page_transitions.dart';
import '../auth/auth_flow.dart';

/// One row of the "Three simple steps" list.
class _Step {
  const _Step({required this.icon, required this.title, required this.body});

  final String icon;
  final String title;
  final String body;
}

const _steps = <_Step>[
  _Step(
    icon: 'assets/icons/step_check.svg',
    title: 'Check in',
    body: 'Tell us where you are and how long you’ll be there.',
  ),
  _Step(
    icon: 'assets/icons/step_people.svg',
    title: 'Find people nearby',
    body: 'See others who are stuck in the same place as you.',
  ),
  _Step(
    icon: 'assets/icons/step_wave.svg',
    title: 'Wave & chat',
    body: 'Send a wave. If they wave back, your temporary chat opens.',
  ),
];

/// Onboarding 02 - "Three simple steps to connect."
///
/// The steps advance only when the user taps Next - nothing moves on its own.
/// Figma pins the step group's *bottom* edge at y=717 in all three states, so
/// the list grows upward as a step expands and the button never moves.
class OnboardingScreenTwo extends StatefulWidget {
  const OnboardingScreenTwo({super.key});

  @override
  State<OnboardingScreenTwo> createState() => _OnboardingScreenTwoState();
}

class _OnboardingScreenTwoState extends State<OnboardingScreenTwo>
    with SingleTickerProviderStateMixin {
  static const double _frameWidth = 393;
  static const double _frameHeight = 852;

  static const _morph = Motion.morph;
  static const _curve = Motion.inPlace;

  int _active = 0;
  bool _leaving = false;

  late final AnimationController _entry;
  late final Animation<double> _glowRise;
  late final Animation<double> _eyebrow;
  late final Animation<double> _stepsIn;
  late final Animation<double> _action;

  @override
  void initState() {
    super.initState();

    _entry = AnimationController(
      vsync: this,
      duration: Motion.entry,
      reverseDuration: Motion.entryReverse,
    );

    // The glow travels the full height, so it gets the whole window. The exit
    // needs its own curve: a CurvedAnimation replays `curve` backwards unless
    // given a reverseCurve, which made the descent crawl then snap.
    _glowRise = CurvedAnimation(
      parent: _entry,
      curve: Motion.backdrop,
      reverseCurve: Motion.backdropOut,
    );

    // Same stagger rhythm as screen 01, so the two entrances feel like one
    // animation rather than two unrelated ones.
    _eyebrow = CurvedAnimation(parent: _entry, curve: Motion.step(0));
    _stepsIn = CurvedAnimation(parent: _entry, curve: Motion.step(2));
    _action = CurvedAnimation(parent: _entry, curve: Motion.action);

    // Wait for the first frame so the whole rise is visible, rather than
    // starting under the route transition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entry.forward();
    });
  }

  bool get _onLastStep => _active == _steps.length - 1;

  /// Runs the entry animation backwards before letting the route pop, so the
  /// glow sinks back down instead of vanishing with the page.
  Future<void> _handleBack() async {
    if (_leaving) return;
    _leaving = true;
    await _entry.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_onLastStep) {
      Navigator.of(context).push(
        FadeThroughRoute<void>(
          child: AuthFlowHost(service: MockAuthService()),
        ),
      );
      return;
    }
    setState(() => _active++);
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
    final ctaLabel = _onLastStep ? 'Continue' : 'Next';

    return PopScope(
      // Take the back gesture, play the exit, then pop for real.
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
      // Saturated blue at the top, so the status bar needs light icons - the
      // opposite of screen 01.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Positioned must stay a direct child of the Stack - wrapping it in
            // the AnimatedBuilder silently discarded its coordinates.
            // The blur is rasterised once inside the RepaintBoundary and only
            // translated per frame; re-running a 47px gaussian every frame
            // would drop the animation to a crawl.
            Positioned(
              left: -126 * s - _TopGlow.pad * s,
              top: -323 * s - _TopGlow.pad * s,
              width: 646 * s + _TopGlow.pad * s * 2,
              height: 646 * s + _TopGlow.pad * s * 2,
              child: AnimatedBuilder(
                animation: _glowRise,
                builder: (context, child) {
                  final dy = (1 - _glowRise.value) * media.size.height;
                  return Transform.translate(
                    offset: Offset(0, dy),
                    child: child,
                  );
                },
                child: RepaintBoundary(child: _TopGlow(scale: s)),
              ),
            ),

            Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                  // Eyebrow + Skip
                  Positioned(
                    left: 20 * s,
                    right: 20 * s,
                    top: safeTop + 20 * s,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: BlurRevealTransition(
                            animation: _eyebrow,
                            child: Text(
                              'Three simple steps\nto connect.',
                              style: interTight(
                                size: 20 * s,
                                weight: 500,
                                height: 1.2,
                                letterSpacing: -0.3 * s,
                                color: AppColors.onInk,
                              ),
                            ),
                          ),
                        ),
                        _SkipPill(scale: s),
                      ],
                    ),
                  ),

                  // Step list - bottom pinned, exactly as in Figma
                  Positioned(
                    left: 20 * s,
                    right: 20 * s,
                    bottom: (_frameHeight - 717) * s +
                        (safeBottom > 0 ? safeBottom - 12 * s : 0),
                    child: BlurRevealTransition(
                      animation: _stepsIn,
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < _steps.length; i++) ...[
                          if (i > 0) SizedBox(height: 30 * s),
                          _StepRow(
                            step: _steps[i],
                            active: i == _active,
                            scale: s,
                            duration: _morph,
                            curve: _curve,
                          ),
                        ],
                      ],
                    ),
                    ),
                  ),

                  // Button
                  Positioned(
                    left: 20 * s,
                    right: 20 * s,
                    bottom: safeBottom > 0 ? safeBottom + 10 * s : 37 * s,
                    child: BlurRevealTransition(
                      animation: _action,
                      sigma: 0,
                      rise: Motion.surfaceRise * s,
                      child: _PrimaryButton(
                        scale: s,
                        label: ctaLabel,
                        onTap: _next,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }
}

/// A step that morphs between its inactive and active presentation.
///
/// Driven by one controller. The previous version stacked four independent
/// implicit animations per row, which drifted out of phase, and animated the
/// title's *font size* - re-laying out glyphs every frame and re-measuring the
/// bottom-pinned list with them. That relayout was the jerk.
///
/// Here the title is laid out once at its active size and scaled by transform,
/// and the description collapses with `heightFactor` rather than `AnimatedSize`,
/// so no frame of the morph re-measures text.
class _StepRow extends StatefulWidget {
  const _StepRow({
    required this.step,
    required this.active,
    required this.scale,
    required this.duration,
    required this.curve,
  });

  final _Step step;
  final bool active;
  final double scale;
  final Duration duration;
  final Curve curve;

  @override
  State<_StepRow> createState() => _StepRowState();
}

class _StepRowState extends State<_StepRow>
    with SingleTickerProviderStateMixin {
  static const double _titleActive = 32;
  static const double _titleInactive = 18;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
    value: widget.active ? 1 : 0,
  );

  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: widget.curve,
    reverseCurve: widget.curve,
  );

  @override
  void didUpdateWidget(covariant _StepRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) {
      _controller.animateTo(widget.active ? 1 : 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;

    // Laid out once at the active size; the morph only scales it.
    final titleStyle = interTight(
      size: _titleActive * s,
      weight: 600,
      height: 1.2,
      letterSpacing: -0.3 * s,
      color: AppColors.stepTitleActive,
    );
    final bodyStyle = interTight(
      size: 16 * s,
      weight: 400,
      height: 1.2,
      color: AppColors.stepDescription,
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _t,
        builder: (context, _) {
          final t = _t.value;
          final iconSize = lerpDouble(24, 30, t)! * s;
          final titleColor = Color.lerp(
            AppColors.stepInactive,
            AppColors.stepTitleActive,
            t,
          )!;

          return Opacity(
            opacity: lerpDouble(0.4, 1.0, t)!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  // The row's own height still interpolates, but it is a plain
                  // box - nothing inside it is re-measured.
                  height: lerpDouble(24, 38, t)! * s,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: iconSize,
                        height: iconSize,
                        child: SvgPicture.asset(
                          widget.step.icon,
                          width: iconSize,
                          height: iconSize,
                          colorFilter: ColorFilter.mode(
                            Color.lerp(
                              AppColors.stepInactive,
                              AppColors.stepActive,
                              t,
                            )!,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.scale(
                            scale: lerpDouble(
                              _titleInactive / _titleActive,
                              1,
                              t,
                            )!,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.step.title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              style: titleStyle.copyWith(color: titleColor),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // heightFactor resizes the box without re-measuring the text
                // inside it, unlike AnimatedSize.
                ClipRect(
                  child: Align(
                    alignment: Alignment.topLeft,
                    heightFactor: t,
                    child: Opacity(
                      opacity: t,
                      child: Padding(
                        padding: EdgeInsets.only(top: 12 * s),
                        child: Text(widget.step.body, style: bodyStyle),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Three overlapping circles under one layer blur, anchored above the frame so
/// only their lower edge bleeds into the screen.
class _TopGlow extends StatelessWidget {
  const _TopGlow({required this.scale});

  final double scale;

  /// Slack around the circles so the blur can bleed instead of being clipped.
  static const double pad = 140;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final p = pad * s;

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 47 * s, sigmaY: 47 * s),
      child: Stack(
        children: [
          _Circle(size: 646 * s, left: p, top: p, color: AppColors.glowTopOuter),
          _Circle(size: 464 * s, left: 91 * s + p, top: 91 * s + p, color: AppColors.glowTopMid),
          _Circle(size: 347 * s, left: 150 * s + p, top: 150 * s + p, color: AppColors.glowTopCore),
        ],
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

class _SkipPill extends StatelessWidget {
  const _SkipPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      width: 62 * s,
      height: 37 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () {},
            child: Center(
              child: Text(
                'Skip',
                style: interTight(
                  size: 14 * s,
                  weight: 600,
                  height: 1.2,
                  letterSpacing: -0.5 * s,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.scale,
    required this.label,
    required this.onTap,
  });

  final double scale;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 54 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.ink,
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SizeTransition(
                      axis: Axis.horizontal,
                      sizeFactor: anim,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  ),
                  child: Text(
                    label,
                    key: ValueKey(label),
                    style: interTight(
                      size: 18 * s,
                      weight: 600,
                      height: 1.2,
                      letterSpacing: -0.5 * s,
                      color: AppColors.onInk,
                    ),
                  ),
                ),
                SizedBox(width: 12 * s),
                SvgPicture.asset(
                  'assets/icons/arrow_right.svg',
                  width: 20 * s,
                  height: 20 * s,
                  colorFilter: const ColorFilter.mode(
                    AppColors.onInk,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
