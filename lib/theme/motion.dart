import 'package:flutter/material.dart';

/// The app's single motion vocabulary.
///
/// Every duration and curve in the app comes from here. Screens that each pick
/// their own timings read as unrelated animations even when the shapes match -
/// the rhythm is what makes motion feel like one product rather than several.
class Motion {
  const Motion._();

  // ---------------------------------------------------------------- durations

  /// Label swaps, small state flips.
  static const Duration fast = Duration(milliseconds: 240);

  /// Screen-to-screen transitions.
  static const Duration transition = Duration(milliseconds: 420);

  /// One card of a split-flap board turning over. Slow enough to read as a
  /// physical flap falling, short enough that a minute change does not draw the
  /// eye away from whatever the user was doing.
  static const Duration flap = Duration(milliseconds: 420);

  /// A component changing state in place (a step growing, a chip selecting).
  static const Duration morph = Duration(milliseconds: 560);

  /// A full staggered screen entrance, start of the first element to the end
  /// of the last.
  static const Duration entry = Duration(milliseconds: 1000);

  /// Leaving is quicker than arriving. An exit that takes as long as the
  /// entrance feels like the screen is reluctant to let go.
  static const Duration entryReverse = Duration(milliseconds: 620);

  // ------------------------------------------------------------------- curves

  /// Anything arriving: decelerates into place.
  static const Curve enter = Curves.easeOutCubic;

  /// Anything leaving: accelerates away.
  static const Curve exit = Curves.easeInCubic;

  /// A component changing in place. Material 3's emphasized easing - a weighted
  /// start and a long settle, which reads smoother than a symmetric ease on a
  /// large size change.
  static const Curve inPlace = Curves.easeInOutCubicEmphasized;

  // ------------------------------------------------------- entrance stagger
  //
  // One shared rhythm. Each element starts a beat after the previous and they
  // overlap heavily, so the screen resolves as a wave rather than a queue.

  static const List<Interval> stagger = [
    Interval(0.00, 0.55, curve: enter),
    Interval(0.10, 0.66, curve: enter),
    Interval(0.20, 0.76, curve: enter),
    Interval(0.28, 0.84, curve: enter),
  ];

  /// The primary button always lands last, after the copy has settled.
  static const Interval action = Interval(0.36, 1.00, curve: enter);

  /// A background element that travels a long way needs the whole window.
  static const Interval backdrop = Interval(0.00, 0.90, curve: enter);

  /// The same window on the way out, but accelerating away instead of
  /// decelerating in - replaying the entrance curve backwards makes the exit
  /// crawl at the start and snap at the end.
  static const Interval backdropOut = Interval(0.00, 0.90, curve: exit);

  // -------------------------------------------------------------- reveal feel

  /// Text resolves out of blur with almost no travel - it should read as
  /// coming into focus, not sliding in.
  static const double textSigma = 14;
  static const double textRise = 6;

  /// Solid shapes rise instead of blurring; a blurred button looks like a
  /// rendering fault rather than an effect.
  static const double surfaceRise = 48;

  /// Interval [i] of the shared stagger, clamped to the list length.
  static Interval step(int i) => stagger[i.clamp(0, stagger.length - 1)];
}
