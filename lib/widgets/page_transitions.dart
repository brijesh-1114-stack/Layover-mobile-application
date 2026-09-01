import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// A soft fade-and-rise transition used for every push in the onboarding flow.
///
/// Material's default slide is too abrupt for screens whose whole identity is a
/// large soft gradient - the hard horizontal edge fights the artwork. This eases
/// the incoming screen up a short distance while fading, and holds the outgoing
/// one still so the gradients cross-dissolve instead of racing each other.
class FadeThroughRoute<T> extends PageRouteBuilder<T> {
  FadeThroughRoute({required this.child})
    : super(
        transitionDuration: Motion.transition,
        reverseTransitionDuration: Motion.transition,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondary, page) {
          final eased = CurvedAnimation(
            parent: animation,
            curve: Motion.enter,
            reverseCurve: Motion.exit,
          );
          return FadeTransition(
            opacity: eased,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(eased),
              child: page,
            ),
          );
        },
      );

  final Widget child;
}
