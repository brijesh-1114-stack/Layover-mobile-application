import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import 'blur_reveal.dart';
import 'top_glow.dart';

/// Shared layout for every step screen in the app - auth, location, check-in.
///
/// They all use the same 393pt frame, the same paddings, the same staggered
/// entrance and the same footer, so the chrome lives here once and screens
/// supply only their own body. Keeping it in one place is what stops the second
/// flow from drifting a few pixels away from the first.
class FlowScaffold extends StatefulWidget {
  const FlowScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.eyebrow,
    this.blueHero = false,
    this.showBack = true,
    this.trailing,
    this.secondary,
    this.busy = false,
    this.banner,
    this.footer,
    this.leading,
  });

  /// A mark that sits *above* the headline - the tick on "All set", the pin on
  /// "Enable location". Distinct from [child], which sits under the copy where
  /// form controls belong. A screen led by a badge also parks its whole block
  /// at the bottom of the glow, with the action right underneath, so the two
  /// behaviours travel together.
  final Widget? leading;

  /// Replaces the primary button entirely, for the rare screen that offers two
  /// equal choices rather than one action and an escape hatch.
  final Widget? footer;

  /// Large headline.
  final String title;

  /// Supporting line under the headline.
  final String body;

  /// The screen's own controls, between the copy and the footer.
  final Widget child;

  final String actionLabel;
  final VoidCallback? onAction;

  /// White text on the blue hero, used on the first and last screens of a flow.
  final String? eyebrow;
  final bool blueHero;
  final bool showBack;

  /// Sits opposite the back button - a step counter, a live pill.
  final Widget? trailing;

  /// Optional quiet action under the primary button.
  final Widget? secondary;

  /// Disables the action and shows a spinner while the fake backend works.
  final bool busy;

  /// Full width note above the body, for warnings that outrank the copy.
  final Widget? banner;

  static const double frameWidth = 393;

  /// Layout scale for the current screen, the factor every measurement in the
  /// app is multiplied by.
  static double scaleOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width / frameWidth;

  @override
  State<FlowScaffold> createState() => _FlowScaffoldState();
}

class _FlowScaffoldState extends State<FlowScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: Motion.entry,
  );

  Animation<double> _on(Interval i) =>
      CurvedAnimation(parent: _entry, curve: i);

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
    final s = media.size.width / FlowScaffold.frameWidth;
    final safeTop = media.padding.top;
    final safeBottom = media.padding.bottom;
    final keyboardOpen = media.viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: widget.blueHero
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: widget.blueHero
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.paper,
        // The layout handles the keyboard itself (see the scroll view below).
        // Letting the Scaffold resize would squash the hero glow as well.
        resizeToAvoidBottomInset: false,
        body: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            if (widget.blueHero) TopGlowHero(scale: s),
            _KeyboardAware(
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
                  if (widget.showBack || widget.trailing != null)
                    Padding(
                      padding: EdgeInsets.only(top: 8 * s, bottom: 24 * s),
                      child: Row(
                        children: [
                          if (widget.showBack) const FlowBackButton(),
                          const Spacer(),
                          if (widget.trailing != null) widget.trailing!,
                        ],
                      ),
                    ),
                  if (widget.blueHero) const Spacer(),
                  if (widget.leading != null) ...[
                    BlurRevealTransition(
                      animation: _fieldIn,
                      sigma: 0,
                      rise: 14 * s,
                      child: widget.leading!,
                    ),
                    SizedBox(height: 22 * s),
                  ],
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
                  if (widget.banner != null) ...[
                    SizedBox(height: 18 * s),
                    BlurRevealTransition(
                      animation: _bodyIn,
                      sigma: 0,
                      rise: 10 * s,
                      child: widget.banner!,
                    ),
                  ],
                  SizedBox(height: 26 * s),
                  BlurRevealTransition(
                    animation: _fieldIn,
                    sigma: 0,
                    rise: 14 * s,
                    child: widget.child,
                  ),
                  // A badge screen has already used its flexible space above
                  // the mark; a second one here would strand the button at the
                  // bottom with a hole in the middle of the screen.
                  if (widget.leading == null) ...[
                    // A floor under the flexible gap. With the keyboard open
                    // there is no slack left for the Spacer to take, so it
                    // collapses to nothing and the action ends up sitting on
                    // the helper line under the field.
                    SizedBox(height: 32 * s),
                    const Spacer(),
                  ] else
                    SizedBox(height: 30 * s),
                  BlurRevealTransition(
                    animation: _actionIn,
                    sigma: 0,
                    rise: Motion.surfaceRise * s,
                    child:
                        widget.footer ??
                        Column(
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
                  // The home indicator is a mock of the system bar, which the
                  // keyboard covers anyway. Keeping it while typing spends
                  // ~30pt of the little room that is left.
                  if (!keyboardOpen) ...[
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
                  ],
                  SizedBox(
                    height: keyboardOpen
                        ? 16 * s
                        : (safeBottom > 0 ? safeBottom : 14 * s),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Keeps the footer above the keyboard.
///
/// The screens are built as one column with a Spacer, which is exactly the
/// shape that breaks when a keyboard appears: with `resizeToAvoidBottomInset`
/// the hero glow gets squashed, and without it the primary button sits under
/// the keyboard where it cannot be tapped - the state the app shipped in.
///
/// Scrolling with a minimum height equal to the space actually left keeps the
/// column at full height when there is no keyboard, and lets it shrink and
/// scroll when there is one.
class _KeyboardAware extends StatelessWidget {
  const _KeyboardAware({required this.padding, required this.child});

  final EdgeInsets padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight - inset;
        return Padding(
          padding: EdgeInsets.only(bottom: inset),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: available > 0 ? available : 0,
              ),
              child: IntrinsicHeight(child: child),
            ),
          ),
        );
      },
    );
  }
}

