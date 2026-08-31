# Layover — Phase 1: Presence Core Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship a working Flutter app where a user checks in at a venue with a type, duration, vibe and status line, appears in a live feed of others at that venue with accurate countdowns, and checks out — with zero ghost entries.

**Architecture:** Domain-first with a repository seam. All presence logic (expiry, staleness, sorting, filtering) lives in pure Dart with no I/O, fully unit-tested. `PresenceRepository` is an abstract interface; Phase 1 ships an in-memory implementation so the entire app is runnable and testable with no cloud account. Phase 2 swaps in Firestore behind the same interface without touching domain or UI.

**Tech Stack:** Flutter 3.47.2 / Dart 3.13.2, Riverpod (state), flutter_test + mocktail + fake_async (testing). No backend in Phase 1.

**Spec:** `Layover-PRD.md` (repo root)

---

## Assumptions (open questions answered by default)

These were raised in the PRD review and remain unanswered. The plan proceeds on these defaults. Each is cheap to reverse during Phase 1; none are cheap to reverse after Phase 3.

| # | Question | Assumed answer | Rationale |
|---|---|---|---|
| 1 | Identity model | Stable per-device user ID persisted locally; upgraded to server-issued auth in Phase 2 | Blocking (PRD 5.5) is impossible without identity that outlives a session. Ephemeral is a *presentation* choice, not a storage one. |
| 2 | Cold start | Venue allowlist — the app ships seeded to a small fixed venue set | An empty global feed kills the app. Concentrating supply is the only route to liquidity. |
| 3 | Contact exchange | Allowed, explicit and mutual, in Phase 3 | Users will paste handles into chat regardless. Better designed than routed around. |
| 4 | Hospital venue category | **Cut from MVP** | GDPR Art. 9 special-category health inference. See PRD review. |
| 5 | Notifications | Transactional only (wave received, chat expiring). No re-engagement pushes. | Honors PRD 4.4 while making the asynchronous wave mechanic actually function. |

---

## Global Constraints

- Dart SDK `^3.13.0`; Flutter stable `3.47.2`.
- Package name `layover`; org `com.layover`. Application ID `com.layover.app`.
- **No `DateTime.now()` inside domain code.** Every time-dependent function takes an explicit `DateTime now` parameter. This is what makes expiry testable without waiting for it.
- **The domain layer (`lib/domain/`) imports nothing from `package:flutter`.** Pure Dart only.
- Venue categories, verbatim, for MVP: Airport, Train Station, DMV/Govt Office, Jury Duty, Long Queue, Custom. Hospital is excluded per Assumption 4.
- Vibe values, verbatim: "Just want quiet company", "Down to chat". The PRD's third option ("Show me who's also stuck here") is the unfiltered default, not a vibe.
- A presence is gone when EITHER `expiresAt` has passed OR `lastHeartbeatAt` is older than 3 minutes. Both conditions, always.
- Every task ends with a commit.

---

## Phase Roadmap (whole PRD)

Phase 1 is detailed below. Later phases get their own plans, written when we reach them.

| Phase | Delivers | PRD sections | Blocked on |
|---|---|---|---|
| **1 — Presence Core** | Check-in, live feed, countdown, checkout. In-memory backend. | 5.1, 5.2, 5.4 (partial), 6.1–6.2, 7.2–7.4 | Nothing |
| **2 — Real Backend** | Firestore presence, anonymous auth, stable identity, venue resolution via Places API | 8, identity spine | Your Firebase + Google Cloud accounts |
| **3 — Connect** | Waves, mutual match, ephemeral chat, true deletion, contact exchange | 5.3, 6.3–6.5, 7.5–7.7 | Phase 2 |
| **4 — Location & Expiry** | Geofencing, auto-checkout, background limits, permission priming | 5.4, 7.9 | Phase 2 |
| **5 — Safety & Moderation** | Report/block backend, moderation queue, 24h SLA tooling, age gate, App Store compliance | 5.5, 7.10 | Phase 3. **Gates launch.** |
| **6 — Polish** | Rive dissolve animation, wave micro-interactions, onboarding | 5.4, 7.1 | Phase 4 |

---

## File Structure

```
lib/
  domain/                        # pure Dart, no Flutter imports
    layover_type.dart            # LayoverType enum + display metadata
    expected_duration.dart       # ExpectedDuration enum + Duration mapping
    vibe.dart                    # Vibe enum
    venue.dart                   # Venue value object
    presence.dart                # Presence value object
    presence_clock.dart          # expiry / staleness / countdown math
    presence_feed.dart           # sort + filter + live-presence selection
  data/
    presence_repository.dart     # abstract interface
    in_memory_presence_repository.dart
    local_user_id_store.dart     # stable device-scoped user id
    seed_venues.dart             # launch venue allowlist
  app/
    providers.dart               # Riverpod wiring
    check_in_controller.dart
    feed_controller.dart
  ui/
    check_in_screen.dart
    feed_screen.dart
    widgets/
      presence_card.dart
      countdown_text.dart
      empty_feed_view.dart
  main.dart
test/
  domain/
    expected_duration_test.dart
    presence_test.dart
    presence_clock_test.dart
    presence_feed_test.dart
  data/
    in_memory_presence_repository_test.dart
    local_user_id_store_test.dart
    seed_venues_test.dart
  app/
    check_in_controller_test.dart
    feed_controller_test.dart
  ui/
    check_in_screen_test.dart
    feed_screen_test.dart
```

Rationale: `domain/` holds every rule that has a right answer, so it is testable without a widget tree or a network. `data/` owns the seam Phase 2 replaces. `app/` is controllers only. `ui/` is rendering only.

---

### Task 0: Project Reset and Foundation

The current scaffold is the default counter app under the wrong package name (`practice_app`) and wrong application ID (`com.example.practice_app`). Application IDs are painful to change once a build is signed or published, so this is fixed now, before any real code exists.

**DESTRUCTIVE STEP:** Step 2 deletes the generated scaffold. `Layover-PRD.md` and `docs/` are copied to safety first and restored in Step 4. Nothing else in this directory is authored work — it was all produced by `flutter create` and is reproduced by Step 3.

**Files:**
- Delete: generated scaffold (`lib/`, `android/`, `ios/`, `web/`, `test/`, `pubspec.yaml`, etc.)
- Create: regenerated scaffold with correct identifiers
- Create: git repository with an initial commit

**Interfaces:**
- Consumes: nothing
- Produces: a `layover` Flutter package with application ID `com.layover.app`, a git repo with one commit, and Riverpod + test dependencies installed.

- [ ] **Step 1: Preserve the PRD and docs, then verify**

```bash
cd "D:/Projects/Practice Project Mobile app"
mkdir -p ../layover-preserve
cp Layover-PRD.md ../layover-preserve/
cp -r docs ../layover-preserve/
ls -R ../layover-preserve
```

Expected: `Layover-PRD.md` and `docs/` both present. Do not continue until this is confirmed.

- [ ] **Step 2: Remove the generated scaffold**

```bash
cd "D:/Projects/Practice Project Mobile app"
rm -rf lib android ios web test build .dart_tool
rm -f pubspec.yaml pubspec.lock analysis_options.yaml .metadata practice_app.iml
ls -A
```

Expected: only `Layover-PRD.md` and `docs/` remain.

- [ ] **Step 3: Regenerate with correct identifiers**

```bash
cd "D:/Projects/Practice Project Mobile app"
"C:/Users/designer/flutter/bin/flutter.bat" create --project-name layover --org com.layover --platforms android,ios,web .
```

Expected: `Wrote NN files.`

- [ ] **Step 4: Restore the PRD and confirm identifiers**

```bash
cd "D:/Projects/Practice Project Mobile app"
cp ../layover-preserve/Layover-PRD.md .
cp -r ../layover-preserve/docs .
grep applicationId android/app/build.gradle.kts
grep "^name:" pubspec.yaml
```

Expected: `applicationId = "com.layover.app"` and `name: layover`.

- [ ] **Step 5: Add dependencies**

```bash
cd "D:/Projects/Practice Project Mobile app"
"C:/Users/designer/flutter/bin/flutter.bat" pub add flutter_riverpod
"C:/Users/designer/flutter/bin/flutter.bat" pub add shared_preferences
"C:/Users/designer/flutter/bin/flutter.bat" pub add dev:mocktail
"C:/Users/designer/flutter/bin/flutter.bat" pub add dev:fake_async
```

Expected: each resolves and writes to `pubspec.yaml`. Let `pub add` choose versions compatible with the installed SDK — do not hand-pin them.

- [ ] **Step 6: Initialise git and commit the baseline**

```bash
cd "D:/Projects/Practice Project Mobile app"
git init -b main
git add -A
git commit -m "chore: scaffold layover flutter app with riverpod and test deps"
```

Expected: one commit. `flutter create` already wrote a suitable `.gitignore`.

- [ ] **Step 7: Verify the app still builds**

