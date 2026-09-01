import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import 'flow_scaffold.dart';

/// Pill toggle used wherever a short list of options has to fit on one screen.
class SelectChip extends StatelessWidget {
  const SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.inPlace,
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 11 * s),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSelectedBg : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: interTight(
              size: 14 * s,
              weight: 600,
              height: 1.2,
              letterSpacing: -0.1 * s,
              color: selected ? AppColors.accentStrong : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

/// A tappable row with an icon puck, a title, a supporting line and a tick when
/// chosen. Venues and vibes are the same shape, so they share one widget.
class SelectRow extends StatelessWidget {
  const SelectRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;

  /// Raw SVG, tinted by this widget - the puck colour and the icon colour have
  /// to move together when the row is selected.
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final tint = selected ? AppColors.accent : AppColors.textMuted;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16 * s),
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.fast,
          curve: Motion.inPlace,
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: selected ? AppColors.accentSelectedBg : AppColors.surface,
            borderRadius: BorderRadius.circular(16 * s),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40 * s,
                height: 40 * s,
                decoration: BoxDecoration(
                  color: selected ? AppColors.accentTint : AppColors.bgMuted,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: SvgPicture.string(
                  icon.replaceAll('#0B79F0', _hex(tint)),
                  width: 20 * s,
                  height: 20 * s,
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: interTight(
                        size: 16 * s,
                        weight: 600,
                        height: 1.25,
                        letterSpacing: -0.2 * s,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 3 * s),
                    Text(
                      subtitle,
                      style: interTight(
                        size: 13 * s,
                        weight: 400,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected) ...[
                SizedBox(width: 10 * s),
                SvgPicture.string(
                  '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" '
                  'xmlns="http://www.w3.org/2000/svg">'
                  '<path d="M5 12.5l4.5 4.5L19 7.5" stroke="#0B79F0" '
                  'stroke-width="2.6" stroke-linecap="round" '
                  'stroke-linejoin="round"/></svg>',
                  width: 18 * s,
                  height: 18 * s,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _hex(Color c) =>
      '#${((c.toARGB32()) & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// Full width note that outranks the body copy - "your card fades in 10 min".
class FlowBanner extends StatelessWidget {
  const FlowBanner({super.key, required this.text, required this.icon});

  final String text;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 14 * s),
      decoration: BoxDecoration(
        color: AppColors.warningBg,
        borderRadius: BorderRadius.circular(14 * s),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Row(
        children: [
          SvgPicture.string(icon, width: 18 * s, height: 18 * s),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              text,
              style: interTight(
                size: 14 * s,
                weight: 600,
                height: 1.35,
                letterSpacing: -0.1 * s,
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small step counter that sits opposite the back button during check-in.
class StepBadge extends StatelessWidget {
  const StepBadge({super.key, required this.step, required this.of});

  final int step;
  final int of;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Text(
      'Check in - $step of $of',
      style: interTight(
        size: 13 * s,
        weight: 600,
        height: 1.2,
        letterSpacing: -0.1 * s,
        color: AppColors.accentStrong,
      ),
    );
  }
}

/// Bottom sheet chrome: handle, padding, and the rounded top corners every
/// sheet in the app shares.
Future<T?> showFlowSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
}) {
  final s = FlowScaffold.scaleOf(context);
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
    ),
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24 * s, 10 * s, 24 * s, 20 * s),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40 * s,
                height: 4 * s,
                margin: EdgeInsets.only(bottom: 18 * s),
                decoration: BoxDecoration(
                  color: AppColors.stepInactive.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            builder(context),
          ],
        ),
      ),
    ),
  );
}
