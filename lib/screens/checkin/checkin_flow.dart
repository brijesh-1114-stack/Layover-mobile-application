import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../presence/presence_models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/flow_controls.dart';
import '../../widgets/flow_scaffold.dart';
import '../../widgets/page_transitions.dart';
import '../presence/presence_flow.dart';

/// Icons for the vibe rows. Kept inline rather than as assets because each is a
/// handful of paths and the flow already ships its icons this way.
class _VibeIcons {
  static const quiet =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<circle cx="9" cy="8" r="3.2" stroke="#0B79F0" stroke-width="2"/>'
      '<path d="M3.5 19c0-3 2.5-5 5.5-5s5.5 2 5.5 5" stroke="#0B79F0" '
      'stroke-width="2" stroke-linecap="round"/>'
      '<path d="M17 9.5h4M17 13.5h3" stroke="#0B79F0" stroke-width="2" '
      'stroke-linecap="round"/></svg>';

  static const chat =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M4 6.5A2.5 2.5 0 0 1 6.5 4h11A2.5 2.5 0 0 1 20 6.5v7A2.5 2.5 0 '
      '0 1 17.5 16H9l-5 4V6.5z" stroke="#0B79F0" stroke-width="2" '
      'stroke-linejoin="round"/></svg>';

  static const looking =
      '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" '
      'xmlns="http://www.w3.org/2000/svg">'
      '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 '
      '2.5 12z" stroke="#0B79F0" stroke-width="2" stroke-linejoin="round"/>'
      '<circle cx="12" cy="12" r="2.8" stroke="#0B79F0" stroke-width="2"/></svg>';

  static String forVibe(Vibe v) => switch (v) {
    Vibe.quiet => quiet,
    Vibe.chat => chat,
    Vibe.looking => looking,
  };
}

// ─────────────────────── C01 Layover type ───────────────────────

class LayoverTypeScreen extends StatefulWidget {
  const LayoverTypeScreen({super.key, required this.venue});

  final Venue venue;

  @override
  State<LayoverTypeScreen> createState() => _LayoverTypeScreenState();
}