class FlowBackButton extends StatelessWidget {
  const FlowBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
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

/// Full width dark pill, the primary action on every step screen.
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.textMuted,
                        ),
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

/// Outline pill, used where two choices sit side by side and neither should
/// look like the safe default.
class SecondaryAction extends StatelessWidget {
  const SecondaryAction({
    super.key,
    required this.label,
    required this.onTap,
    required this.scale,
  });

  final String label;
  final VoidCallback? onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return SizedBox(
      height: 56 * s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: interTight(
                  size: 17 * s,
                  weight: 600,
                  height: 1.3,
                  letterSpacing: -0.2 * s,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Quiet text action, for the escape hatch under a primary button.
class QuietAction extends StatelessWidget {
  const QuietAction({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return TextButton(
      onPressed: onTap,
      child: Text(
        label,
        style: interTight(
          size: 15 * s,
          weight: 600,
          height: 1.35,
          letterSpacing: -0.1 * s,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Single line input, matching the Figma field.
class FlowField extends StatelessWidget {
  const FlowField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.maxLines = 1,
    this.hasError = false,
    this.textAlign = TextAlign.start,
  });

  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int maxLines;
  final bool hasError;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final active = value.text.isNotEmpty;
        final borderColor = hasError
            ? AppColors.errorBorder
            : active
            ? AppColors.accent
            : AppColors.border;
        return AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.inPlace,
          constraints: BoxConstraints(minHeight: 58 * s),
          padding: EdgeInsets.symmetric(
            horizontal: 16 * s,
            vertical: maxLines > 1 ? 14 * s : 0,
          ),
          decoration: BoxDecoration(
            color: hasError ? AppColors.errorBg : AppColors.surface,
            borderRadius: BorderRadius.circular(14 * s),
            border: Border.all(
              color: borderColor,
              width: (active || hasError) ? 1.5 : 1,
            ),
          ),
          alignment: maxLines > 1 ? Alignment.topLeft : Alignment.centerLeft,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: autofocus,
            textCapitalization: textCapitalization,
            maxLength: maxLength,
            maxLines: maxLines,
            textAlign: textAlign,
            cursorColor: AppColors.accent,
            style: interTight(
              size: 17 * s,
              weight: 600,
              height: 1.3,
              letterSpacing: -0.2 * s,
              color: hasError ? AppColors.error : AppColors.textPrimary,
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

/// Small note under a field. Turns red when it is carrying an error, so a
/// screen never needs a second slot for the failure case.
class FlowHelper extends StatelessWidget {
  const FlowHelper({
    super.key,
    required this.text,
    required this.icon,
    this.isError = false,
  });

  final String text;
  final String icon;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Padding(
      padding: EdgeInsets.only(top: 14 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.string(
            isError ? FlowIcons.alert : icon,
            width: 15 * s,
            height: 15 * s,
          ),
          SizedBox(width: 8 * s),
          Expanded(
            child: Text(
              text,
              style: interTight(
                size: 13 * s,
                weight: isError ? 500 : 400,
                height: 1.38,
                color: isError ? AppColors.error : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icons used by the helper lines and small inline notes.
class FlowIcons {
  const FlowIcons._();

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

  static const String alert =
      '<svg width="15" height="15" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="12" cy="12" r="9" stroke="#C7292E" stroke-width="2"/>'
      '<path d="M12 7.5v5.5M12 16.2h.01" stroke="#C7292E" stroke-width="2" '
      'stroke-linecap="round"/></svg>';

  static const String pin =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M12 21s7-5.6 7-11a7 7 0 1 0-14 0c0 5.4 7 11 7 11z" '
      'stroke="#0B79F0" stroke-width="2" stroke-linejoin="round"/>'
      '<circle cx="12" cy="10" r="2.6" stroke="#0B79F0" stroke-width="2"/></svg>';

  static const String search =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="11" cy="11" r="7" stroke="#A3AAB8" stroke-width="2"/>'
      '<path d="M16.5 16.5L21 21" stroke="#A3AAB8" stroke-width="2" '
      'stroke-linecap="round"/></svg>';

  static const String check =
      '<svg width="28" height="28" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#0B79F0" stroke-width="2.6" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';

  static const String clock =
      '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="12" cy="12" r="9" stroke="#8A5A00" stroke-width="2"/>'
      '<path d="M12 7v5.4l3.2 2" stroke="#8A5A00" stroke-width="2" '
      'stroke-linecap="round" stroke-linejoin="round"/></svg>';

  /// A pin tinted for a muted context, where the accent version would shout.
  static String pinMuted(String hex) => pin.replaceAll('#0B79F0', hex);
}
