import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../presence/presence_models.dart';
import '../../presence/presence_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/flow_controls.dart';
import '../../widgets/flow_scaffold.dart';
import '../../widgets/page_transitions.dart';
import '../../widgets/presence_pass.dart';

// ─────────────────────── A01 Checked in ───────────────────────

class CheckedInScreen extends StatelessWidget {
  const CheckedInScreen({
    super.key,
    required this.session,
    required this.service,
    this.name,
  });

  final PresenceSession session;
  final PresenceService service;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final left = CountdownParts.from(session.remaining(DateTime.now()));

    return FlowScaffold(
      blueHero: true,
      showBack: false,
      eyebrow: 'You are in\nlimbo.',
      title: 'You are checked in',
      body:
          'Your card is live at ${session.venue.name} for the next '
          '${left.spoken.replaceAll(' left', '')}.',
      actionLabel: 'See your card',
      leading: Container(
        width: 56 * s,
        height: 56 * s,
        decoration: const BoxDecoration(
          color: AppColors.accentTint,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(
          FlowIcons.check,
          width: 28 * s,
          height: 28 * s,
        ),
      ),
      onAction: () => Navigator.of(context).pushReplacement(
        FadeThroughRoute<void>(
          child: LivePresenceScreen(
            session: session,
            service: service,
            name: name,
          ),
        ),
      ),
      child: const SizedBox.shrink(),
    );
  }
}

// ─────────── A02 live / A03 edit / A04 ending soon / A05 checkout ───────────

class LivePresenceScreen extends StatefulWidget {
  const LivePresenceScreen({
    super.key,
    required this.session,
    required this.service,
    this.name,
  });

  final PresenceSession session;
  final PresenceService service;
  final String? name;

  @override
  State<LivePresenceScreen> createState() => _LivePresenceScreenState();
}

class _LivePresenceScreenState extends State<LivePresenceScreen> {
  late PresenceSession _session = widget.session;
  VenueCrowd _crowd = VenueCrowd.empty;

  /// One clock for the whole screen. Every time-dependent value below reads
  /// this, so the headline, the flip tiles and the banner can never disagree
  /// about what time it is.
  DateTime _now = DateTime.now();
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
    _loadCrowd();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _loadCrowd() async {
    final crowd = await widget.service.crowdAt(
      _session.venue,
      since: _session.checkedInAt,
    );
    if (mounted) setState(() => _crowd = crowd);
  }

  Future<void> _editDuration() async {
    final picked = await showFlowSheet<ExpectedDuration>(
      context: context,
      builder: (sheetContext) => _DurationSheet(current: _session.duration),
    );
    if (picked == null || !mounted) return;
    setState(() => _busy = true);
    final updated = await widget.service.restretch(_session, picked);
    if (!mounted) return;
    setState(() {
      _session = updated;
      _busy = false;
    });
  }

