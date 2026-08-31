import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/page_transitions.dart';
import 'auth_chrome.dart';

/// Carries the service and the profile being assembled across the flow, so the
/// screens stay stateless about each other.
class AuthFlow extends InheritedWidget {
  const AuthFlow({
    super.key,
    required this.service,
    required this.draft,
    required this.onDraftChanged,
    required super.child,
  });

  final AuthService service;
  final ProfileDraft draft;
  final ValueChanged<ProfileDraft> onDraftChanged;

  static AuthFlow of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthFlow>()!;

  @override
  bool updateShouldNotify(AuthFlow old) => old.draft != draft;
}

/// Root of the auth flow. Owns the draft so every screen can add to it.
class AuthFlowHost extends StatefulWidget {
  const AuthFlowHost({super.key, required this.service});

  final AuthService service;

  @override
  State<AuthFlowHost> createState() => _AuthFlowHostState();
}

class _AuthFlowHostState extends State<AuthFlowHost> {
  ProfileDraft _draft = const ProfileDraft();

  @override
  Widget build(BuildContext context) {
    return AuthFlow(
      service: widget.service,
      draft: _draft,
      onDraftChanged: (d) => setState(() => _draft = d),
      child: const PhoneScreen(),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
      ),
    );
}

// ───────────────────────────── 01 Phone ─────────────────────────────