class _LayoverTypeScreenState extends State<LayoverTypeScreen> {
  late LayoverType? _type = widget.venue.type;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      trailing: const StepBadge(step: 1, of: 4),
      title: 'What kind of\nwait is this?',
      body: 'It sets the icon on your card, and who you show up next to.',
      actionLabel: 'Continue',
      onAction: _type == null
          ? null
          : () => Navigator.of(context).push(
              FadeThroughRoute<void>(
                child: DurationScreen(
                  draft: CheckInDraft(venue: widget.venue, type: _type),
                ),
              ),
            ),
      child: Wrap(
        spacing: 10 * s,
        runSpacing: 10 * s,
        children: [
          for (final type in LayoverType.values)
            SelectChip(
              label: type.label,
              selected: type == _type,
              onTap: () => setState(() => _type = type),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────── C02 Duration ───────────────────────

class DurationScreen extends StatefulWidget {
  const DurationScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<DurationScreen> createState() => _DurationScreenState();
}

class _DurationScreenState extends State<DurationScreen> {
  ExpectedDuration? _duration = ExpectedDuration.oneToTwo;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      trailing: const StepBadge(step: 2, of: 4),
      title: 'How long will\nyou be here?',
      body:
          'Your card disappears when the clock runs out. You can stretch it '
          'later.',
      actionLabel: 'Continue',
      onAction: _duration == null
          ? null
          : () => Navigator.of(context).push(
              FadeThroughRoute<void>(
                child: VibeScreen(
                  draft: widget.draft.copyWith(duration: _duration),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10 * s,
            runSpacing: 10 * s,
            children: [
              for (final option in ExpectedDuration.values)
                SelectChip(
                  label: option.label,
                  selected: option == _duration,
                  onTap: () => setState(() => _duration = option),
                ),
            ],
          ),
          const FlowHelper(
            text: '"No idea" gives you 2 hrs, and asks again near the end.',
            icon: FlowIcons.info,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── C03 Vibe ───────────────────────

class VibeScreen extends StatefulWidget {
  const VibeScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<VibeScreen> createState() => _VibeScreenState();
}

class _VibeScreenState extends State<VibeScreen> {
  Vibe? _vibe = Vibe.chat;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      trailing: const StepBadge(step: 3, of: 4),
      title: 'What are you\nup for?',
      body: 'People filter the feed by this, so say what you actually want.',
      actionLabel: 'Continue',
      onAction: _vibe == null
          ? null
          : () => Navigator.of(context).push(
              FadeThroughRoute<void>(
                child: StatusLineScreen(
                  draft: widget.draft.copyWith(vibe: _vibe),
                ),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final vibe in Vibe.values) ...[
            SelectRow(
              title: vibe.label,
              subtitle: vibe.blurb,
              icon: _VibeIcons.forVibe(vibe),
              selected: vibe == _vibe,
              onTap: () => setState(() => _vibe = vibe),
            ),
            SizedBox(height: 10 * s),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────── C04 Status line ───────────────────────

class StatusLineScreen extends StatefulWidget {
  const StatusLineScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<StatusLineScreen> createState() => _StatusLineScreenState();
}

class _StatusLineScreenState extends State<StatusLineScreen> {
  static const int _limit = 80;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(String? line) {
    Navigator.of(context).push(
      FadeThroughRoute<void>(
        child: ReviewScreen(
          draft: line == null
              ? widget.draft.copyWith(clearStatusLine: true)
              : widget.draft.copyWith(statusLine: line),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        return FlowScaffold(
          trailing: const StepBadge(step: 4, of: 4),
          title: 'Say what is\ngoing on',
          body: 'One line, on your card. Skip it if you cannot be bothered.',
          actionLabel: 'Review check-in',
          onAction: () => _next(text.isEmpty ? null : text),
          secondary: QuietAction(
            label: 'Skip and review',
            onTap: () => _next(null),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FlowField(
                controller: _controller,
                hint: 'Flight delayed, bored out of my mind',
                autofocus: true,
                maxLength: _limit,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              SizedBox(height: 10 * s),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Visible to everyone at this venue.',
                      style: interTight(
                        size: 13 * s,
                        weight: 400,
                        height: 1.38,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    '${value.text.characters.length}/$_limit',
                    style: interTight(
                      size: 13 * s,
                      weight: 500,
                      height: 1.38,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────── C05 Review / C06 busy ───────────────────────

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key, required this.draft});

  final CheckInDraft draft;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  bool _busy = false;

  Future<void> _checkIn() async {
    final flow = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final session = await flow.presenceService.checkIn(widget.draft);
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        FadeThroughRoute<void>(
          child: CheckedInScreen(
            session: session,
            service: flow.presenceService,
            name: flow.name,
          ),
        ),
        // The composer is finished business - leaving it on the stack would let
        // Back drop the user into a half-filled form behind a live card.
        (route) => route.isFirst,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final draft = widget.draft;
    final ends = DateTime.now().add(draft.duration!.span);

    Widget field(String label, String value) => Padding(
      padding: EdgeInsets.only(bottom: 14 * s),
      child: Row(
        children: [
          SizedBox(
            width: 96 * s,
            child: Text(
              label,
              style: interTight(
                size: 13 * s,
                weight: 500,
                height: 1.3,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: interTight(
                size: 15 * s,
                weight: 600,
                height: 1.3,
                letterSpacing: -0.2 * s,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Text(
              'Change',
              style: interTight(
                size: 13 * s,
                weight: 600,
                height: 1.3,
                color: AppColors.accentStrong,
              ),
            ),
          ),
        ],
      ),
    );

    return FlowScaffold(
      title: 'Ready to be\nin limbo?',
      body: 'This is what everyone at the venue will see.',
      actionLabel: "I'm stuck here",
      busy: _busy,
      onAction: _checkIn,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: AppColors.accentSelectedBg,
              padding: EdgeInsets.all(18 * s),
              child: Row(
                children: [
                  SvgPicture.string(
                    FlowIcons.pin,
                    width: 20 * s,
                    height: 20 * s,
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.venue!.name,
                          style: interTight(
                            size: 16 * s,
                            weight: 600,
                            height: 1.25,
                            letterSpacing: -0.2 * s,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2 * s),
                        Text(
                          draft.venue!.subtitle,
                          style: interTight(
                            size: 13 * s,
                            weight: 400,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18 * s, 18 * s, 18 * s, 4 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  field('Type', draft.type!.label),
                  field(
                    'Ends in',
                    '${draft.duration!.label} - ${_clock(ends)}',
                  ),
                  field('Vibe', draft.vibe!.label),
                  if (draft.statusLine != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(14 * s),
                      margin: EdgeInsets.only(bottom: 14 * s),
                      decoration: BoxDecoration(
                        color: AppColors.bgMuted,
                        borderRadius: BorderRadius.circular(12 * s),
                      ),
                      child: Text(
                        '"${draft.statusLine}"',
                        style: interTight(
                          size: 14 * s,
                          weight: 400,
                          height: 1.4,
                          color: AppColors.textSecondary,
                        ),
                      ),
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

/// 24 hour wall clock, the format the whole flow uses for times of day.
String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
