import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app_scope.dart';
import '../../presence/presence_models.dart';
import '../../presence/presence_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';
import '../../widgets/flow_controls.dart';
import '../../widgets/flow_scaffold.dart';
import '../../widgets/page_transitions.dart';
import '../checkin/checkin_flow.dart';

/// Entry point for everything after sign up.
///
/// Like the auth flow, this holds no inherited state of its own: the service
/// lives in [AppScope] above the Navigator, so every screen pushed from here
/// can still reach it.
class LocationFlowHost extends StatelessWidget {
  const LocationFlowHost({super.key});

  @override
  Widget build(BuildContext context) => const EnableLocationScreen();
}

// ─────────────────────── L01 Enable location ───────────────────────

class EnableLocationScreen extends StatefulWidget {
  const EnableLocationScreen({super.key});

  @override
  State<EnableLocationScreen> createState() => _EnableLocationScreenState();
}

class _EnableLocationScreenState extends State<EnableLocationScreen> {
  bool _busy = false;

  Future<void> _ask() async {
    final flow = AppScope.of(context);
    setState(() => _busy = true);
    final result = await flow.presenceService.requestLocation();
    if (!mounted) return;
    setState(() => _busy = false);

    // The OS answer decides the branch. Refusing is a legitimate choice, not an
    // error, so it gets a screen of its own rather than a snackbar.
    Navigator.of(context).push(
      FadeThroughRoute<void>(
        child: result == LocationPermission.granted
            ? const FindingVenueScreen()
            : LocationDeniedScreen(
                permanent: result == LocationPermission.deniedForever,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      blueHero: true,
      showBack: false,
      eyebrow: 'Before you\ncheck in.',
      title: 'Enable location',
      body:
          'We use it to place you at the right venue, and to check you out '
          'automatically when you leave.',
      actionLabel: 'Allow',
      busy: _busy,
      onAction: _ask,
      leading: Container(
        width: 56 * s,
        height: 56 * s,
        decoration: const BoxDecoration(
          color: AppColors.accentTint,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: SvgPicture.string(FlowIcons.pin, width: 26 * s, height: 26 * s),
      ),
      footer: Row(
        children: [
          Expanded(
            child: SecondaryAction(
              label: 'Not now',
              scale: s,
              onTap: _busy
                  ? null
                  : () => Navigator.of(context).push(
                      FadeThroughRoute<void>(
                        child: const LocationDeniedScreen(permanent: false),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 12 * s),
          Expanded(
            child: PrimaryAction(
              label: 'Allow',
              scale: s,
              busy: _busy,
              onTap: _ask,
            ),
          ),
        ],
      ),
      child: const SizedBox.shrink(),
    );
  }
}

// ─────────────────────── L03 Location denied ───────────────────────

class LocationDeniedScreen extends StatelessWidget {
  const LocationDeniedScreen({super.key, required this.permanent});

  /// A permanent refusal cannot be re-prompted, so the action has to point at
  /// Settings instead of asking again.
  final bool permanent;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    Widget consequence(String text) => Padding(
      padding: EdgeInsets.only(bottom: 12 * s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6 * s,
            height: 6 * s,
            margin: EdgeInsets.only(top: 7 * s),
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              text,
              style: interTight(
                size: 14 * s,
                weight: 500,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    return FlowScaffold(
      title: 'Location is off',
      body:
          'Without it we cannot tell which venue you are in, or check you out '
          'when you leave.',
      actionLabel: permanent ? 'Open Settings' : 'Try again',
      onAction: () => Navigator.of(context).maybePop(),
      secondary: QuietAction(
        label: 'Pick a venue by hand',
        onTap: () =>
            Navigator.of(context)
                .push(FadeThroughRoute<void>(child: const SearchVenueScreen())),
      ),
      child: Container(
        padding: EdgeInsets.all(18 * s),
        decoration: BoxDecoration(
          color: AppColors.bgMuted,
          borderRadius: BorderRadius.circular(16 * s),
        ),
        child: Column(
          children: [
            consequence('No venue detected, so nobody sees you in limbo.'),
            Padding(
              padding: EdgeInsets.only(bottom: 0),
              child: consequence(
                'No auto checkout - you would have to end it by hand.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────── L04 Finding you ───────────────────────

class FindingVenueScreen extends StatefulWidget {
  const FindingVenueScreen({super.key});

  @override
  State<FindingVenueScreen> createState() => _FindingVenueScreenState();
}

class _FindingVenueScreenState extends State<FindingVenueScreen> {
  @override
  void initState() {
    super.initState();
    // Detection starts on its own: the screen exists to report progress, and
    // making the user press "find me" after they already granted location is a
    // step that carries no decision.
    WidgetsBinding.instance.addPostFrameCallback((_) => _detect());
  }

  Future<void> _detect() async {
    final flow = AppScope.of(context);
    try {
      final venues = await flow.presenceService.nearbyVenues();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeThroughRoute<void>(
          child: venues.isEmpty
              ? const SearchVenueScreen()
              : ConfirmVenueScreen(venues: venues),
        ),
      );
    } on LocationException {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        FadeThroughRoute<void>(child: const SearchVenueScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    Widget bar(double w, double h) => Container(
      width: w * s,
      height: h * s,
      decoration: BoxDecoration(
        color: AppColors.bgMuted,
        borderRadius: BorderRadius.circular(6 * s),
      ),
    );

    return FlowScaffold(
      title: 'Finding you',
      body: 'Reading your location and matching it to venues within 300 m.',
      actionLabel: 'Confirm venue',
      onAction: null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(18 * s),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16 * s),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40 * s,
                  height: 40 * s,
                  decoration: const BoxDecoration(
                    color: AppColors.bgMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 14 * s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(190, 14),
                    SizedBox(height: 8 * s),
                    bar(120, 12),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 14 * s),
          Row(
            children: [
              SizedBox(
                width: 15 * s,
                height: 15 * s,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textMuted,
                  ),
                ),
              ),
              SizedBox(width: 8 * s),
              Text(
                'Reading GPS',
                style: interTight(
                  size: 13 * s,
                  weight: 400,
                  height: 1.38,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── L05 Confirm venue ───────────────────────

class ConfirmVenueScreen extends StatefulWidget {
  const ConfirmVenueScreen({super.key, required this.venues});

  final List<Venue> venues;

  @override
  State<ConfirmVenueScreen> createState() => _ConfirmVenueScreenState();
}

class _ConfirmVenueScreenState extends State<ConfirmVenueScreen> {
  late Venue _chosen = widget.venues.first;

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      title: 'Is this where\nyou are stuck?',
      body:
          'We matched your location to one venue. Change it if we got it '
          'wrong.',
      actionLabel: 'Continue',
      onAction: () => Navigator.of(
        context,
      ).push(FadeThroughRoute<void>(child: LayoverTypeScreen(venue: _chosen))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final venue in widget.venues) ...[
            SelectRow(
              title: venue.name,
              subtitle: venue.subtitle,
              icon: FlowIcons.pin,
              selected: venue.id == _chosen.id,
              onTap: () => setState(() => _chosen = venue),
            ),
            SizedBox(height: 10 * s),
          ],
          Padding(
            padding: EdgeInsets.only(top: 6 * s),
            child: GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(FadeThroughRoute<void>(child: const SearchVenueScreen())),
              child: Text(
                'Neither - search for a venue',
                style: interTight(
                  size: 14 * s,
                  weight: 600,
                  height: 1.35,
                  color: AppColors.accentStrong,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────── L06 Search venue ───────────────────────

class SearchVenueScreen extends StatefulWidget {
  const SearchVenueScreen({super.key});

  @override
  State<SearchVenueScreen> createState() => _SearchVenueScreenState();
}

class _SearchVenueScreenState extends State<SearchVenueScreen> {
  final _query = TextEditingController();
  List<Venue> _results = const [];
  Venue? _chosen;

  @override
  void initState() {
    super.initState();
    _query.addListener(_search);
    WidgetsBinding.instance.addPostFrameCallback((_) => _search());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final flow = AppScope.of(context);
    final results = await flow.presenceService.searchVenues(_query.text);
    if (!mounted) return;
    setState(() {
      _results = results;
      // Keep a chosen venue only while it is still in the list, otherwise the
      // Continue button would submit something the user can no longer see.
      if (_chosen != null && !results.any((v) => v.id == _chosen!.id)) {
        _chosen = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);

    return FlowScaffold(
      title: 'Search venues',
      body: 'Pick the place you are actually stuck in.',
      actionLabel: 'Use this venue',
      onAction: _chosen == null
          ? null
          : () => Navigator.of(context).push(
              FadeThroughRoute<void>(child: LayoverTypeScreen(venue: _chosen!)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlowField(
            controller: _query,
            hint: 'Airport, station, office',
            autofocus: true,
          ),
          SizedBox(height: 14 * s),
          if (_results.isEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8 * s),
              child: Text(
                'Nothing matches that. Try the venue name on the signage.',
                style: interTight(
                  size: 14 * s,
                  weight: 400,
                  height: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          for (final venue in _results) ...[
            SelectRow(
              title: venue.name,
              subtitle: venue.subtitle,
              icon: FlowIcons.pin,
              selected: venue.id == _chosen?.id,
              onTap: () => setState(() => _chosen = venue),
            ),
            SizedBox(height: 10 * s),
          ],
        ],
      ),
    );
  }
}
