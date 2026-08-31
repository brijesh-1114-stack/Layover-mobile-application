import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../theme/motion.dart';
import '../../widgets/blur_reveal.dart';

/// Shared layout for every auth screen.
///
/// All six use the same 393pt Figma frame, the same paddings and the same
/// footer, so the chrome lives here once. Screens supply only their own body.
class AuthScaffold extends StatefulWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.eyebrow,
    this.blueHero = false,
    this.showBack = true,
    this.secondary,
    this.busy = false,
  });

  /// Large headline.
  final String title;

  /// Supporting line under the headline.
  final String body;

  /// The screen's own controls, between the copy and the footer.
  final Widget child;

  final String actionLabel;
  final VoidCallback? onAction;

  /// White text on the blue hero, used on the first and last screens.
  final String? eyebrow;
  final bool blueHero;
  final bool showBack;

  /// Optional quiet action under the primary button.
  final Widget? secondary;

  /// Disables the action and shows a spinner while the fake backend works.
  final bool busy;

  static const double frameWidth = 393;

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: Motion.entry,
  );

  Animation<double> _on(Interval i) => CurvedAnimation(parent: _entry, curve: i);

  late final Animation<double> _titleIn = _on(Motion.step(0));
  late final Animation<double> _bodyIn = _on(Motion.step(1));
  late final Animation<double> _fieldIn = _on(Motion.step(2));
  late final Animation<double> _actionIn = _on(Motion.action);

  @override
  void initState() {
    super.initState();
    // Same cold start guard as the onboarding screens: an immediate start plays
    // out before Android has composited anything.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
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
    final s = media.size.width / AuthScaffold.frameWidth;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            widget.blueHero ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            widget.blueHero ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        resizeToAvoidBottomInset: false,
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (widget.blueHero) _BlueHero(scale: s),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: safeTop + 14 * s),
                  if (widget.eyebrow != null)
                    Padding(
                      padding: EdgeInsets.only(top: 18 * s),
                      child: Text(
                        widget.eyebrow!,
                        style: interTight(
                          size: 20 * s,
                          weight: 500,
                          height: 1.2,
                          letterSpacing: -0.3 * s,
                          color: AppColors.onInk,
                        ),
                      ),
                    ),
                  if (widget.showBack)
                    Padding(
                      padding: EdgeInsets.only(top: 8 * s, bottom: 24 * s),
                      child: const _BackButton(),
                    ),
                  if (widget.blueHero) const Spacer(),
                  BlurRevealTransition(
                    animation: _titleIn,
                    child: Text(
                      widget.title,
                      style: interTight(
                        size: 32 * s,
                        weight: 700,
                        height: 1.19,
                        letterSpacing: -1 * s,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * s),
                  BlurRevealTransition(
                    animation: _bodyIn,
                    sigma: Motion.textSigma - 3,
                    child: Text(
                      widget.body,
                      style: interTight(
                        size: 16 * s,
                        weight: 400,
                        height: 1.44,
                        letterSpacing: -0.1 * s,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  SizedBox(height: 26 * s),
                  BlurRevealTransition(
                    animation: _fieldIn,
                    sigma: 0,
                    rise: 14 * s,
                    child: widget.child,
                  ),
                  const Spacer(),
                  BlurRevealTransition(
                    animation: _actionIn,
                    sigma: 0,
                    rise: Motion.surfaceRise * s,
                    child: Column(
                      children: [
                        PrimaryAction(
                          label: widget.actionLabel,
                          onTap: widget.onAction,
                          busy: widget.busy,
                          scale: s,
                        ),
                        if (widget.secondary != null) ...[
                          SizedBox(height: 4 * s),
                          widget.secondary!,
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  Center(
                    child: Container(
                      width: 140 * s,
                      height: 5 * s,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  SizedBox(height: safeBottom > 0 ? safeBottom : 14 * s),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The gradient used on the first and last auth screens, matching onboarding.
class _BlueHero extends StatelessWidget {
  const _BlueHero({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: 430 * scale,
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B79F0),
              Color(0xFF1E9BF6),
              Color(0xFF45BEF8),
              Color(0xFF82D5FA),
              Color(0xFFC9EAFC),
              Color(0xFFF2FAFE),
              Color(0xFFFFFFFF),
            ],
            stops: [0, 0.14, 0.32, 0.50, 0.66, 0.82, 1],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    return SizedBox(
      width: 40 * s,
      height: 40 * s,
      child: Material(
        color: AppColors.bgMuted,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          child: Center(
            child: SvgPicture.string(
              '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" '
              'xmlns="http://www.w3.org/2000/svg"><path d="M15 5l-7 7 7 7" '
              'stroke="#0D0D0F" stroke-width="2.2" stroke-linecap="round" '
              'stroke-linejoin="round"/></svg>',
              width: 20 * s,
              height: 20 * s,
            ),
          ),
        ),
      ),
    );
  }
}

/// Full width dark pill, the primary action on every auth screen.
class PrimaryAction extends StatelessWidget {
  const PrimaryAction({
    super.key,
    required this.label,
    required this.onTap,
    required this.scale,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final double scale;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final enabled = onTap != null && !busy;

    return SizedBox(
      width: double.infinity,
      height: 56 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: enabled ? AppColors.ink : AppColors.bgMuted,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: enabled ? onTap : null,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 22 * s,
                      height: 22 * s,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.textMuted),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: interTight(
                            size: 17 * s,
                            weight: 600,
                            height: 1.3,
                            letterSpacing: -0.2 * s,
                            color: enabled
                                ? AppColors.onInk
                                : AppColors.textMuted,
                          ),
                        ),
                        if (enabled) ...[
                          SizedBox(width: 10 * s),
                          SvgPicture.string(
                            '<svg width="18" height="18" viewBox="0 0 24 24" '
                            'fill="none" xmlns="http://www.w3.org/2000/svg">'
                            '<path d="M5 12h14M13 6l6 6-6 6" stroke="#FFFFFF" '
                            'stroke-width="2.2" stroke-linecap="round" '
                            'stroke-linejoin="round"/></svg>',
                            width: 18 * s,
                            height: 18 * s,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single line input, matching the Figma field.
class AuthField extends StatelessWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = value.text.isNotEmpty;
        return Container(
          height: 58 * s,
          padding: EdgeInsets.symmetric(horizontal: 16 * s),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.border,
              width: active ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: autofocus,
            textCapitalization: textCapitalization,
            maxLength: maxLength,
            cursorColor: AppColors.accent,
            style: interTight(
              size: 17 * s,
              weight: 600,
              height: 1.3,
              letterSpacing: -0.2 * s,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              hintText: hint,
              hintStyle: interTight(
                size: 17 * s,
                weight: 600,
                height: 1.3,
                letterSpacing: -0.2 * s,
                color: AppColors.textMuted,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Small muted note under a field.
class AuthHelper extends StatelessWidget {
  const AuthHelper({super.key, required this.text, required this.icon});

  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / AuthScaffold.frameWidth;
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.string(icon, width: 15 * s, height: 15 * s),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(
              text,
              style: interTight(
                size: 13 * s,
                weight: 400,
                height: 1.38,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icons used by the helper lines.
class AuthIcons {
  const AuthIcons._();

  static const String lock =
      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<rect x="4" y="10" width="16" height="10" rx="3" stroke="#A3AAB8" stroke-width="2"/>'
      '<path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="#A3AAB8" stroke-width="2" '
      'stroke-linecap="round"/></svg>';

  static const String info =
      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="12" cy="12" r="9" stroke="#A3AAB8" stroke-width="2"/>'
      '<path d="M12 8h.01M11 12h1v4h1" stroke="#A3AAB8" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';
}
