import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

import '../../app_scope.dart';
import '../../auth/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/motion.dart';
import '../../widgets/page_transitions.dart';
import '../location/location_flow.dart';
import '../../widgets/country_sheet.dart';
import '../../widgets/flow_scaffold.dart';

/// Entry point for the auth flow.
///
/// Deliberately thin: the service and the draft live in [AppScope], above the
/// Navigator, because an InheritedWidget hosted here would be invisible to
/// every screen this one pushes.
class AuthFlowHost extends StatelessWidget {
  const AuthFlowHost({super.key});

  @override
  Widget build(BuildContext context) => const PhoneScreen();
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

  /// India is the default because that is where the app is being trialled, not
  /// because the field assumes it - every country in the list is reachable in
  /// two taps.
  Country _country = CountryService().findByCode('IN')!;

  /// Set when the backend rejects the number, cleared as soon as the user edits
  /// it. An error that outlives the thing it is complaining about is worse than
  /// no error at all.
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _digits => _controller.text.replaceAll(RegExp(r'\D'), '');

  /// Real per-country validation rather than a hardcoded length. A ten digit
  /// rule is right for +91 and wrong for most of the list.
  bool get _isValid {
    if (_digits.isEmpty) return false;
    try {
      final parsed = PhoneNumber.parse(
        _digits,
        destinationCountry: IsoCode.values.byName(_country.countryCode),
      );
      return parsed.isValid(type: PhoneNumberType.mobile);
    } catch (_) {
      return false;
    }
  }

  Future<void> _pickCountry() async {
    final picked = await showCountrySheet(context: context, selected: _country);
    if (picked == null || !mounted) return;
    setState(() {
      _country = picked;
      _error = null;
    });
  }

