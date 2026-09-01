import 'presence_models.dart';

/// What the OS told us about location access.
///
/// [deniedForever] is separate from [denied] because only one of them can be
/// fixed inside the app: a plain denial can be asked again, a permanent one
/// leaves Settings as the only route, and showing the wrong screen for either
/// sends the user in a circle.
enum LocationPermission { notAsked, granted, denied, deniedForever }

class LocationException implements Exception {
  const LocationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Backend seam for everything that needs the device's position or the server's
/// view of a venue.
///
/// The screens only ever talk to this, so swapping the mock for real
/// geolocation and a venue API changes nothing above it.
abstract interface class PresenceService {
  /// Asks the OS for location access. Returns whatever the user chose.
  Future<LocationPermission> requestLocation();

  /// Current permission without prompting, for screens that need to branch on
  /// entry.
  Future<LocationPermission> locationStatus();

  /// Venues near the device, nearest first. The first entry is only a
  /// suggestion - the user confirms it, because GPS at an airport is routinely
  /// off by a terminal.
  Future<List<Venue>> nearbyVenues();

  /// Venue lookup by free text, for when detection got it wrong.
  Future<List<Venue>> searchVenues(String query);

  /// Publishes the check-in. The server decides the timestamps so a device with
  /// a wrong clock cannot mint a session that outlives everyone else's.
  Future<PresenceSession> checkIn(CheckInDraft draft);

  /// Replaces the remaining time. Not additive: the user picks the new total,
  /// which is the only version of this that stays predictable when it is used
  /// twice.
  Future<PresenceSession> restretch(
    PresenceSession session,
    ExpectedDuration duration,
  );

  /// Ends the session now.
  Future<PresenceSession> checkOut(PresenceSession session);

  /// How many other people are currently checked in at [venue], and how many of
  /// those arrived after [since]. The card's live strip reports both.
  Future<VenueCrowd> crowdAt(Venue venue, {required DateTime since});
}

/// Who else is in limbo at a venue.
class VenueCrowd {
  const VenueCrowd({
    required this.total,
    required this.arrivedSince,
    required this.initials,
  });

  final int total;
  final int arrivedSince;

  /// Up to three initials for the avatar cluster. Initials rather than names or
  /// photos: nobody has agreed to be identified before a mutual wave.
  final List<String> initials;

  static const empty = VenueCrowd(total: 0, arrivedSince: 0, initials: []);
}
