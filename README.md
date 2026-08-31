# Layover

A mobile app for people stuck somewhere temporarily - airports, stations,
waiting rooms, long queues - who want light, low-pressure company for as long
as the wait lasts.

Presence is ephemeral by design: you check in, you're visible for the duration
of your wait, and you disappear when you leave. No persistent profiles, no
follower counts, no long-term social graph.

Full product definition: [`Layover-PRD.md`](Layover-PRD.md).

## Status

Onboarding is implemented. The rest of the flow is designed but not yet built.

| Screen | State |
|---|---|
| 01 - Welcome (doubles as the splash) | Built |
| 02 - Three simple steps | Built |
| 03 - Enable location | Designed |
| 04 - Check in | Designed |
| 05 - Limbo feed | Designed |

The Phase 1 implementation plan lives in
[`docs/superpowers/plans/`](docs/superpowers/plans/).

## Running it

```bash
flutter pub get
flutter run
```

Requires Flutter stable (built against 3.47) and the Android SDK. iOS builds
need macOS and Xcode.

## Layout

```
lib/
  main.dart                  entry point, system UI, theme
  theme/
    app_colors.dart          colour tokens, mirroring the Figma variables
    app_text.dart            Inter Tight helper (variable-font weight axis)
    motion.dart              durations, curves and the shared entrance stagger
  screens/onboarding/        onboarding 01 and 02
  widgets/
    blur_reveal.dart         blur-to-sharp reveal, driven or self-triggering
    page_transitions.dart    shared route transition
assets/
  fonts/                     Inter Tight (variable)
  images/, logo/, icons/     exported from the Figma source file
```

## Notes for anyone picking this up

**Motion is centralised.** Every duration and curve comes from
`theme/motion.dart`. Screens that pick their own timings read as unrelated
animations even when the shapes match, so add to that file rather than
hardcoding a `Duration` in a widget.

**Inter Tight ships only as a variable font.** `fontWeight` alone does not move
a variable axis reliably, so `interTight()` sets `FontVariation('wght', …)`
explicitly. Use that helper rather than a bare `TextStyle`.

**Layout is scaled from the 393pt Figma frame.** Relationships that carry the
design are pinned to their Figma values and the slack falls into one flexible
gap, so proportions hold on aspect ratios the frame never anticipated.

**Entrance animations start one frame late on purpose.** On a cold start
Flutter paints its first frames into a surface Android has not composited yet;
starting immediately means the animation plays out before anything reaches the
screen.

**Prefer transforms over relayout when animating.** Animating a font size
re-lays out glyphs every frame; scaling a once-laid-out `Text` does not. The
same applies to `Align(heightFactor:)` over `AnimatedSize`.
