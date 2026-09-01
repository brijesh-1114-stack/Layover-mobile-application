/// Domain types for the check-in flow.
///
/// Pure Dart on purpose: no Flutter imports, no clock reads, no I/O. A wait is
/// easy to reason about only while "how long is left" is a function of values
/// that were passed in, so every time-dependent answer here takes an explicit
/// `now`.
library;

/// Where someone is stuck.
///
/// Hospital is deliberately absent. Inferring a health context from a check-in
/// makes the record special-category data under GDPR Art. 9, which is a
/// disproportionate obligation for a feature that only needs to say "this
/// person is waiting somewhere".
enum LayoverType {
  airport('Airport'),
  trainStation('Train station'),
  govtOffice('Govt office'),
  juryDuty('Jury duty'),
  longQueue('Long queue'),
  other('Something else');

  const LayoverType(this.label);

  final String label;
}

/// How long the wait is expected to last.
///
/// [noIdea] is not a missing value - it is a real answer, and it resolves to a
/// concrete two hours so presence can still expire on its own. Someone who does
/// not know when they are leaving is exactly the person who will forget to
/// check out.
enum ExpectedDuration {
  halfHour('30 min', Duration(minutes: 30)),
  oneToTwo('1-2 hrs', Duration(hours: 2)),
  threePlus('3+ hrs', Duration(hours: 3)),
  noIdea('No idea', Duration(hours: 2));

  const ExpectedDuration(this.label, this.span);

  final String label;
  final Duration span;
}

/// What kind of contact someone is open to, which is what the feed filters on.
enum Vibe {
  quiet('Quiet company', 'Near people, not talking to them.'),
  chat('Down to chat', 'Happy to be waved at and to reply.'),
  looking('Just looking', 'Show me who is stuck here. No waves yet.');

  const Vibe(this.label, this.blurb);

  final String label;
  final String blurb;
}

/// A place someone can be stuck in.
class Venue {
  const Venue({
    required this.id,
    required this.name,
    required this.type,
    required this.metresAway,
  });

  final String id;
  final String name;
  final LayoverType type;
  final int metresAway;

  /// True when the device is inside the venue's own radius rather than merely
  /// near it. Only these can be auto-detected; anything further has to be
  /// chosen by hand, so we never plant someone in a building they can see but
  /// are not inside.
  bool get isHere => metresAway <= 300;

  String get distanceLabel => isHere
      ? 'within 300 m'
      : '${(metresAway / 1000).toStringAsFixed(1)} km away';

  String get subtitle => '${type.label} - $distanceLabel';
}

/// What the user has assembled so far while stepping through check-in.
class CheckInDraft {
  const CheckInDraft({
    this.venue,
    this.type,
    this.duration,
    this.vibe,
    this.statusLine,
  });

  final Venue? venue;
  final LayoverType? type;
  final ExpectedDuration? duration;
  final Vibe? vibe;
  final String? statusLine;

  /// The status line is optional, so it is not part of readiness.
  bool get isComplete =>
      venue != null && type != null && duration != null && vibe != null;

  CheckInDraft copyWith({
    Venue? venue,
    LayoverType? type,
    ExpectedDuration? duration,
    Vibe? vibe,
    String? statusLine,
    bool clearStatusLine = false,
  }) {
    return CheckInDraft(
      venue: venue ?? this.venue,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      vibe: vibe ?? this.vibe,
      statusLine: clearStatusLine ? null : (statusLine ?? this.statusLine),
    );
  }
}

/// A live check-in.
///
/// [expiresAt] is stored rather than derived from a duration, because the user
/// can stretch or cut the wait while it runs and the end time is the thing that
/// actually governs whether the card is still alive.
class PresenceSession {
  const PresenceSession({
    required this.venue,
    required this.type,
    required this.vibe,
    required this.checkedInAt,
    required this.expiresAt,
    required this.duration,
    this.statusLine,
    this.endedAt,
  });

  final Venue venue;
  final LayoverType type;
  final Vibe vibe;
  final DateTime checkedInAt;
  final DateTime expiresAt;
  final ExpectedDuration duration;
  final String? statusLine;

  /// Set when the user checks out by hand or leaves the geofence, which can
  /// happen well before [expiresAt].
  final DateTime? endedAt;

  bool get isEnded => endedAt != null;

  /// Time left at [now], floored at zero. A negative remainder is not a
  /// countdown, it is an expired card.
  Duration remaining(DateTime now) {
    if (endedAt != null) return Duration.zero;
    final left = expiresAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  bool isLive(DateTime now) => !isEnded && remaining(now) > Duration.zero;

  /// The last stretch of the wait, where the app should offer more time before
  /// the card disappears on its own.
  bool isEndingSoon(DateTime now) {
    final left = remaining(now);
    return left > Duration.zero && left <= const Duration(minutes: 10);
  }

  /// How much of the wait has burnt, 0 -> 1. Used to draw the countdown, so it
  /// is clamped: a stretched session must not report a negative fraction.
  double progress(DateTime now) {
    final total = expiresAt.difference(checkedInAt).inSeconds;
    if (total <= 0) return 1;
    final spent = now.difference(checkedInAt).inSeconds;
    return (spent / total).clamp(0.0, 1.0);
  }

  PresenceSession copyWith({
    DateTime? expiresAt,
    ExpectedDuration? duration,
    Vibe? vibe,
    DateTime? endedAt,
  }) {
    return PresenceSession(
      venue: venue,
      type: type,
      vibe: vibe ?? this.vibe,
      checkedInAt: checkedInAt,
      expiresAt: expiresAt ?? this.expiresAt,
      duration: duration ?? this.duration,
      statusLine: statusLine,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

/// Formats a remaining span the way the countdown reads it out.
///
/// Returns hours and minutes separately so the flip clock can animate each
/// digit on its own; a preformatted string would force the whole clock to
/// rebuild as one lump.
class CountdownParts {
  const CountdownParts(this.hours, this.minutes, this.seconds);

  /// Exact remainder, floored.
  ///
  /// Floored rather than rounded up because the seconds are on screen: a clock
  /// that reads 1:47:59 while claiming 48 minutes contradicts itself. The
  /// rounding that prose wants lives in [spoken] instead.
  factory CountdownParts.from(Duration left) {
    final total = left.inSeconds;
    return CountdownParts(total ~/ 3600, (total % 3600) ~/ 60, total % 60);
  }

  final int hours;
  final int minutes;
  final int seconds;

  String get hourDigit => hours.clamp(0, 9).toString();
  String get minuteTens => (minutes ~/ 10).toString();
  String get minuteOnes => (minutes % 10).toString();
  String get secondTens => (seconds ~/ 10).toString();
  String get secondOnes => (seconds % 10).toString();

  /// Long form, for headlines and body copy.
  ///
  /// Here the leftover seconds do round up - "1 min left" with 40 seconds on
  /// the clock reads as wrong in a sentence, even though it is right on a dial.
  String get spoken {
    final totalMinutes = ((hours * 3600 + minutes * 60 + seconds) / 60).ceil();
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (h == 0 && m == 0) return 'no time left';
    if (h == 0) return '$m min left';
    if (m == 0) return '$h hr left';
    return '$h hr $m min left';
  }
}