  Future<void> _confirmCheckout() async {
    final confirmed = await showFlowSheet<bool>(
      context: context,
      builder: (sheetContext) => const _CheckoutSheet(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    final ended = await widget.service.checkOut(_session);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      FadeThroughRoute<void>(
        child: CheckedOutScreen(
          session: ended,
          service: widget.service,
          name: widget.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final endingSoon = _session.isEndingSoon(_now);
    final left = CountdownParts.from(_session.remaining(_now));

    return FlowScaffold(
      showBack: false,
      trailing: _LivePill(scale: s),
      title: endingSoon ? 'Your card is fading' : 'You are in limbo',
      body: endingSoon
          ? 'Still stuck? Stretch the clock. Otherwise your card fades out at '
                '${_clock(_session.expiresAt)}.'
          : 'Your card fades out on its own, or the moment you walk out of the '
                'venue.',
      banner: endingSoon
          ? FlowBanner(
              text:
                  'Your card fades out in ${left.spoken.replaceAll(' left', '')}.',
              icon: FlowIcons.clock,
            )
          : null,
      actionLabel: endingSoon ? 'Add 30 min' : 'See who else is here',
      busy: _busy,
      onAction: endingSoon
          ? () async {
              setState(() => _busy = true);
              final updated = await widget.service.restretch(
                _session,
                ExpectedDuration.halfHour,
              );
              if (!mounted) return;
              setState(() {
                _session = updated;
                _busy = false;
              });
            }
          : () => _snack(context, 'The Limbo feed is the next flow.'),
      secondary: QuietAction(
        label: "I'm done waiting",
        onTap: _busy ? null : _confirmCheckout,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PresencePass(
            session: _session,
            now: _now,
            name: widget.name,
            crowd: _crowd,
            onTapCrowd: () =>
                _snack(context, 'The Limbo feed is the next flow.'),
          ),
          if (!endingSoon) ...[
            SizedBox(height: 14 * s),
            Row(
              children: [
                Expanded(
                  child: SecondaryAction(
                    label: 'Edit time left',
                    scale: s,
                    onTap: _busy ? null : _editDuration,
                  ),
                ),
                SizedBox(width: 10 * s),
                Expanded(
                  child: SecondaryAction(
                    label: 'Change vibe',
                    scale: s,
                    onTap: _busy
                        ? null
                        : () => _snack(
                            context,
                            'Vibe editing comes with the feed.',
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A03 - how much longer.
class _DurationSheet extends StatefulWidget {
  const _DurationSheet({required this.current});

  final ExpectedDuration current;

  @override
  State<_DurationSheet> createState() => _DurationSheetState();
}

class _DurationSheetState extends State<_DurationSheet> {
  late ExpectedDuration _picked = widget.current;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'How much longer?',
          style: interTight(
            size: 20 * s,
            weight: 600,
            height: 1.25,
            letterSpacing: -0.4 * s,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          'Replaces the time left. It does not add to it.',
          style: interTight(
            size: 14 * s,
            weight: 400,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 16 * s),
        Wrap(
          spacing: 10 * s,
          runSpacing: 10 * s,
          children: [
            for (final option in ExpectedDuration.values)
              SelectChip(
                label: option.label,
                selected: option == _picked,
                onTap: () => setState(() => _picked = option),
              ),
          ],
        ),
        SizedBox(height: 20 * s),
        PrimaryAction(
          label: 'Update time left',
          scale: s,
          onTap: () => Navigator.of(context).pop(_picked),
        ),
      ],
    );
  }
}

/// A05 - done waiting.
class _CheckoutSheet extends StatelessWidget {
  const _CheckoutSheet();

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Done waiting?',
          style: interTight(
            size: 20 * s,
            weight: 600,
            height: 1.25,
            letterSpacing: -0.4 * s,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6 * s),
        Text(
          'Your card disappears from the venue right away. Chats you already '
          'opened stay alive for 2 hrs, then fade.',
          style: interTight(
            size: 14 * s,
            weight: 400,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: 20 * s),
        PrimaryAction(
          label: 'Check me out',
          scale: s,
          onTap: () => Navigator.of(context).pop(true),
        ),
        SizedBox(height: 10 * s),
        SecondaryAction(
          label: 'Stay checked in',
          scale: s,
          onTap: () => Navigator.of(context).pop(false),
        ),
      ],
    );
  }
}

// ─────────────────────── A06 Checked out ───────────────────────

class CheckedOutScreen extends StatelessWidget {
  const CheckedOutScreen({
    super.key,
    required this.session,
    required this.service,
    this.name,
  });

  final PresenceSession session;
  final PresenceService service;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final wasLive = (session.endedAt ?? DateTime.now()).difference(
      session.checkedInAt,
    );

    return FlowScaffold(
      showBack: false,
      title: 'You are out\nof limbo',
      body:
          'Your card is gone from ${session.venue.name}. Nobody there can '
          'see you now.',
      actionLabel: 'Check in somewhere else',
      onAction: () => Navigator.of(context).popUntil((route) => route.isFirst),
      child: PresencePass(
        session: session,
        now: DateTime.now(),
        name: name,
        crowd: VenueCrowd(
          total: 0,
          arrivedSince: 0,
          initials: const ['T', 'K', 'R'],
        ),
      ),
    ).withSemanticsHint('Was live for ${wasLive.inMinutes} minutes');
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 7 * s),
      decoration: BoxDecoration(
        color: AppColors.accentSelectedBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7 * s,
            height: 7 * s,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 6 * s),
          Text(
            'Live',
            style: interTight(
              size: 13 * s,
              weight: 600,
              height: 1.2,
              color: AppColors.accentStrong,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  /// Attaches a screen reader hint without changing the visual tree.
  Widget withSemanticsHint(String hint) =>
      Semantics(container: false, hint: hint, child: this);
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

String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