class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final flow = AuthFlow.of(context);
    final phone = '+91 ${_controller.text}';
    setState(() => _busy = true);
    try {
      await flow.service.requestCode(phone);
      if (!mounted) return;
      Navigator.of(context).push(
        FadeThroughRoute<void>(child: VerifyScreen(phone: phone)),
      );
    } on AuthException catch (e) {
      if (mounted) _snack(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final ready = value.text.replaceAll(RegExp(r'\D'), '').length >= 8;
        return AuthScaffold(
          blueHero: true,
          showBack: false,
          eyebrow: 'Welcome to\nLayover.',
          title: 'What is your number?',
          body: 'We text you a six digit code. New or returning, '
              'this is the only way in.',
          actionLabel: 'Send code',
          busy: _busy,
          onAction: ready ? _send : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 58 * s,
                    padding: EdgeInsets.symmetric(horizontal: 16 * s),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14 * s),
                      border: Border.all(color: AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '+91',
                      style: interTight(
                        size: 17 * s,
                        weight: 600,
                        height: 1.3,
                        letterSpacing: -0.2 * s,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: AuthField(
                      controller: _controller,
                      hint: '98765 43210',
                      keyboardType: TextInputType.phone,
                      maxLength: 12,
                    ),
                  ),
                ],
              ),
              const AuthHelper(
                text: 'Your number is never shown to anyone else.',
                icon: AuthIcons.lock,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────── 02 Verify ─────────────────────────────

class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key, required this.phone});

  final String phone;

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  static const int _length = 6;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _ticker;
  int _secondsLeft = 30;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startCooldown() {
    _ticker?.cancel();
    setState(() => _secondsLeft = 30);
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final flow = AuthFlow.of(context);
    setState(() => _busy = true);
    try {
      final result = await flow.service.verifyCode(
        phone: widget.phone,
        code: _controller.text,
      );
      if (!mounted) return;
      // The branch: the server, not the user, decides which path this is.
      Navigator.of(context).push(
        FadeThroughRoute<void>(
          child: result.profileComplete
              ? const AllSetScreen(returning: true)
              : const NameScreen(),
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        _controller.clear();
        _snack(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final code = value.text;
        return AuthScaffold(
          title: 'Enter the code',
          body: 'Sent to ${widget.phone}',
          actionLabel: 'Verify',
          busy: _busy,
          onAction: code.length == _length ? _verify : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // One real field drives six painted cells; six separate inputs
              // fight each other over focus and paste.
              SizedBox(
                height: 60 * s,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        keyboardType: TextInputType.number,
                        maxLength: _length,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ),
                    GestureDetector(
                      onTap: _focus.requestFocus,
                      child: Row(
                        children: List.generate(_length, (i) {
                          final filled = i < code.length;
                          final focused = i == code.length;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  right: i == _length - 1 ? 0 : 10 * s),
                              child: Container(
                                height: 60 * s,
                                decoration: BoxDecoration(
                                  color: filled
                                      ? AppColors.surface
                                      : AppColors.bgMuted,
                                  borderRadius: BorderRadius.circular(14 * s),
                                  border: Border.all(
                                    color: focused
                                        ? AppColors.accent
                                        : AppColors.border,
                                    width: focused ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: filled
                                    ? Text(
                                        code[i],
                                        style: interTight(
                                          size: 24 * s,
                                          weight: 600,
                                          height: 1.25,
                                          letterSpacing: -0.4 * s,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : focused
                                        ? Container(
                                            width: 2 * s,
                                            height: 26 * s,
                                            color: AppColors.accent,
                                          )
                                        : null,
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 18 * s),
                child: _secondsLeft > 0
                    ? Row(
                        children: [
                          SvgPicture.string(AuthIcons.info,
                              width: 15 * s, height: 15 * s),
                          SizedBox(width: 6 * s),
                          Text(
                            'Resend code in 0:${_secondsLeft.toString().padLeft(2, '0')}',
                            style: interTight(
                              size: 14 * s,
                              weight: 500,
                              height: 1.4,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      )
                    : GestureDetector(
                        onTap: () {
                          AuthFlow.of(context).service.requestCode(widget.phone);
                          _startCooldown();
                          _snack(context, 'New code sent.');
                        },
                        child: Text(
                          'Resend code',
                          style: interTight(
                            size: 14 * s,
                            weight: 600,
                            height: 1.4,
                            color: AppColors.accentStrong,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────── 03 Name ─────────────────────────────

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final ready = value.text.trim().isNotEmpty;
        return AuthScaffold(
          title: 'What should we\ncall you?',
          body: 'Shown on your card while you are checked in. '
              'A first name is plenty.',
          actionLabel: 'Continue',
          onAction: ready
              ? () {
                  final flow = AuthFlow.of(context);
                  flow.onDraftChanged(
                      flow.draft.copyWith(name: value.text.trim()));
                  Navigator.of(context).push(
                    FadeThroughRoute<void>(child: const EmailScreen()),
                  );
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                controller: _controller,
                hint: 'First name',
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
              ),
              const AuthHelper(
                text: 'You can change this any time in Settings.',
                icon: AuthIcons.info,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ───────────────────────────── 04 Email ─────────────────────────────

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(String? email) {
    final flow = AuthFlow.of(context);
    flow.onDraftChanged(flow.draft.copyWith(email: email));
    Navigator.of(context).push(
      FadeThroughRoute<void>(child: const BirthdayScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
        return AuthScaffold(
          title: 'Your email',
          body: 'Only used to reach you about your account. '
              'Never shown to other people.',
          actionLabel: 'Continue',
          onAction: valid ? () => _next(text) : null,
          // Optional on purpose: recovery only. Requiring it would be the
          // biggest drop off point in the flow.
          secondary: TextButton(
            onPressed: () => _next(null),
            child: Text(
              'Skip for now',
              style: interTight(
                size: 15 * s,
                weight: 600,
                height: 1.35,
                letterSpacing: -0.1 * s,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                controller: _controller,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const AuthHelper(
                text: 'We do not send marketing. Account matters only.',
                icon: AuthIcons.lock,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────── 05 Birthday ───────────────────────────

class BirthdayScreen extends StatefulWidget {
  const BirthdayScreen({super.key});

  @override
  State<BirthdayScreen> createState() => _BirthdayScreenState();
}

class _BirthdayScreenState extends State<BirthdayScreen> {
  final _day = TextEditingController();
  final _month = TextEditingController();
  final _year = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _day.dispose();
    _month.dispose();
    _year.dispose();
    super.dispose();
  }

  DateTime? get _date {
    final d = int.tryParse(_day.text);
    final m = int.tryParse(_month.text);
    final y = int.tryParse(_year.text);
    if (d == null || m == null || y == null) return null;
    if (m < 1 || m > 12 || d < 1 || d > 31 || y < 1900) return null;
    final parsed = DateTime(y, m, d);
    return parsed.month == m && parsed.day == d ? parsed : null;
  }

  bool get _isAdult {
    final date = _date;
    if (date == null) return false;
    final now = DateTime.now();
    final eighteenth = DateTime(date.year + 18, date.month, date.day);
    return !eighteenth.isAfter(now);
  }

  Future<void> _finish() async {
    final flow = AuthFlow.of(context);
    final draft = flow.draft.copyWith(birthday: _date);
    setState(() => _busy = true);
    try {
      await flow.service.submitProfile(draft);
      flow.onDraftChanged(draft);
      if (!mounted) return;
      Navigator.of(context).push(
        FadeThroughRoute<void>(child: const AllSetScreen(returning: false)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    final complete = _date != null;

    return AuthScaffold(
      title: 'When were\nyou born?',
      body: 'Layover is for adults only. Your birthday is never shown to anyone.',
      actionLabel: 'Continue',
      busy: _busy,
      onAction: _isAdult ? _finish : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AuthField(
                    controller: _day,
                    hint: 'DD',
                    keyboardType: TextInputType.number,
                    maxLength: 2),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: AuthField(
                    controller: _month,
                    hint: 'MM',
                    keyboardType: TextInputType.number,
                    maxLength: 2),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                flex: 2,
                child: AuthField(
                    controller: _year,
                    hint: 'YYYY',
                    keyboardType: TextInputType.number,
                    maxLength: 4),
              ),
            ],
          ),
          AuthHelper(
            text: complete && !_isAdult
                ? 'You must be 18 or over to use Layover.'
                : 'You must be 18 or over to use Layover.',
            icon: AuthIcons.info,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── 06 All set ───────────────────────────

class AllSetScreen extends StatelessWidget {
  const AllSetScreen({super.key, required this.returning});

  /// A returning account skips the profile screens and lands here directly.
  final bool returning;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    final name = AuthFlow.of(context).draft.name;

    return AuthScaffold(
      blueHero: true,
      showBack: false,
      eyebrow: 'You are in.',
      title: returning
          ? 'Welcome back'
          : (name == null ? 'All set' : 'All set, $name'),
      body: 'Next we find where you are, so you can check in and see '
          'who else is stuck there.',
      actionLabel: 'Turn on location',
      onAction: () => _snack(context, 'Location step comes next.'),
      child: Container(
        width: 56 * s,
        height: 56 * s,
        decoration: const BoxDecoration(
          color: AppColors.accentTint,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(
          '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" '
          'xmlns="http://www.w3.org/2000/svg">'
          '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#0B79F0" stroke-width="2.6" '
          'stroke-linecap="round" stroke-linejoin="round"/></svg>',
          width: 28 * s,
          height: 28 * s,
        ),
      ),
    );
  }
}
