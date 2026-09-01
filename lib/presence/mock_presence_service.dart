import 'dart:math';

import 'presence_models.dart';
import 'presence_service.dart';

/// Stand in for geolocation and the venue backend, so the whole check-in flow
/// is walkable before either exists.
///
/// Knobs, chosen so every screen in the flow can be reached by hand:
///   * [permissionAnswer] decides what the fake OS prompt returns
///   * [detectionFails] empties the nearby list, which is what drives the
///     "we could not place you" path into manual search
class MockPresenceService implements PresenceService {
  MockPresenceService({
    this.latency = const Duration(milliseconds: 700),
    this.permissionAnswer = LocationPermission.granted,
    this.detectionFails = false,
  });

  final Duration latency;
  final LocationPermission permissionAnswer;
  final bool detectionFails;

  LocationPermission _status = LocationPermission.notAsked;

  static const _catalogue = <Venue>[
    Venue(
      id: 'bom-t2',
      name: 'Mumbai BOM - Terminal 2',
      type: LayoverType.airport,
      metresAway: 180,
    ),
    Venue(
      id: 'bom-t1',
      name: 'Mumbai BOM - Terminal 1',
      type: LayoverType.airport,
      metresAway: 1400,
    ),
    Venue(
      id: 'mmct',
      name: 'Mumbai Central',
      type: LayoverType.trainStation,
      metresAway: 6100,
    ),
    Venue(
      id: 'bandra-rto',
      name: 'Bandra RTO',
      type: LayoverType.govtOffice,
      metresAway: 9200,
    ),
    Venue(
      id: 'sessions-court',
      name: 'Sessions Court',
      type: LayoverType.juryDuty,
      metresAway: 11800,
    ),
  ];

  @override
  Future<LocationPermission> locationStatus() async => _status;

  @override
  Future<LocationPermission> requestLocation() async {
    await Future<void>.delayed(latency);
    _status = permissionAnswer;
    return _status;
  }

  @override
  Future<List<Venue>> nearbyVenues() async {
    await Future<void>.delayed(latency);
    if (_status != LocationPermission.granted) {
      throw const LocationException('Location is off.');
    }
    if (detectionFails) return const [];
    return _catalogue.take(2).toList(growable: false);
  }

  @override
  Future<List<Venue>> searchVenues(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _catalogue;
    return _catalogue
        .where(
          (v) =>
              v.name.toLowerCase().contains(q) ||
              v.type.label.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  @override
  Future<PresenceSession> checkIn(CheckInDraft draft) async {
    await Future<void>.delayed(latency);
    if (!draft.isComplete) {
      throw const LocationException('Finish the check-in first.');
    }
    final now = DateTime.now();
    return PresenceSession(
      venue: draft.venue!,
      type: draft.type!,
      vibe: draft.vibe!,
      checkedInAt: now,
      expiresAt: now.add(draft.duration!.span),
      duration: draft.duration!,
      statusLine: draft.statusLine,
    );
  }

  @override
  Future<PresenceSession> restretch(
    PresenceSession session,
    ExpectedDuration duration,
  ) async {
    await Future<void>.delayed(latency);
    // Measured from now, not from check-in: the user is answering "how much
    // longer", and anchoring to check-in would silently shorten a stretch made
    // late in a wait.
    return session.copyWith(
      expiresAt: DateTime.now().add(duration.span),
      duration: duration,
    );
  }

  @override
  Future<PresenceSession> checkOut(PresenceSession session) async {
    await Future<void>.delayed(latency);
    return session.copyWith(endedAt: DateTime.now());
  }

  @override
  Future<VenueCrowd> crowdAt(Venue venue, {required DateTime since}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    // Deterministic per venue so the number does not flicker between rebuilds,
    // then grows slowly with how long the user has been sitting there.
    final seed = venue.id.hashCode.toUnsigned(16);
    final base = 3 + (seed % 5);
    final minutesHere = DateTime.now().difference(since).inMinutes;
    final arrived = min(4, minutesHere ~/ 3);
    const pool = ['T', 'K', 'R', 'A', 'M', 'S'];
    return VenueCrowd(
      total: base + arrived,
      arrivedSince: arrived,
      initials: [for (var i = 0; i < 3; i++) pool[(seed + i) % pool.length]],
    );
  }
}
