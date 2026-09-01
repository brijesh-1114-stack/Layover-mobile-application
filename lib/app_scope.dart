import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'presence/presence_service.dart';

/// App wide state and service seams, hosted **above** the Navigator.
///
/// This has to sit above the Navigator, not inside a route. An InheritedWidget
/// placed in a route is not an ancestor of the routes pushed on top of it -
/// they are siblings in the Navigator's overlay - so a `.of(context)` lookup
/// from the second screen of a flow finds nothing and throws. That is exactly
/// what happened to the auth flow: tapping Verify blew up with "Null check
/// operator used on a null value" and the screen simply sat there.
class AppScope extends StatefulWidget {
  const AppScope({
    super.key,
    required this.authService,
    required this.presenceService,
    required this.child,
  });

  final AuthService authService;
  final PresenceService presenceService;
  final Widget child;

  static AppScopeState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScopeMarker>();
    assert(
      scope != null,
      'No AppScope above this widget. It must wrap MaterialApp.',
    );
    return scope!.state;
  }

  @override
  State<AppScope> createState() => AppScopeState();
}

class AppScopeState extends State<AppScope> {
  ProfileDraft _profile = const ProfileDraft();

  AuthService get authService => widget.authService;
  PresenceService get presenceService => widget.presenceService;

  /// The profile being assembled during sign up, and afterwards the one thing
  /// the rest of the app needs from it: a first name to greet with.
  ProfileDraft get profile => _profile;
  String? get name => _profile.name;

  void updateProfile(ProfileDraft draft) => setState(() => _profile = draft);

  @override
  Widget build(BuildContext context) {
    return _AppScopeMarker(state: this, profile: _profile, child: widget.child);
  }
}

class _AppScopeMarker extends InheritedWidget {
  const _AppScopeMarker({
    required this.state,
    required this.profile,
    required super.child,
  });

  final AppScopeState state;

  /// Held separately so [updateShouldNotify] can compare values rather than
  /// the state object, which never changes identity.
  final ProfileDraft profile;

  @override
  bool updateShouldNotify(_AppScopeMarker old) => old.profile != profile;
}