  Future<void> _send() async {
    final flow = AppScope.of(context);
    final phone = '+${_country.phoneCode} $_digits';
    setState(() => _busy = true);
    try {
      await flow.authService.requestCode(phone);
      if (!mounted) return;
      Navigator.of(context)
          .push(FadeThroughRoute<void>(child: VerifyScreen(phone: phone)));
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / FlowScaffold.frameWidth;
    final hasError = _error != null;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        return FlowScaffold(
          blueHero: true,
          showBack: false,
          eyebrow: 'Welcome to\nLayover.',
          title: 'What is your number?',
          body:
              'We text you a six digit code. New or returning, '
              'this is the only way in.',
          actionLabel: 'Send code',
          busy: _busy,
          onAction: _isValid ? _send : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _DialCodeButton(
                    country: _country,
                    hasError: hasError,
                    onTap: _busy ? null : _pickCountry,
                    scale: s,
                  ),
                  SizedBox(width: 10 * s),
                  Expanded(
                    child: FlowField(
                      controller: _controller,
                      hint: _country.example.isEmpty
                          ? 'Phone number'
                          : _country.example,
                      keyboardType: TextInputType.phone,
                      hasError: hasError,
                      // A generous cap: the field is validated per country, and
                      // a hard length here would truncate legitimate numbers in
                      // the countries that run longer than +91 does.
                      maxLength: 15,
                    ),
                  ),
                ],
              ),
              FlowHelper(
                text: _error ?? 'Your number is never shown to anyone else.',
                isError: hasError,
                icon: FlowIcons.lock,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The dial code chip. Tapping it opens the country sheet, so it has to look
/// pressable - a bare box reads as a label and never gets tapped.
class _DialCodeButton extends StatelessWidget {
  const _DialCodeButton({
    required this.country,
    required this.hasError,
    required this.onTap,
    required this.scale,
  });

  final Country country;
  final bool hasError;
  final VoidCallback? onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Material(
      color: hasError ? AppColors.errorBg : AppColors.surface,
      borderRadius: BorderRadius.circular(14 * s),
      child: InkWell(
        borderRadius: BorderRadius.circular(14 * s),
        onTap: onTap,
        child: Container(
          height: 58 * s,
          padding: EdgeInsets.symmetric(horizontal: 14 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(
              color: hasError ? AppColors.errorBorder : AppColors.border,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country.flagEmoji, style: TextStyle(fontSize: 18 * s)),
              SizedBox(width: 8 * s),
              Text(
                '+${country.phoneCode}',
                style: interTight(
                  size: 17 * s,
                  weight: 600,
                  height: 1.3,
                  letterSpacing: -0.2 * s,
                  color: hasError ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 6 * s),
              SvgPicture.string(
                '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" '
                'xmlns="http://www.w3.org/2000/svg"><path d="M6 9l6 6 6-6" '
                'stroke="#667085" stroke-width="2.2" stroke-linecap="round" '
                'stroke-linejoin="round"/></svg>',
                width: 14 * s,
                height: 14 * s,
              ),
            ],
          ),
        ),
      ),
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

  /// A rejected code is not a passing notification - it is the state of the
  /// screen until the user types a different one, so it lives here and paints
  /// the cells rather than flashing past in a snackbar.
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
    _controller.addListener(() {
      if (_error != null) setState(() => _error = null);
    });
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
    final flow = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final result = await flow.authService.verifyCode(
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
      // The digits stay put. Clearing them means retyping five correct ones to
      // fix a typo in the sixth.
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / FlowScaffold.frameWidth;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final code = value.text;
        final hasError = _error != null;
        return FlowScaffold(
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                                right: i == _length - 1 ? 0 : 10 * s,
                              ),
                              child: AnimatedContainer(
                                duration: Motion.fast,
                                curve: Motion.inPlace,
                                height: 60 * s,
                                decoration: BoxDecoration(
                                  color: hasError
                                      ? AppColors.errorBg
                                      : filled
                                      ? AppColors.surface
                                      : AppColors.bgMuted,
                                  borderRadius: BorderRadius.circular(14 * s),
                                  border: Border.all(
                                    color: hasError
                                        ? AppColors.errorBorder
                                        : focused
                                        ? AppColors.accent
                                        : AppColors.border,
                                    width: (hasError || focused) ? 1.5 : 1,
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
                                          color: hasError
                                              ? AppColors.error
                                              : AppColors.textPrimary,
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
              if (hasError)
                FlowHelper(text: _error!, isError: true, icon: FlowIcons.info),
              Padding(
                padding: EdgeInsets.only(top: hasError ? 10 * s : 18 * s),
                child: (_secondsLeft > 0 && !hasError)
                    ? Row(
                        children: [
                          SvgPicture.string(
                            FlowIcons.info,
                            width: 15 * s,
                            height: 15 * s,
                          ),
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
                          AppScope.of(context).authService
                              .requestCode(widget.phone);
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
        return FlowScaffold(
          title: 'What should we\ncall you?',
          body:
              'Shown on your card while you are checked in. '
              'A first name is plenty.',
          actionLabel: 'Continue',
          onAction: ready
              ? () {
                  final flow = AppScope.of(context);
                  flow.updateProfile(
                    flow.profile.copyWith(name: value.text.trim()),
                  );
                  Navigator.of(context)
                      .push(FadeThroughRoute<void>(child: const EmailScreen()));
                }
              : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowField(
                controller: _controller,
                hint: 'First name',
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                maxLength: 24,
              ),
              const FlowHelper(
                text: 'You can change this any time in Settings.',
                icon: FlowIcons.info,
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
    final flow = AppScope.of(context);
    flow.updateProfile(flow.profile.copyWith(email: email));
    Navigator.of(context)
        .push(FadeThroughRoute<void>(child: const BirthdayScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / FlowScaffold.frameWidth;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
        return FlowScaffold(
          title: 'Your email',
          body:
              'Only used to reach you about your account. '
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
              FlowField(
                controller: _controller,
                hint: 'name@example.com',
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              const FlowHelper(
                text: 'We do not send marketing. Account matters only.',
                icon: FlowIcons.lock,
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
  void initState() {
    super.initState();
    // Without these the screen never rebuilds while the date is typed, so the
    // Continue button stays disabled no matter what you enter - the flow dead
    // ends here. The other screens get this for free from a
    // ValueListenableBuilder; this one reads three controllers at once, so it
    // listens instead.
    for (final field in [_day, _month, _year]) {
      field.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final field in [_day, _month, _year]) {
      field.removeListener(_onChanged);
      field.dispose();
    }
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
    final flow = AppScope.of(context);
    final draft = flow.profile.copyWith(birthday: _date);
    setState(() => _busy = true);
    try {
      await flow.authService.submitProfile(draft);
      flow.updateProfile(draft);
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
    final s = MediaQuery.sizeOf(context).width / FlowScaffold.frameWidth;
    final complete = _date != null;

    return FlowScaffold(
      title: 'When were\nyou born?',
      body:
          'Layover is for adults only. Your birthday is never shown to anyone.',
      actionLabel: 'Continue',
      busy: _busy,
      onAction: _isAdult ? _finish : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FlowField(
                  controller: _day,
                  hint: 'DD',
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                child: FlowField(
                  controller: _month,
                  hint: 'MM',
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                ),
              ),
              SizedBox(width: 10 * s),
              Expanded(
                flex: 2,
                child: FlowField(
                  controller: _year,
                  hint: 'YYYY',
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                ),
              ),
            ],
          ),
          FlowHelper(
            // Both branches said the same thing, so a rejected date looked
            // identical to an empty form. Only the under-18 case is an error.
            text: complete && !_isAdult
                ? 'That birthday is under 18. Layover is adults only.'
                : 'You must be 18 or over to use Layover.',
            isError: complete && !_isAdult,
            icon: FlowIcons.info,
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
    final s = MediaQuery.sizeOf(context).width / FlowScaffold.frameWidth;
    final name = AppScope.of(context).name;

    return FlowScaffold(
      blueHero: true,
      showBack: false,
      eyebrow: 'You are in.',
      title: returning
          ? 'Welcome back'
          : (name == null ? 'All set' : 'All set, $name'),
      body:
          'Next we find where you are, so you can check in and see '
          'who else is stuck there.',
      actionLabel: 'Turn on location',
      leading: _Badge(scale: s, icon: FlowIcons.check),
      onAction: () => Navigator.of(context).pushAndRemoveUntil(
        FadeThroughRoute<void>(child: const LocationFlowHost()),
        // Auth is done. Leaving it behind would let Back walk back into a code
        // screen for a session that already exists.
        (route) => route.isFirst,
      ),
      child: const SizedBox.shrink(),
    );
  }
}

/// The circular mark that leads a hero screen.
class _Badge extends StatelessWidget {
  const _Badge({required this.scale, required this.icon});

  final double scale;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      width: 56 * s,
      height: 56 * s,
      decoration: const BoxDecoration(
        color: AppColors.accentTint,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SvgPicture.string(icon, width: 28 * s, height: 28 * s),
    );
  }
}