```bash
cd "D:/Projects/Practice Project Mobile app"
"C:/Users/designer/flutter/bin/flutter.bat" analyze
"C:/Users/designer/flutter/bin/flutter.bat" test
```

Expected: `No issues found.` and the default widget test passes.

---

### Task 1: Domain Enums

**Files:**
- Create: `lib/domain/layover_type.dart`
- Create: `lib/domain/expected_duration.dart`
- Create: `lib/domain/vibe.dart`
- Test: `test/domain/expected_duration_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `enum LayoverType { airport, trainStation, dmvGovtOffice, juryDuty, longQueue, custom }` with `String get label`
  - `enum ExpectedDuration { thirtyMin, oneToTwoHours, threePlusHours, unknown }` with `Duration? toDuration()` and `String get label`
  - `enum Vibe { quietCompany, downToChat }` with `String get label`

`ExpectedDuration.unknown` returns `null` from `toDuration()`. This is the PRD's unresolved "No idea" case (5.1 offers it; 5.4 ties the signature countdown to duration): there is no countdown to render, so the domain says so explicitly rather than inventing a number.

- [ ] **Step 1: Write the failing test**

Create `test/domain/expected_duration_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/domain/expected_duration.dart';

void main() {
  group('ExpectedDuration.toDuration', () {
    test('thirtyMin is 30 minutes', () {
      expect(ExpectedDuration.thirtyMin.toDuration(), const Duration(minutes: 30));
    });

    test('oneToTwoHours uses the upper bound of 2 hours', () {
      expect(ExpectedDuration.oneToTwoHours.toDuration(), const Duration(hours: 2));
    });

    test('threePlusHours uses a 3 hour floor', () {
      expect(ExpectedDuration.threePlusHours.toDuration(), const Duration(hours: 3));
    });

    test('unknown has no fixed duration', () {
      expect(ExpectedDuration.unknown.toDuration(), isNull);
    });
  });

  test('every duration has a non-empty label', () {
    for (final d in ExpectedDuration.values) {
      expect(d.label, isNotEmpty);
    }
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/expected_duration_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/domain/expected_duration.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/domain/expected_duration.dart`:

```dart
/// How long a user expects to be stuck.
///
/// [unknown] deliberately has no duration: the PRD offers "No idea" as a
/// check-in option but also ties the signature countdown to duration. Rather
/// than invent a number, the domain returns null and callers decide how to
/// present the absence of a countdown.
enum ExpectedDuration {
  thirtyMin,
  oneToTwoHours,
  threePlusHours,
  unknown;

  Duration? toDuration() => switch (this) {
        ExpectedDuration.thirtyMin => const Duration(minutes: 30),
        ExpectedDuration.oneToTwoHours => const Duration(hours: 2),
        ExpectedDuration.threePlusHours => const Duration(hours: 3),
        ExpectedDuration.unknown => null,
      };

  String get label => switch (this) {
        ExpectedDuration.thirtyMin => '30 min',
        ExpectedDuration.oneToTwoHours => '1-2 hrs',
        ExpectedDuration.threePlusHours => '3+ hrs',
        ExpectedDuration.unknown => 'No idea',
      };
}
```

Create `lib/domain/layover_type.dart`:

```dart
/// Where the user is stuck.
///
/// Hospital is intentionally absent. Presence at a named medical facility
/// leaks health status, which is special-category data under GDPR Art. 9.
/// See the PRD review before reinstating it.
enum LayoverType {
  airport,
  trainStation,
  dmvGovtOffice,
  juryDuty,
  longQueue,
  custom;

  String get label => switch (this) {
        LayoverType.airport => 'Airport',
        LayoverType.trainStation => 'Train Station',
        LayoverType.dmvGovtOffice => 'DMV / Govt Office',
        LayoverType.juryDuty => 'Jury Duty',
        LayoverType.longQueue => 'Long Queue',
        LayoverType.custom => 'Custom',
      };
}
```

Create `lib/domain/vibe.dart`:

```dart
/// What kind of contact the user is open to.
///
/// The PRD's third filter option ("Show me who's also stuck here") is not a
/// vibe — it is the unfiltered feed, represented everywhere as a null filter.
enum Vibe {
  quietCompany,
  downToChat;

  String get label => switch (this) {
        Vibe.quietCompany => 'Just want quiet company',
        Vibe.downToChat => 'Down to chat',
      };
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/expected_duration_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain test/domain
git commit -m "feat(domain): add layover type, duration and vibe enums"
```

---

### Task 2: Venue and Presence Value Objects

**Files:**
- Create: `lib/domain/venue.dart`
- Create: `lib/domain/presence.dart`
- Test: `test/domain/presence_test.dart`

**Interfaces:**
- Consumes: `LayoverType`, `ExpectedDuration`, `Vibe` from Task 1
- Produces:
  - `class Venue` with `final String id; final String name; final LayoverType type;`
  - `class Presence` with fields `userId`, `venueId`, `displayName`, `type`, `duration`, `statusLine` (nullable), `vibe`, `checkedInAt`, `expiresAt` (nullable), `lastHeartbeatAt`; a `Presence.checkIn({...})` factory deriving `expiresAt` from `duration`; and `copyWith`.

`expiresAt` is computed once at check-in rather than derived on every read, so that editing duration later (PRD 5.4) is an explicit act rather than a silent recomputation.

- [ ] **Step 1: Write the failing test**

Create `test/domain/presence_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  final now = DateTime.utc(2026, 8, 31, 12, 0);

  Presence build({
    ExpectedDuration duration = ExpectedDuration.thirtyMin,
    String userId = 'u1',
  }) {
    return Presence.checkIn(
      userId: userId,
      venueId: 'v1',
      displayName: 'Ash',
      type: LayoverType.airport,
      duration: duration,
      statusLine: 'Flight delayed',
      vibe: Vibe.downToChat,
      now: now,
    );
  }

  test('checkIn derives expiresAt from the duration', () {
    expect(build().expiresAt, now.add(const Duration(minutes: 30)));
  });

  test('checkIn leaves expiresAt null when duration is unknown', () {
    expect(build(duration: ExpectedDuration.unknown).expiresAt, isNull);
  });

  test('checkIn seeds lastHeartbeatAt to the check-in time', () {
    final p = build();
    expect(p.lastHeartbeatAt, now);
    expect(p.checkedInAt, now);
  });

  test('copyWith replaces only the named field', () {
    final p = build();
    final beat = now.add(const Duration(minutes: 5));
    final updated = p.copyWith(lastHeartbeatAt: beat);
    expect(updated.lastHeartbeatAt, beat);
    expect(updated.userId, p.userId);
    expect(updated.expiresAt, p.expiresAt);
  });

  test('presences with the same userId are equal', () {
    expect(build(userId: 'u1'), equals(build(userId: 'u1')));
    expect(build(userId: 'u1'), isNot(equals(build(userId: 'u2'))));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/domain/presence.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/domain/venue.dart`:

```dart
import 'layover_type.dart';

/// A place people get stuck. Phase 1 venues come from a seeded allowlist;
/// Phase 2 resolves them from a places provider.
class Venue {
  const Venue({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final LayoverType type;

  @override
  bool operator ==(Object other) => other is Venue && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
```

Create `lib/domain/presence.dart`:

```dart
import 'expected_duration.dart';
import 'layover_type.dart';
import 'vibe.dart';

/// One person's live presence at one venue.
///
/// Identity is [userId] and equality is by that alone: a user has exactly one
/// presence at a time, and the feed de-duplicates on it.
class Presence {
  const Presence({
    required this.userId,
    required this.venueId,
    required this.displayName,
    required this.type,
    required this.duration,
    required this.statusLine,
    required this.vibe,
    required this.checkedInAt,
    required this.expiresAt,
    required this.lastHeartbeatAt,
  });

  /// Creates a fresh presence, deriving [expiresAt] from [duration].
  ///
  /// [now] is injected rather than read from the clock so expiry is testable.
  factory Presence.checkIn({
    required String userId,
    required String venueId,
    required String displayName,
    required LayoverType type,
    required ExpectedDuration duration,
    required String? statusLine,
    required Vibe vibe,
    required DateTime now,
  }) {
    final window = duration.toDuration();
    return Presence(
      userId: userId,
      venueId: venueId,
      displayName: displayName,
      type: type,
      duration: duration,
      statusLine: statusLine,
      vibe: vibe,
      checkedInAt: now,
      expiresAt: window == null ? null : now.add(window),
      lastHeartbeatAt: now,
    );
  }

  final String userId;
  final String venueId;
  final String displayName;
  final LayoverType type;
  final ExpectedDuration duration;
  final String? statusLine;
  final Vibe vibe;
  final DateTime checkedInAt;

  /// When the stated wait runs out. Null when [duration] is unknown.
  final DateTime? expiresAt;

  /// Last time the client confirmed this user is still here.
  final DateTime lastHeartbeatAt;

  Presence copyWith({
    ExpectedDuration? duration,
    String? statusLine,
    Vibe? vibe,
    DateTime? expiresAt,
    DateTime? lastHeartbeatAt,
  }) {
    return Presence(
      userId: userId,
      venueId: venueId,
      displayName: displayName,
      type: type,
      duration: duration ?? this.duration,
      statusLine: statusLine ?? this.statusLine,
      vibe: vibe ?? this.vibe,
      checkedInAt: checkedInAt,
      expiresAt: expiresAt ?? this.expiresAt,
      lastHeartbeatAt: lastHeartbeatAt ?? this.lastHeartbeatAt,
    );
  }

  @override
  bool operator ==(Object other) => other is Presence && other.userId == userId;

  @override
  int get hashCode => userId.hashCode;
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain test/domain
git commit -m "feat(domain): add venue and presence value objects"
```

---

### Task 3: Presence Clock — Expiry, Staleness, Countdown

This task prevents the ghost-feed failure identified in the PRD review. A presence is live only if its stated wait has not elapsed **and** the client has checked in recently. Either condition alone is insufficient: expiry alone leaves users who force-quit visible for hours; heartbeat alone leaves users visible past a wait they said was 30 minutes.

**Files:**
- Create: `lib/domain/presence_clock.dart`
- Test: `test/domain/presence_clock_test.dart`

**Interfaces:**
- Consumes: `Presence` from Task 2
- Produces: `class PresenceClock` with `static const Duration staleAfter`, `static const Duration unknownDurationTtl`, and static methods `bool isLive(Presence, DateTime now)`, `Duration? remaining(Presence, DateTime now)`, `double? dissolveProgress(Presence, DateTime now)`

`dissolveProgress` returns 0.0 at check-in rising to 1.0 at expiry, and drives the boarding-pass dissolve animation in Phase 6. Defining it now keeps that animation a rendering concern rather than a logic one.

- [ ] **Step 1: Write the failing test**

Create `test/domain/presence_clock_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/presence_clock.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 31, 12, 0);

  Presence build({required ExpectedDuration duration}) => Presence.checkIn(
        userId: 'u1',
        venueId: 'v1',
        displayName: 'Ash',
        type: LayoverType.airport,
        duration: duration,
        statusLine: null,
        vibe: Vibe.downToChat,
        now: t0,
      );

  group('isLive', () {
    test('is live immediately after check-in', () {
      expect(PresenceClock.isLive(build(duration: ExpectedDuration.thirtyMin), t0), isTrue);
    });

    test('is not live once the stated wait has elapsed', () {
      final p = build(duration: ExpectedDuration.thirtyMin);
      expect(PresenceClock.isLive(p, t0.add(const Duration(minutes: 31))), isFalse);
    });

    test('is not live when the heartbeat has gone stale, even before expiry', () {
      final p = build(duration: ExpectedDuration.threePlusHours);
      final after = t0.add(PresenceClock.staleAfter + const Duration(seconds: 1));
      expect(PresenceClock.isLive(p, after), isFalse);
    });

    test('stays live past the stale window when the heartbeat keeps up', () {
      final p = build(duration: ExpectedDuration.threePlusHours);
      final later = t0.add(const Duration(minutes: 30));
      expect(PresenceClock.isLive(p.copyWith(lastHeartbeatAt: later), later), isTrue);
    });

    test('unknown duration expires on a TTL rather than living forever', () {
      final p = build(duration: ExpectedDuration.unknown);
      final beyond = t0.add(PresenceClock.unknownDurationTtl + const Duration(minutes: 1));
      expect(PresenceClock.isLive(p.copyWith(lastHeartbeatAt: beyond), beyond), isFalse);
    });
  });

  group('remaining', () {
    test('counts down toward expiry', () {
      final p = build(duration: ExpectedDuration.thirtyMin);
      expect(PresenceClock.remaining(p, t0.add(const Duration(minutes: 10))),
          const Duration(minutes: 20));
    });

    test('never returns a negative duration', () {
      final p = build(duration: ExpectedDuration.thirtyMin);
      expect(PresenceClock.remaining(p, t0.add(const Duration(hours: 5))), Duration.zero);
    });

    test('is null when there is no stated duration', () {
      expect(PresenceClock.remaining(build(duration: ExpectedDuration.unknown), t0), isNull);
    });
  });

  group('dissolveProgress', () {
    test('is 0 at check-in and 1 at expiry', () {
      final p = build(duration: ExpectedDuration.thirtyMin);
      expect(PresenceClock.dissolveProgress(p, t0), 0.0);
      expect(PresenceClock.dissolveProgress(p, t0.add(const Duration(minutes: 30))), 1.0);
    });

    test('is half way at the midpoint', () {
      final p = build(duration: ExpectedDuration.thirtyMin);
      expect(PresenceClock.dissolveProgress(p, t0.add(const Duration(minutes: 15))),
          closeTo(0.5, 0.001));
    });

    test('is null when there is no stated duration', () {
      expect(PresenceClock.dissolveProgress(build(duration: ExpectedDuration.unknown), t0),
          isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_clock_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/domain/presence_clock.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/domain/presence_clock.dart`:

```dart
import 'presence.dart';

/// All time-based rules about a [Presence].
///
/// Every method takes an explicit [now]. Nothing here reads the system clock,
/// which is what makes expiry behaviour testable without waiting for it.
class PresenceClock {
  const PresenceClock._();

  /// How long since the last heartbeat before we treat a user as gone.
  ///
  /// Guards against force-quits, dead batteries and lost signal — cases where
  /// no explicit checkout ever arrives. Without this the feed fills with
  /// people who left, which is worse than an empty feed: users wave at ghosts.
  static const Duration staleAfter = Duration(minutes: 3);

  /// Backstop expiry for users who said "No idea" how long they will be here.
  static const Duration unknownDurationTtl = Duration(hours: 4);

  /// Whether this presence should appear in a feed at [now].
  static bool isLive(Presence p, DateTime now) {
    if (now.difference(p.lastHeartbeatAt) > staleAfter) return false;

    final expiry = p.expiresAt ?? p.checkedInAt.add(unknownDurationTtl);
    return now.isBefore(expiry);
  }

  /// Time left on the stated wait, floored at zero.
  /// Null when the user gave no duration — there is nothing honest to show.
  static Duration? remaining(Presence p, DateTime now) {
    final expiry = p.expiresAt;
    if (expiry == null) return null;

    final left = expiry.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// 0.0 at check-in through 1.0 at expiry, clamped.
  /// Drives the boarding-pass dissolve animation. Null when no duration.
  static double? dissolveProgress(Presence p, DateTime now) {
    final expiry = p.expiresAt;
    if (expiry == null) return null;

    final total = expiry.difference(p.checkedInAt).inMilliseconds;
    if (total <= 0) return 1.0;

    final elapsed = now.difference(p.checkedInAt).inMilliseconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_clock_test.dart`
Expected: PASS, 11 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/presence_clock.dart test/domain/presence_clock_test.dart
git commit -m "feat(domain): add presence clock with expiry, staleness and dissolve progress"
```

---

### Task 4: Feed Selection — Filter and Sort

**Files:**
- Create: `lib/domain/presence_feed.dart`
- Test: `test/domain/presence_feed_test.dart`

**Interfaces:**
- Consumes: `Presence` (Task 2), `PresenceClock` (Task 3), `Vibe` (Task 1)
- Produces: `class PresenceFeed` with `static List<Presence> build({required Iterable<Presence> all, required String venueId, required String selfUserId, required Vibe? vibeFilter, required DateTime now})`

The PRD sorts by in-venue proximity (terminal, floor, section). That data does not exist without indoor positioning, which is out of scope. Phase 1 sorts by soonest expiry instead — whoever leaves first is most time-sensitive to reach, which is defensible and needs no data we do not have.

- [ ] **Step 1: Write the failing test**

Create `test/domain/presence_feed_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/presence_clock.dart';
import 'package:layover/domain/presence_feed.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 31, 12, 0);

  Presence p(
    String userId, {
    String venueId = 'v1',
    ExpectedDuration duration = ExpectedDuration.oneToTwoHours,
    Vibe vibe = Vibe.downToChat,
    DateTime? heartbeat,
  }) {
    final base = Presence.checkIn(
      userId: userId,
      venueId: venueId,
      displayName: userId,
      type: LayoverType.airport,
      duration: duration,
      statusLine: null,
      vibe: vibe,
      now: t0,
    );
    return heartbeat == null ? base : base.copyWith(lastHeartbeatAt: heartbeat);
  }

  List<String> ids(List<Presence> list) => list.map((e) => e.userId).toList();

  test('excludes the current user', () {
    final feed = PresenceFeed.build(
      all: [p('me'), p('other')],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: t0,
    );
    expect(ids(feed), ['other']);
  });

  test('excludes people at other venues', () {
    final feed = PresenceFeed.build(
      all: [p('here'), p('elsewhere', venueId: 'v2')],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: t0,
    );
    expect(ids(feed), ['here']);
  });

  test('excludes presences that are no longer live', () {
    final stale = p('gone', heartbeat: t0);
    final fresh = p('here', heartbeat: t0.add(const Duration(minutes: 10)));
    final now = t0.add(const Duration(minutes: 10));

    final feed = PresenceFeed.build(
      all: [stale, fresh],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: now,
    );
    expect(ids(feed), ['here']);
    expect(PresenceClock.isLive(stale, now), isFalse);
  });

  test('a null vibe filter returns everyone', () {
    final feed = PresenceFeed.build(
      all: [p('a', vibe: Vibe.quietCompany), p('b', vibe: Vibe.downToChat)],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: t0,
    );
    expect(ids(feed)..sort(), ['a', 'b']);
  });

  test('a vibe filter narrows to that vibe', () {
    final feed = PresenceFeed.build(
      all: [p('a', vibe: Vibe.quietCompany), p('b', vibe: Vibe.downToChat)],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: Vibe.quietCompany,
      now: t0,
    );
    expect(ids(feed), ['a']);
  });

  test('sorts soonest to leave first', () {
    final feed = PresenceFeed.build(
      all: [
        p('long', duration: ExpectedDuration.threePlusHours),
        p('short', duration: ExpectedDuration.thirtyMin),
        p('mid', duration: ExpectedDuration.oneToTwoHours),
      ],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: t0,
    );
    expect(ids(feed), ['short', 'mid', 'long']);
  });

  test('places unknown-duration users last', () {
    final feed = PresenceFeed.build(
      all: [
        p('unknown', duration: ExpectedDuration.unknown),
        p('short', duration: ExpectedDuration.thirtyMin),
      ],
      venueId: 'v1',
      selfUserId: 'me',
      vibeFilter: null,
      now: t0,
    );
    expect(ids(feed), ['short', 'unknown']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_feed_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/domain/presence_feed.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/domain/presence_feed.dart`:

```dart
import 'presence.dart';
import 'presence_clock.dart';
import 'vibe.dart';

/// Turns the raw set of presences into the list one user should see.
class PresenceFeed {
  const PresenceFeed._();

  /// Everyone else who is live at [venueId], soonest to leave first.
  ///
  /// A null [vibeFilter] means no filter — the PRD's "show me who's also stuck
  /// here", which is the absence of a filter rather than a vibe.
  ///
  /// Sorted by time remaining because in-venue proximity (terminal, floor,
  /// section) requires indoor positioning we do not have. Whoever leaves
  /// soonest is the most time-sensitive to reach.
  static List<Presence> build({
    required Iterable<Presence> all,
    required String venueId,
    required String selfUserId,
    required Vibe? vibeFilter,
    required DateTime now,
  }) {
    final visible = all
        .where((p) => p.userId != selfUserId)
        .where((p) => p.venueId == venueId)
        .where((p) => PresenceClock.isLive(p, now))
        .where((p) => vibeFilter == null || p.vibe == vibeFilter)
        .toList();

    visible.sort((a, b) {
      final ra = PresenceClock.remaining(a, now);
      final rb = PresenceClock.remaining(b, now);

      // Users with no stated duration sort last — we cannot rank them.
      if (ra == null && rb == null) return a.userId.compareTo(b.userId);
      if (ra == null) return 1;
      if (rb == null) return -1;

      final byTime = ra.compareTo(rb);
      return byTime != 0 ? byTime : a.userId.compareTo(b.userId);
    });

    return visible;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/domain/presence_feed_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/domain/presence_feed.dart test/domain/presence_feed_test.dart
git commit -m "feat(domain): add feed filtering and expiry-ordered sorting"
```

---

### Task 5: Presence Repository and In-Memory Implementation

**Files:**
- Create: `lib/data/presence_repository.dart`
- Create: `lib/data/in_memory_presence_repository.dart`
- Test: `test/data/in_memory_presence_repository_test.dart`

**Interfaces:**
- Consumes: `Presence` from Task 2
- Produces:
  - `abstract interface class PresenceRepository` with `Stream<List<Presence>> watchVenue(String venueId)`, `Future<void> checkIn(Presence)`, `Future<void> heartbeat({required String userId, required DateTime now})`, `Future<void> checkOut(String userId)`, `Future<void> dispose()`
  - `class InMemoryPresenceRepository implements PresenceRepository`

This is the seam Phase 2 replaces with Firestore. Nothing above this layer knows where presence is stored.

- [ ] **Step 1: Write the failing test**

Create `test/data/in_memory_presence_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/data/in_memory_presence_repository.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 31, 12, 0);

  Presence p(String userId, {String venueId = 'v1'}) => Presence.checkIn(
        userId: userId,
        venueId: venueId,
        displayName: userId,
        type: LayoverType.airport,
        duration: ExpectedDuration.thirtyMin,
        statusLine: null,
        vibe: Vibe.downToChat,
        now: t0,
      );

  late InMemoryPresenceRepository repo;

  setUp(() => repo = InMemoryPresenceRepository());
  tearDown(() => repo.dispose());

  test('watchVenue emits the current occupants immediately', () async {
    await repo.checkIn(p('a'));
    final first = await repo.watchVenue('v1').first;
    expect(first.map((e) => e.userId), ['a']);
  });

  test('watchVenue emits again when someone checks in', () async {
    final emissions = <List<String>>[];
    final sub = repo
        .watchVenue('v1')
        .listen((list) => emissions.add(list.map((e) => e.userId).toList()));

    await repo.checkIn(p('a'));
    await repo.checkIn(p('b'));
    await Future<void>.delayed(Duration.zero);

    expect(emissions.last..sort(), ['a', 'b']);
    await sub.cancel();
  });

  test('watchVenue only reports the requested venue', () async {
    await repo.checkIn(p('a'));
    await repo.checkIn(p('b', venueId: 'v2'));
    final list = await repo.watchVenue('v1').first;
    expect(list.map((e) => e.userId), ['a']);
  });

  test('checkIn replaces an existing presence for the same user', () async {
    await repo.checkIn(p('a'));
    await repo.checkIn(p('a'));
    expect(await repo.watchVenue('v1').first, hasLength(1));
  });

  test('heartbeat advances lastHeartbeatAt', () async {
    await repo.checkIn(p('a'));
    final beat = t0.add(const Duration(minutes: 2));
    await repo.heartbeat(userId: 'a', now: beat);

    final list = await repo.watchVenue('v1').first;
    expect(list.single.lastHeartbeatAt, beat);
  });

  test('heartbeat for an unknown user is a no-op', () async {
    await repo.heartbeat(userId: 'ghost', now: t0);
    expect(await repo.watchVenue('v1').first, isEmpty);
  });

  test('checkOut removes the presence', () async {
    await repo.checkIn(p('a'));
    await repo.checkOut('a');
    expect(await repo.watchVenue('v1').first, isEmpty);
  });

  test('moving venue clears the old venue feed', () async {
    await repo.checkIn(p('a', venueId: 'v1'));
    await repo.checkIn(p('a', venueId: 'v2'));
    expect(await repo.watchVenue('v1').first, isEmpty);
    expect(await repo.watchVenue('v2').first, hasLength(1));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/in_memory_presence_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/data/in_memory_presence_repository.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/data/presence_repository.dart`:

```dart
import '../domain/presence.dart';

/// Storage seam for presence.
///
/// Phase 1 ships an in-memory implementation so the app runs with no backend.
/// Phase 2 supplies a Firestore implementation behind this same interface;
/// nothing above this layer changes.
abstract interface class PresenceRepository {
  /// Live occupants of [venueId]. Emits the current set on subscribe and
  /// again on every change. Emissions are unfiltered — expiry and staleness
  /// are applied by PresenceFeed, not here.
  Stream<List<Presence>> watchVenue(String venueId);

  Future<void> checkIn(Presence presence);

  /// Confirms the user is still present. No-op for unknown users.
  Future<void> heartbeat({required String userId, required DateTime now});

  Future<void> checkOut(String userId);

  Future<void> dispose();
}
```

Create `lib/data/in_memory_presence_repository.dart`:

```dart
import 'dart:async';

import '../domain/presence.dart';
import 'presence_repository.dart';

/// Process-local presence store.
///
/// Real enough to develop and test the whole client against, with no cloud
/// account required. State does not survive a restart and nothing is shared
/// between devices — Phase 2 addresses both.
class InMemoryPresenceRepository implements PresenceRepository {
  final Map<String, Presence> _byUserId = {};
  final Map<String, StreamController<List<Presence>>> _controllers = {};

  @override
  Stream<List<Presence>> watchVenue(String venueId) {
    final controller = _controllers.putIfAbsent(
      venueId,
      () => StreamController<List<Presence>>.broadcast(),
    );

    // Replay current state to each new subscriber, then follow changes.
    return Stream<List<Presence>>.multi((listener) {
      listener.add(_occupantsOf(venueId));
      final sub = controller.stream.listen(
        listener.add,
        onError: listener.addError,
        onDone: listener.close,
      );
      listener.onCancel = sub.cancel;
    });
  }

  List<Presence> _occupantsOf(String venueId) =>
      _byUserId.values.where((p) => p.venueId == venueId).toList();

  void _emit(String venueId) {
    final c = _controllers[venueId];
    if (c != null && !c.isClosed) c.add(_occupantsOf(venueId));
  }

  @override
  Future<void> checkIn(Presence presence) async {
    final previous = _byUserId[presence.userId];
    _byUserId[presence.userId] = presence;

    // A user has one presence: leaving venue A on check-in to venue B must
    // refresh A's feed too, or they linger there as a ghost.
    if (previous != null && previous.venueId != presence.venueId) {
      _emit(previous.venueId);
    }
    _emit(presence.venueId);
  }

  @override
  Future<void> heartbeat({required String userId, required DateTime now}) async {
    final existing = _byUserId[userId];
    if (existing == null) return;

    _byUserId[userId] = existing.copyWith(lastHeartbeatAt: now);
    _emit(existing.venueId);
  }

  @override
  Future<void> checkOut(String userId) async {
    final removed = _byUserId.remove(userId);
    if (removed != null) _emit(removed.venueId);
  }

  @override
  Future<void> dispose() async {
    for (final c in _controllers.values) {
      await c.close();
    }
    _controllers.clear();
    _byUserId.clear();
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/in_memory_presence_repository_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data test/data
git commit -m "feat(data): add presence repository interface and in-memory implementation"
```

---

### Task 6: Stable Local User Identity

The PRD says no persistent profiles, but also requires report and block with a block list. Blocking is meaningless without an identifier that outlives a session — otherwise a blocked user reappears seconds later as someone new. This task establishes that spine. It is device-scoped in Phase 1 and upgraded to server-issued identity in Phase 2.

**Files:**
- Create: `lib/data/local_user_id_store.dart`
- Test: `test/data/local_user_id_store_test.dart`

**Interfaces:**
- Consumes: `shared_preferences`
- Produces: `class LocalUserIdStore` with `Future<String> getOrCreate()`

- [ ] **Step 1: Write the failing test**

Create `test/data/local_user_id_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/data/local_user_id_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('creates an id on first call', () async {
    expect(await LocalUserIdStore().getOrCreate(), isNotEmpty);
  });

  test('returns the same id on subsequent calls', () async {
    final store = LocalUserIdStore();
    final first = await store.getOrCreate();
    expect(await store.getOrCreate(), first);
  });

  test('persists across store instances', () async {
    final first = await LocalUserIdStore().getOrCreate();
    expect(await LocalUserIdStore().getOrCreate(), first);
  });

  test('honours an id already in storage', () async {
    SharedPreferences.setMockInitialValues({'layover.userId': 'existing-id'});
    expect(await LocalUserIdStore().getOrCreate(), 'existing-id');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/local_user_id_store_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/data/local_user_id_store.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/data/local_user_id_store.dart`:

```dart
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// A stable identifier for this install.
///
/// Layover presents itself as ephemeral, and it is: presence and chats expire.
/// But blocking (PRD 5.5) requires an identity that outlives a session,
/// otherwise a blocked user simply checks in again and reappears. Ephemerality
/// is a property of what we *show* and *retain*, not of who we can recognise.
///
/// Phase 2 replaces this with a server-issued identity so that a reinstall
/// cannot shed a block.
class LocalUserIdStore {
  static const String _key = 'layover.userId';

  Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final created = _generateId();
    await prefs.setString(_key, created);
    return created;
  }

  String _generateId() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random.secure();
    final chars = List.generate(24, (_) => alphabet[rng.nextInt(alphabet.length)]);
    return 'u_${chars.join()}';
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/local_user_id_store_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data/local_user_id_store.dart test/data/local_user_id_store_test.dart
git commit -m "feat(data): add stable device-scoped user identity"
```

---

### Task 7: Seeded Venues and Riverpod Wiring

Phase 1 ships a fixed venue list rather than location lookup. This makes the cold-start decision from Assumption 2 concrete: concentrating users at a small set of venues is the only route to a non-empty feed, and it removes the Places API dependency from Phase 1 entirely.

**Files:**
- Create: `lib/data/seed_venues.dart`
- Create: `lib/app/providers.dart`
- Test: `test/data/seed_venues_test.dart`

**Interfaces:**
- Consumes: `Venue`, `LayoverType` (Tasks 1-2), `PresenceRepository`, `InMemoryPresenceRepository` (Task 5), `LocalUserIdStore` (Task 6)
- Produces:
  - `const List<Venue> seedVenues`
  - `final nowProvider = Provider<DateTime Function()>(...)`
  - `final presenceRepositoryProvider = Provider<PresenceRepository>(...)`
  - `final userIdProvider = FutureProvider<String>(...)`
  - `final venuesProvider = Provider<List<Venue>>(...)`

`nowProvider` exists so tests can freeze time. Domain code never reads the clock; this is the single place the real clock enters the app.

- [ ] **Step 1: Write the failing test**

Create `test/data/seed_venues_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/data/seed_venues.dart';
import 'package:layover/domain/layover_type.dart';

void main() {
  test('seed venues are non-empty and uniquely identified', () {
    expect(seedVenues, isNotEmpty);
    expect(seedVenues.map((v) => v.id).toSet().length, seedVenues.length);
  });

  test('every seed venue has a name', () {
    for (final v in seedVenues) {
      expect(v.name, isNotEmpty, reason: 'venue ${v.id} has no name');
    }
  });

  test('no seed venue is a medical facility', () {
    // Hospital is excluded from MVP: presence at a named medical facility
    // leaks health status. See the PRD review.
    for (final v in seedVenues) {
      expect(
        v.name.toLowerCase(),
        isNot(anyOf(contains('hospital'), contains('clinic'), contains('medical'))),
      );
    }
  });

  test('seed venues cover more than one layover type', () {
    expect(seedVenues.map((v) => v.type).toSet().length, greaterThan(1));
  });

  test('LayoverType has no hospital member', () {
    expect(LayoverType.values.map((e) => e.name), isNot(contains('hospital')));
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/seed_venues_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/data/seed_venues.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/data/seed_venues.dart`:

```dart
import '../domain/layover_type.dart';
import '../domain/venue.dart';

/// The venues Layover launches at.
///
/// A proximity app needs two strangers at the same place in the same hour.
/// Spread across every venue on earth that never happens, so Phase 1 ships a
/// deliberately narrow list and concentrates whatever supply exists. Phase 2
/// adds location-resolved venues once there is a reason to.
const List<Venue> seedVenues = [
  Venue(id: 'bom-t2', name: 'Mumbai BOM - Terminal 2', type: LayoverType.airport),
  Venue(id: 'del-t3', name: 'Delhi DEL - Terminal 3', type: LayoverType.airport),
  Venue(id: 'blr-t1', name: 'Bengaluru BLR - Terminal 1', type: LayoverType.airport),
  Venue(id: 'csmt', name: 'Mumbai CSMT Station', type: LayoverType.trainStation),
  Venue(id: 'rto-andheri', name: 'Andheri RTO', type: LayoverType.dmvGovtOffice),
];
```

Create `lib/app/providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/in_memory_presence_repository.dart';
import '../data/local_user_id_store.dart';
import '../data/presence_repository.dart';
import '../data/seed_venues.dart';
import '../domain/venue.dart';

/// The one place the real clock enters the app. Domain code never reads it;
/// tests override this provider to freeze time.
final nowProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final presenceRepositoryProvider = Provider<PresenceRepository>((ref) {
  final repo = InMemoryPresenceRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final userIdProvider = FutureProvider<String>((ref) {
  return LocalUserIdStore().getOrCreate();
});

final venuesProvider = Provider<List<Venue>>((ref) => seedVenues);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/data/seed_venues_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/data/seed_venues.dart lib/app/providers.dart test/data/seed_venues_test.dart
git commit -m "feat(app): add seeded venues and riverpod wiring"
```

---

### Task 8: Check-In Controller

**Files:**
- Create: `lib/app/check_in_controller.dart`
- Test: `test/app/check_in_controller_test.dart`

**Interfaces:**
- Consumes: `PresenceRepository` (Task 5), `Presence` (Task 2), enums (Task 1), `nowProvider` / `presenceRepositoryProvider` / `userIdProvider` (Task 7)
- Produces:
  - `class CheckInState` with `venue`, `type`, `duration`, `statusLine`, `vibe`, `isSubmitting`, and `bool get canSubmit`
  - `class CheckInController extends Notifier<CheckInState>` with `selectVenue`, `selectType`, `selectDuration`, `setStatusLine`, `selectVibe`, `Future<Presence?> submit()`, `Future<void> checkOut()`, and `static const int statusLineMaxLength = 120`
  - `final checkInControllerProvider = NotifierProvider<CheckInController, CheckInState>(CheckInController.new)`

The status line is capped at 120 characters — the PRD calls it "one sentence" but gives no limit, and an unbounded string breaks card layout.

- [ ] **Step 1: Write the failing test**

Create `test/app/check_in_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/app/check_in_controller.dart';
import 'package:layover/app/providers.dart';
import 'package:layover/data/in_memory_presence_repository.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/venue.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime.utc(2026, 8, 31, 12, 0);
  const venue = Venue(id: 'v1', name: 'Test Venue', type: LayoverType.airport);

  late InMemoryPresenceRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = InMemoryPresenceRepository();
    container = ProviderContainer(overrides: [
      presenceRepositoryProvider.overrideWithValue(repo),
      nowProvider.overrideWithValue(() => t0),
      userIdProvider.overrideWith((ref) async => 'me'),
    ]);
  });

  tearDown(() {
    container.dispose();
    repo.dispose();
  });

  CheckInController controller() => container.read(checkInControllerProvider.notifier);
  CheckInState state() => container.read(checkInControllerProvider);

  test('cannot submit until venue, type and duration are chosen', () {
    expect(state().canSubmit, isFalse);

    controller().selectVenue(venue);
    controller().selectDuration(ExpectedDuration.thirtyMin);
    expect(state().canSubmit, isTrue);
  });

  test('submit writes a presence to the repository', () async {
    controller()
      ..selectVenue(venue)
      ..selectType(LayoverType.airport)
      ..selectDuration(ExpectedDuration.thirtyMin)
      ..setStatusLine('Flight delayed')
      ..selectVibe(Vibe.quietCompany);

    expect(await controller().submit(), isNotNull);

    final occupants = await repo.watchVenue('v1').first;
    expect(occupants.single.userId, 'me');
    expect(occupants.single.statusLine, 'Flight delayed');
    expect(occupants.single.vibe, Vibe.quietCompany);
    expect(occupants.single.expiresAt, t0.add(const Duration(minutes: 30)));
  });

  test('submit returns null when the form is incomplete', () async {
    expect(await controller().submit(), isNull);
    expect(await repo.watchVenue('v1').first, isEmpty);
  });

  test('status line is trimmed and capped', () {
    controller().setStatusLine('  ${'x' * 200}  ');
    expect(state().statusLine.length, CheckInController.statusLineMaxLength);
  });

  test('an empty status line is stored as null on the presence', () async {
    controller()
      ..selectVenue(venue)
      ..selectDuration(ExpectedDuration.thirtyMin)
      ..setStatusLine('   ');

    await controller().submit();
    final occupants = await repo.watchVenue('v1').first;
    expect(occupants.single.statusLine, isNull);
  });

  test('checkOut removes the presence', () async {
    controller()
      ..selectVenue(venue)
      ..selectDuration(ExpectedDuration.thirtyMin);
    await controller().submit();

    await controller().checkOut();
    expect(await repo.watchVenue('v1').first, isEmpty);
  });

  test('selecting a venue pre-fills the layover type', () {
    controller().selectVenue(venue);
    expect(state().type, LayoverType.airport);
  });

  test('vibe defaults to downToChat', () {
    expect(state().vibe, Vibe.downToChat);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/app/check_in_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/app/check_in_controller.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/app/check_in_controller.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expected_duration.dart';
import '../domain/layover_type.dart';
import '../domain/presence.dart';
import '../domain/venue.dart';
import '../domain/vibe.dart';
import 'providers.dart';

/// The check-in form as the user fills it in.
class CheckInState {
  const CheckInState({
    this.venue,
    this.type,
    this.duration,
    this.statusLine = '',
    this.vibe = Vibe.downToChat,
    this.isSubmitting = false,
  });

  final Venue? venue;
  final LayoverType? type;
  final ExpectedDuration? duration;
  final String statusLine;
  final Vibe vibe;
  final bool isSubmitting;

  bool get canSubmit =>
      venue != null && type != null && duration != null && !isSubmitting;

  CheckInState copyWith({
    Venue? venue,
    LayoverType? type,
    ExpectedDuration? duration,
    String? statusLine,
    Vibe? vibe,
    bool? isSubmitting,
  }) {
    return CheckInState(
      venue: venue ?? this.venue,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      statusLine: statusLine ?? this.statusLine,
      vibe: vibe ?? this.vibe,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CheckInController extends Notifier<CheckInState> {
  /// The PRD asks for "one sentence". Unbounded text breaks card layout, so
  /// the domain gets a hard limit rather than a hopeful placeholder.
  static const int statusLineMaxLength = 120;

  @override
  CheckInState build() => const CheckInState();

  void selectVenue(Venue venue) {
    // Selecting a venue pre-fills the type; the user can still override it.
    state = state.copyWith(venue: venue, type: state.type ?? venue.type);
  }

  void selectType(LayoverType type) => state = state.copyWith(type: type);

  void selectDuration(ExpectedDuration duration) =>
      state = state.copyWith(duration: duration);

  void selectVibe(Vibe vibe) => state = state.copyWith(vibe: vibe);

  void setStatusLine(String value) {
    final trimmed = value.trim();
    final capped = trimmed.length > statusLineMaxLength
        ? trimmed.substring(0, statusLineMaxLength)
        : trimmed;
    state = state.copyWith(statusLine: capped);
  }

  /// Writes the presence. Returns null when the form is incomplete.
  Future<Presence?> submit() async {
    if (!state.canSubmit) return null;

    state = state.copyWith(isSubmitting: true);
    try {
      final userId = await ref.read(userIdProvider.future);
      final now = ref.read(nowProvider)();

      final presence = Presence.checkIn(
        userId: userId,
        venueId: state.venue!.id,
        displayName: _displayNameFor(userId),
        type: state.type!,
        duration: state.duration!,
        statusLine: state.statusLine.isEmpty ? null : state.statusLine,
        vibe: state.vibe,
        now: now,
      );

      await ref.read(presenceRepositoryProvider).checkIn(presence);
      return presence;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> checkOut() async {
    final userId = await ref.read(userIdProvider.future);
    await ref.read(presenceRepositoryProvider).checkOut(userId);
  }

  /// No profiles in MVP, so the display name is derived from the id rather
  /// than collected. Phase 3 lets matched users reveal more.
  String _displayNameFor(String userId) {
    final tail = userId.length >= 4 ? userId.substring(userId.length - 4) : userId;
    return 'Traveller $tail';
  }
}

final checkInControllerProvider =
    NotifierProvider<CheckInController, CheckInState>(CheckInController.new);
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/app/check_in_controller_test.dart`
Expected: PASS, 8 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/app/check_in_controller.dart test/app/check_in_controller_test.dart
git commit -m "feat(app): add check-in controller with validation and submission"
```

---

### Task 9: Feed Controller with Heartbeat

**Files:**
- Create: `lib/app/feed_controller.dart`
- Test: `test/app/feed_controller_test.dart`

**Interfaces:**
- Consumes: `PresenceFeed` (Task 4), `PresenceRepository` (Task 5), providers (Task 7)
- Produces:
  - `final vibeFilterProvider = StateProvider<Vibe?>((ref) => null)`
  - `final venueFeedProvider = StreamProvider.family<List<Presence>, String>(...)`
  - `class HeartbeatService` with `static const Duration interval`, `void start(String userId)`, `void stop()`
  - `final heartbeatServiceProvider = Provider<HeartbeatService>(...)`

The heartbeat is what makes staleness detection work: without a client pulse, `PresenceClock.staleAfter` never trips and everyone looks permanently present. The interval is short enough that one dropped beat does not evict a live user.

- [ ] **Step 1: Write the failing test**

Create `test/app/feed_controller_test.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/app/feed_controller.dart';
import 'package:layover/app/providers.dart';
import 'package:layover/data/in_memory_presence_repository.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/presence_clock.dart';
import 'package:layover/domain/vibe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime.utc(2026, 8, 31, 12, 0);

  Presence p(String userId, {Vibe vibe = Vibe.downToChat}) => Presence.checkIn(
        userId: userId,
        venueId: 'v1',
        displayName: userId,
        type: LayoverType.airport,
        duration: ExpectedDuration.oneToTwoHours,
        statusLine: null,
        vibe: vibe,
        now: t0,
      );

  late InMemoryPresenceRepository repo;
  late ProviderContainer container;
  DateTime now = t0;

  setUp(() {
    now = t0;
    repo = InMemoryPresenceRepository();
    container = ProviderContainer(overrides: [
      presenceRepositoryProvider.overrideWithValue(repo),
      nowProvider.overrideWithValue(() => now),
      userIdProvider.overrideWith((ref) async => 'me'),
    ]);
  });

  tearDown(() {
    container.dispose();
    repo.dispose();
  });

  test('feed excludes self and shows other occupants', () async {
    await repo.checkIn(p('me'));
    await repo.checkIn(p('other'));

    final list = await container.read(venueFeedProvider('v1').future);
    expect(list.map((e) => e.userId), ['other']);
  });

  test('feed applies the vibe filter', () async {
    await repo.checkIn(p('quiet', vibe: Vibe.quietCompany));
    await repo.checkIn(p('chatty', vibe: Vibe.downToChat));

    container.read(vibeFilterProvider.notifier).state = Vibe.quietCompany;

    final list = await container.read(venueFeedProvider('v1').future);
    expect(list.map((e) => e.userId), ['quiet']);
  });

  test('feed drops presences whose heartbeat went stale', () async {
    await repo.checkIn(p('other'));
    now = t0.add(PresenceClock.staleAfter + const Duration(seconds: 1));

    expect(await container.read(venueFeedProvider('v1').future), isEmpty);
  });

  test('heartbeat pulses the repository', () async {
    await repo.checkIn(p('me'));
    final service = HeartbeatService(repository: repo, now: () => now);

    now = t0.add(const Duration(minutes: 1));
    await service.pulse('me');

    final list = await repo.watchVenue('v1').first;
    expect(list.single.lastHeartbeatAt, now);
  });

  test('one missed beat is survivable within the stale window', () {
    expect(HeartbeatService.interval * 2, lessThan(PresenceClock.staleAfter));
  });

  test('stop cancels the timer so no further pulses occur', () async {
    await repo.checkIn(p('me'));
    final service = HeartbeatService(repository: repo, now: () => now);
    service.start('me');
    service.stop();
    expect(service.isRunning, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/app/feed_controller_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/app/feed_controller.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/app/feed_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/presence_repository.dart';
import '../domain/presence.dart';
import '../domain/presence_clock.dart';
import '../domain/presence_feed.dart';
import '../domain/vibe.dart';
import 'providers.dart';

/// Null means no filter — the PRD's "show me who's also stuck here".
final vibeFilterProvider = StateProvider<Vibe?>((ref) => null);

/// The list one user should see at one venue.
final venueFeedProvider =
    StreamProvider.family<List<Presence>, String>((ref, venueId) async* {
  final repo = ref.watch(presenceRepositoryProvider);
  final now = ref.watch(nowProvider);
  final filter = ref.watch(vibeFilterProvider);
  final selfId = await ref.watch(userIdProvider.future);

  await for (final all in repo.watchVenue(venueId)) {
    yield PresenceFeed.build(
      all: all,
      venueId: venueId,
      selfUserId: selfId,
      vibeFilter: filter,
      now: now(),
    );
  }
});

/// Tells the backend this user is still here.
///
/// Without this pulse [PresenceClock.staleAfter] never trips and departed
/// users stay visible until their stated wait runs out — the ghost feed.
class HeartbeatService {
  HeartbeatService({
    required PresenceRepository repository,
    required DateTime Function() now,
  })  : _repository = repository,
        _now = now;

  /// One third of the stale window, so a single dropped beat does not evict
  /// a user who is still present.
  static const Duration interval = Duration(minutes: 1);

  final PresenceRepository _repository;
  final DateTime Function() _now;
  Timer? _timer;

  bool get isRunning => _timer != null;

  /// Sends one heartbeat immediately. Exposed so tests do not need timers.
  Future<void> pulse(String userId) =>
      _repository.heartbeat(userId: userId, now: _now());

  void start(String userId) {
    stop();
    _timer = Timer.periodic(interval, (_) => pulse(userId));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

final heartbeatServiceProvider = Provider<HeartbeatService>((ref) {
  final service = HeartbeatService(
    repository: ref.watch(presenceRepositoryProvider),
    now: ref.watch(nowProvider),
  );
  ref.onDispose(service.stop);
  return service;
});
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/app/feed_controller_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/app/feed_controller.dart test/app/feed_controller_test.dart
git commit -m "feat(app): add feed controller and presence heartbeat"
```

---

### Task 10: Feed Screen, Presence Card and Empty State

The empty state is not a polish item. At launch it is the screen most users will see, because liquidity does not exist yet. It is designed deliberately rather than defaulting to a blank list.

This task comes before the check-in screen so that `CheckInScreen` can navigate to a real `FeedScreen` rather than a stub.

**Files:**
- Create: `lib/ui/feed_screen.dart`
- Create: `lib/ui/widgets/presence_card.dart`
- Create: `lib/ui/widgets/countdown_text.dart`
- Create: `lib/ui/widgets/empty_feed_view.dart`
- Test: `test/ui/feed_screen_test.dart`

**Interfaces:**
- Consumes: `venueFeedProvider`, `vibeFilterProvider`, `heartbeatServiceProvider` (Task 9), `checkInControllerProvider` (Task 8), `PresenceClock` (Task 3)
- Produces: `class FeedScreen extends ConsumerWidget` taking `{required String venueId}`

- [ ] **Step 1: Write the failing test**

Create `test/ui/feed_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/app/providers.dart';
import 'package:layover/data/in_memory_presence_repository.dart';
import 'package:layover/domain/expected_duration.dart';
import 'package:layover/domain/layover_type.dart';
import 'package:layover/domain/presence.dart';
import 'package:layover/domain/vibe.dart';
import 'package:layover/ui/feed_screen.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 31, 12, 0);
  late InMemoryPresenceRepository repo;

  setUp(() => repo = InMemoryPresenceRepository());
  tearDown(() => repo.dispose());

  Presence p(String userId, {String? status}) => Presence.checkIn(
        userId: userId,
        venueId: 'v1',
        displayName: userId,
        type: LayoverType.airport,
        duration: ExpectedDuration.thirtyMin,
        statusLine: status,
        vibe: Vibe.downToChat,
        now: t0,
      );

  Widget harness() {
    return ProviderScope(
      overrides: [
        presenceRepositoryProvider.overrideWithValue(repo),
        nowProvider.overrideWithValue(() => t0),
        userIdProvider.overrideWith((ref) async => 'me'),
      ],
      child: const MaterialApp(home: FeedScreen(venueId: 'v1')),
    );
  }

  testWidgets('shows the empty state when nobody else is here', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('No one else here yet'), findsOneWidget);
  });

  testWidgets('renders a card per occupant with their status line', (tester) async {
    await repo.checkIn(p('other', status: 'Flight delayed'));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('other'), findsOneWidget);
    expect(find.text('Flight delayed'), findsOneWidget);
  });

  testWidgets('shows a countdown for a stated duration', (tester) async {
    await repo.checkIn(p('other'));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('30m left'), findsOneWidget);
  });

  testWidgets('does not render the current user', (tester) async {
    await repo.checkIn(p('me'));

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('me'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/ui/feed_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/ui/feed_screen.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/ui/widgets/countdown_text.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/presence.dart';
import '../../domain/presence_clock.dart';

/// Time left on someone's stated wait.
///
/// Says nothing definite when the user answered "No idea" — inventing a number
/// would be dishonest, and honesty about duration is the product's premise.
class CountdownText extends StatelessWidget {
  const CountdownText({super.key, required this.presence, required this.now});

  final Presence presence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final left = PresenceClock.remaining(presence, now);
    if (left == null) {
      return Text('No idea how long',
          style: Theme.of(context).textTheme.labelMedium);
    }

    final hours = left.inHours;
    final minutes = left.inMinutes.remainder(60);
    final label = hours > 0 ? '${hours}h ${minutes}m left' : '${minutes}m left';

    return Text(label, style: Theme.of(context).textTheme.labelMedium);
  }
}
```

Create `lib/ui/widgets/presence_card.dart`:

```dart
import 'package:flutter/material.dart';

import '../../domain/presence.dart';
import 'countdown_text.dart';

class PresenceCard extends StatelessWidget {
  const PresenceCard({super.key, required this.presence, required this.now});

  final Presence presence;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final initial = presence.displayName.isEmpty
        ? '?'
        : presence.displayName.substring(0, 1).toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(child: Text(initial)),
        title: Text(presence.displayName),
        subtitle: presence.statusLine == null ? null : Text(presence.statusLine!),
        trailing: CountdownText(presence: presence, now: now),
      ),
    );
  }
}
```

Create `lib/ui/widgets/empty_feed_view.dart`:

```dart
import 'package:flutter/material.dart';

/// What a user sees when nobody else is checked in.
///
/// At launch this is the most-viewed screen in the app, because liquidity does
/// not exist yet. It is designed as a real state rather than an accident: it
/// tells the truth and it does not pretend someone is coming.
class EmptyFeedView extends StatelessWidget {
  const EmptyFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty, size: 48),
            const SizedBox(height: 16),
            Text(
              'No one else here yet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You are checked in. If someone else gets stuck here, '
              'they will show up in this list.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

Create `lib/ui/feed_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/check_in_controller.dart';
import '../app/feed_controller.dart';
import '../app/providers.dart';
import '../domain/vibe.dart';
import 'widgets/empty_feed_view.dart';
import 'widgets/presence_card.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(venueFeedProvider(venueId));
    final filter = ref.watch(vibeFilterProvider);
    final now = ref.watch(nowProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Limbo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'I am done waiting',
            onPressed: () async {
              ref.read(heartbeatServiceProvider).stop();
              await ref.read(checkInControllerProvider.notifier).checkOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Everyone'),
                  selected: filter == null,
                  onSelected: (_) =>
                      ref.read(vibeFilterProvider.notifier).state = null,
                ),
                ...Vibe.values.map(
                  (v) => ChoiceChip(
                    label: Text(v.label),
                    selected: filter == v,
                    onSelected: (_) =>
                        ref.read(vibeFilterProvider.notifier).state = v,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: feed.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Could not load: $e')),
              data: (list) {
                if (list.isEmpty) return const EmptyFeedView();
                return ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      PresenceCard(presence: list[i], now: now),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/ui/feed_screen_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/ui test/ui
git commit -m "feat(ui): add limbo feed with presence cards, filters and empty state"
```

---

### Task 11: Check-In Screen and App Entry Point

**Files:**
- Create: `lib/ui/check_in_screen.dart`
- Modify: `lib/main.dart` (replace the generated counter app entirely)
- Delete: `test/widget_test.dart` (tests the counter app, which no longer exists)
- Test: `test/ui/check_in_screen_test.dart`

**Interfaces:**
- Consumes: `checkInControllerProvider` (Task 8), `venuesProvider`, `nowProvider` (Task 7), `heartbeatServiceProvider` (Task 9), `FeedScreen` (Task 10)
- Produces: `class CheckInScreen extends ConsumerWidget`, `class LayoverApp extends StatelessWidget`

- [ ] **Step 1: Write the failing test**

Create `test/ui/check_in_screen_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layover/app/providers.dart';
import 'package:layover/data/in_memory_presence_repository.dart';
import 'package:layover/ui/check_in_screen.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 31, 12, 0);
  late InMemoryPresenceRepository repo;

  setUp(() => repo = InMemoryPresenceRepository());
  tearDown(() => repo.dispose());

  Widget harness() {
    return ProviderScope(
      overrides: [
        presenceRepositoryProvider.overrideWithValue(repo),
        nowProvider.overrideWithValue(() => t0),
        userIdProvider.overrideWith((ref) async => 'me'),
      ],
      child: const MaterialApp(home: CheckInScreen()),
    );
  }

  testWidgets('renders the seeded venues', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Mumbai BOM - Terminal 2'), findsOneWidget);
    expect(find.text('Andheri RTO'), findsOneWidget);
  });

  testWidgets('check-in button is disabled until the form is complete',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'I am stuck here'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting venue and duration enables check-in', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mumbai BOM - Terminal 2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('30 min'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'I am stuck here'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('does not offer a hospital option', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.textContaining('Hospital'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `"C:/Users/designer/flutter/bin/flutter.bat" test test/ui/check_in_screen_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:layover/ui/check_in_screen.dart'`

- [ ] **Step 3: Write the implementation**

Create `lib/ui/check_in_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/check_in_controller.dart';
import '../app/feed_controller.dart';
import '../app/providers.dart';
import '../domain/expected_duration.dart';
import '../domain/vibe.dart';
import 'feed_screen.dart';

class CheckInScreen extends ConsumerWidget {
  const CheckInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venues = ref.watch(venuesProvider);
    final state = ref.watch(checkInControllerProvider);
    final controller = ref.read(checkInControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Where are you stuck?')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionLabel('Venue'),
          ...venues.map(
            (v) => RadioListTile<String>(
              value: v.id,
              groupValue: state.venue?.id,
              title: Text(v.name),
              subtitle: Text(v.type.label),
              onChanged: (_) => controller.selectVenue(v),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('How long?'),
          Wrap(
            spacing: 8,
            children: ExpectedDuration.values
                .map((d) => ChoiceChip(
                      label: Text(d.label),
                      selected: state.duration == d,
                      onSelected: (_) => controller.selectDuration(d),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Vibe'),
          Wrap(
            spacing: 8,
            children: Vibe.values
                .map((v) => ChoiceChip(
                      label: Text(v.label),
                      selected: state.vibe == v,
                      onSelected: (_) => controller.selectVibe(v),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Status (optional)'),
          TextField(
            maxLength: CheckInController.statusLineMaxLength,
            decoration: const InputDecoration(
              hintText: 'Flight delayed to Mumbai, bored out of my mind',
              border: OutlineInputBorder(),
            ),
            onChanged: controller.setStatusLine,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: state.canSubmit
                ? () async {
                    final presence = await controller.submit();
                    if (presence == null || !context.mounted) return;
                    ref.read(heartbeatServiceProvider).start(presence.userId);
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FeedScreen(venueId: presence.venueId),
                      ),
                    );
                  }
                : null,
            child: const Text('I am stuck here'),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
```

Replace `lib/main.dart` entirely:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/check_in_screen.dart';

void main() {
  runApp(const ProviderScope(child: LayoverApp()));
}

class LayoverApp extends StatelessWidget {
  const LayoverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layover',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2B5CE6)),
        useMaterial3: true,
      ),
      home: const CheckInScreen(),
    );
  }
}
```

Remove the generated counter test:

```bash
rm -f test/widget_test.dart
```

- [ ] **Step 4: Run the full suite and the analyzer**

```bash
"C:/Users/designer/flutter/bin/flutter.bat" test
"C:/Users/designer/flutter/bin/flutter.bat" analyze
```

Expected: every suite PASS, and `No issues found.`

**Known risk:** `RadioListTile`'s `groupValue` / `onChanged` pair is deprecated in recent Flutter in favour of a `RadioGroup` ancestor. If the analyzer reports a deprecation on this SDK, replace the venue list with `RadioGroup<String>` wrapping the `RadioListTile`s and move the selection callback to the group, or swap the venue picker to the same `ChoiceChip` pattern used for duration and vibe. Keep the test assertions unchanged — they assert on venue names and button state, not on the widget type.

- [ ] **Step 5: Commit**

```bash
git add lib/ui/check_in_screen.dart lib/main.dart test/ui/check_in_screen_test.dart
git rm --cached test/widget_test.dart 2>/dev/null || true
git commit -m "feat(ui): add check-in screen and replace counter scaffold"
```

---

### Task 12: End-to-End Verification on Device

**Files:**
- Create: `docs/superpowers/plans/phase1-verification.md`

**Interfaces:**
- Consumes: everything above
- Produces: a recorded verification result

- [ ] **Step 1: Run the full suite and analyzer**

```bash
cd "D:/Projects/Practice Project Mobile app"
"C:/Users/designer/flutter/bin/flutter.bat" analyze
"C:/Users/designer/flutter/bin/flutter.bat" test
```

Expected: `No issues found.` and every test passing. Record the exact counts.

- [ ] **Step 2: Run on the Android device**

Connect the Samsung SM-N970F over USB, then:

```bash
cd "D:/Projects/Practice Project Mobile app"
"C:/Users/designer/flutter/bin/flutter.bat" devices
"C:/Users/designer/flutter/bin/flutter.bat" run -d RZ8NA2954KA
```

Expected: `Installing build\app\outputs\flutter-apk\app-debug.apk` followed by `Syncing files to device`.

If Gradle reports a missing SDK package, install it with the replacement CLI rather than letting Gradle try — `sdkmanager.bat` in cmdline-tools 23.0 is a deprecated shim that crashes with `0xC0000409`:

```bash
"C:/Users/designer/AppData/Local/Android/Sdk/cmdline-tools/latest/bin/android.exe" sdk install <package>
```

- [ ] **Step 3: Walk the flow manually**

1. Pick "Mumbai BOM - Terminal 2", duration "30 min", vibe "Down to chat", type a status line.
2. Tap "I am stuck here" — the Limbo feed opens showing the empty state.
3. Confirm the empty-state copy reads as an intended state, not as an error.
4. Tap the logout icon — returns to check-in.

Because the repository is in-memory and per-process, a second device will not see the first. That is expected in Phase 1 and is what Phase 2 fixes.

- [ ] **Step 4: Record the result**

Write `docs/superpowers/plans/phase1-verification.md` containing the analyzer output, the test counts, the device the build ran on, and any step that did not behave as described above.

- [ ] **Step 5: Commit**

```bash
git add docs/superpowers/plans/phase1-verification.md
git commit -m "docs: record phase 1 verification results"
```

---

## Deferred to Later Phases

Recorded so that nothing in the PRD is silently dropped.

| PRD section | Item | Phase |
|---|---|---|
| 5.1 | Auto-detect venue via location, manual search override | 2 |
| 5.2 | Proximity sort within venue (terminal / floor / section) | Deferred indefinitely — needs indoor positioning |
| 5.3 | Waves, mutual match, ephemeral chat, true deletion | 3 |
| 5.4 | Geofenced auto-checkout, editable duration | 4 |
| 5.4 | Rive boarding-pass dissolve (`PresenceClock.dissolveProgress` already supplies the value) | 6 |
| 5.5 | Report / block backend, moderation queue, 24h SLA | 5 |
| 7.1 | Onboarding / value prop screens | 6 |
| 7.5 | User detail card | 3 |
| 9 | Monetization | Post-launch |
| — | Age gate and App Store Guideline 1.2 compliance | 5 — gates launch |
