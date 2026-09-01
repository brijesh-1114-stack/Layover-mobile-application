import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../presence/presence_models.dart';
import '../presence/presence_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import '../theme/motion.dart';
import 'flow_scaffold.dart';

/// The live presence card: a departure board.
///
/// The wait is the only thing on this card worth looking at twice, so it is
/// rendered as split-flap tiles rather than a progress bar, and the strip
/// underneath reports the one fact that changes while you sit there - who else
/// turned up.
class PresencePass extends StatelessWidget {
  const PresencePass({
    super.key,
    required this.session,
    required this.now,
    required this.name,
    required this.crowd,
    this.onTapCrowd,
  });

  final PresenceSession session;

  /// Passed in rather than read here, so the card is a pure function of its
  /// inputs and the clock lives in exactly one place.
  final DateTime now;

  final String? name;
  final VenueCrowd crowd;
  final VoidCallback? onTapCrowd;

  bool get _ended => session.isEnded || session.remaining(now) == Duration.zero;
  bool get _endingSoon => session.isEndingSoon(now);

  @override
  Widget build(BuildContext context) {
    final s = FlowScaffold.scaleOf(context);
    final parts = CountdownParts.from(session.remaining(now));

    final digitColor = _ended
        ? AppColors.onInk.withValues(alpha: 0.3)
        : _endingSoon
        ? AppColors.warningOnInk
        : AppColors.onInk;

    final label = _ended
        ? 'YOU LEFT LIMBO AT ${_clock(session.endedAt ?? session.expiresAt)}'
        : _endingSoon
        ? 'YOUR CARD FADES IN'
        : 'YOU LEAVE LIMBO IN';

    return ClipRRect(
      borderRadius: BorderRadius.circular(24 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: AppColors.ink,
            padding: EdgeInsets.all(20 * s),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: interTight(
                          size: 10 * s,
                          weight: 500,
                          height: 1.2,
                          letterSpacing: 1.6 * s,
                          color: _endingSoon && !_ended
                              ? AppColors.warningOnInk
                              : AppColors.onInk.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                    _GateTag(code: _gateCode(session.venue.name), scale: s),
                  ],
                ),
                SizedBox(height: 14 * s),
                _Clock(parts: parts, color: digitColor, scale: s),
                SizedBox(height: 14 * s),
                Row(
                  children: [
                    Container(
                      width: 28 * s,
                      height: 28 * s,
                      decoration: BoxDecoration(
                        color: AppColors.onInk.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _initial(name),
                        style: interTight(
                          size: 12 * s,
                          weight: 600,
                          color: AppColors.onInk.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                    SizedBox(width: 10 * s),
                    Expanded(
                      child: Text(
                        _metaLine(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: interTight(
                          size: 10 * s,
                          weight: 500,
                          height: 1.2,
                          letterSpacing: 1.3 * s,
                          color: AppColors.onInk.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ],
                ),
                if (session.statusLine != null) ...[
                  SizedBox(height: 14 * s),
                  Text(
                    '"${session.statusLine}"',
                    style: interTight(
                      size: 14 * s,
                      weight: 400,
                      height: 1.4,
                      color: AppColors.onInk.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          _CrowdStrip(
            crowd: crowd,
            spent: _ended,
            onTap: _ended ? null : onTapCrowd,
            scale: s,
          ),
        ],
      ),
    );
  }

  String _metaLine() {
    final who = (name ?? 'You').toUpperCase();
    return '$who - ${session.type.label.toUpperCase()} - ${session.vibe.label.toUpperCase()}';
  }

  static String _initial(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? 'Y' : trimmed.characters.first.toUpperCase();
  }

  /// Airport style short code for the gate tag, taken from the venue name so it
  /// stays honest when the venue is a courthouse rather than a terminal.
  static String _gateCode(String venueName) {
    final parts = venueName.split(RegExp(r'\s*-\s*'));
    if (parts.length > 1) {
      final head = parts.first.split(' ').last;
      final tail = parts.last.replaceAll('Terminal ', 'T').replaceAll(' ', '');
      return '$head - $tail';
    }
    return venueName.length <= 12
        ? venueName
        : '${venueName.substring(0, 11)}…';
  }
}

/// Hours, minutes and seconds as a split-flap board.
///
/// Seconds earn their place here: they are the only part of the card that moves
/// on its own, so they are what makes a card that is quietly expiring look
/// alive rather than frozen. They also set the tile size - five cards and two
/// colons have to fit the 345pt column, so the tiles are narrower than a
/// three-card clock would allow.
class _Clock extends StatelessWidget {
  const _Clock({required this.parts, required this.color, required this.scale});

  final CountdownParts parts;
  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;

    Widget colon() => Padding(
      padding: EdgeInsets.symmetric(horizontal: 4 * s),
      child: Text(
        ':',
        style: interTight(
          size: 26 * s,
          weight: 600,
          height: 1.0,
          color: AppColors.onInk.withValues(alpha: 0.45),
        ),
      ),
    );

    Widget group(String a, String b, String label, double labelOpacity) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlipTile(digit: a, color: color, scale: s),
              SizedBox(width: 5 * s),
              FlipTile(digit: b, color: color, scale: s),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            label,
            style: interTight(
              size: 9 * s,
              weight: 600,
              height: 1.1,
              letterSpacing: 1.2 * s,
              color: AppColors.onInk.withValues(alpha: labelOpacity),
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FlipTile(digit: parts.hourDigit, color: color, scale: s),
            SizedBox(height: 6 * s),
            Text(
              'HRS',
              style: interTight(
                size: 9 * s,
                weight: 600,
                height: 1.1,
                letterSpacing: 1.2 * s,
                color: AppColors.onInk.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.only(top: 14 * s),
          child: colon(),
        ),
        group(parts.minuteTens, parts.minuteOnes, 'MIN', 0.6),
        Padding(
          padding: EdgeInsets.only(top: 14 * s),
          child: colon(),
        ),
        // The seconds are the quietest label because they are the loudest
        // element: the tile is already turning over once a second.
        group(parts.secondTens, parts.secondOnes, 'SEC', 0.35),
      ],
    );
  }
}

/// One card of a split-flap board.
///
/// A real flap board does not cross-fade or spin the whole card. The tile is
/// split across its middle: the **top half of the outgoing digit** hinges down
/// and away, uncovering the top half of the new digit that was waiting behind
/// it; then the **bottom half of the incoming digit** swings up from behind the
/// seam and lands flat over the old one. Two flaps, one after the other, always
/// falling downwards - which is why the seam has to sit exactly on the axis
/// both halves rotate about.
class FlipTile extends StatefulWidget {
  const FlipTile({
    super.key,
    required this.digit,
    required this.color,
    required this.scale,
  });

  final String digit;
  final Color color;
  final double scale;

  @override
  State<FlipTile> createState() => _FlipTileState();
}

class _FlipTileState extends State<FlipTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.flap,
  );

  /// The digit being turned away from. Only meaningful while the controller
  /// runs; the rest of the time the tile paints [widget.digit] flat, so an idle
  /// clock costs nothing.
  late String _outgoing = widget.digit;

  @override
  void didUpdateWidget(covariant FlipTile old) {
    super.didUpdateWidget(old);
    if (old.digit != widget.digit) {
      _outgoing = old.digit;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final w = 46 * s;
    final h = 58 * s;

    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final flipping = _controller.isAnimating;

          // The first half of the timeline turns the old top away, the second
          // half brings the new bottom in. Splitting one controller rather than
          // running two keeps the halves from overlapping at the seam.
          final fallT = (t / 0.5).clamp(0.0, 1.0);
          final riseT = ((t - 0.5) / 0.5).clamp(0.0, 1.0);

          return Stack(
            children: [
              // What is already settled behind the flaps: the new digit's top,
              // and - until the incoming flap lands - the old digit's bottom.
              _face(_TileHalf.top, widget.digit, w, h),
              _face(
                _TileHalf.bottom,
                flipping && riseT < 1 ? _outgoing : widget.digit,
                w,
                h,
              ),

              if (flipping) ...[
                if (fallT < 1)
                  _flap(
                    half: _TileHalf.top,
                    digit: _outgoing,
                    // 0 -> -90 degrees, hinged on the seam at the bottom edge.
                    angle: -math.pi / 2 * Curves.easeIn.transform(fallT),
                    alignment: Alignment.bottomCenter,
                    w: w,
                    h: h,
                  ),
                if (riseT > 0)
                  _flap(
                    half: _TileHalf.bottom,
                    digit: widget.digit,
                    // +90 -> 0 degrees, hinged on the seam at the top edge.
                    angle: math.pi / 2 * (1 - Curves.easeOut.transform(riseT)),
                    alignment: Alignment.topCenter,
                    w: w,
                    h: h,
                  ),
              ],

              // The seam sits above every layer so the two halves always read
              // as one card that is hinged, not two stacked tiles.
              Positioned(
                left: 0,
                right: 0,
                top: h / 2 - 0.5,
                child: Container(
                  height: 1,
                  // A hairline of light, not a black gash - but barely there.
                  // The seam only has to hint at where the card is hinged; at
                  // any more than a few percent it cuts through the digit.
                  color: AppColors.onInk.withValues(alpha: 0.05),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// A static half of the tile.
  Widget _face(_TileHalf half, String digit, double w, double h) {
    return Positioned(
      top: half == _TileHalf.top ? 0 : h / 2,
      left: 0,
      child: _halfCard(half: half, digit: digit, w: w, h: h),
    );
  }

  /// A half that is mid-turn, drawn with perspective and darkened as it goes
  /// edge-on - a flap catching less light the further it tips.
  Widget _flap({
    required _TileHalf half,
    required String digit,
    required double angle,
    required Alignment alignment,
    required double w,
    required double h,
  }) {
    final shade = (angle.abs() / (math.pi / 2)).clamp(0.0, 1.0);
    return Positioned(
      top: half == _TileHalf.top ? 0 : h / 2,
      left: 0,
      child: Transform(
        alignment: alignment,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0018)
          ..rotateX(angle),
        child: Stack(
          children: [
            _halfCard(half: half, digit: digit, w: w, h: h),
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.55 * shade),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// One half of a card: the full digit drawn at full size, then clipped to the
  /// half we want. Drawing the whole glyph and cropping is what makes the two
  /// halves line up exactly at the seam.
  Widget _halfCard({
    required _TileHalf half,
    required String digit,
    required double w,
    required double h,
  }) {
    final s = widget.scale;
    final radius = Radius.circular(10 * s);

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: half == _TileHalf.top ? radius : Radius.zero,
        bottom: half == _TileHalf.bottom ? radius : Radius.zero,
      ),
      child: SizedBox(
        width: w,
        height: h / 2,
        child: OverflowBox(
          alignment: half == _TileHalf.top
              ? Alignment.topCenter
              : Alignment.bottomCenter,
          minHeight: h,
          maxHeight: h,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: const Color(0xFF17181B),
              borderRadius: BorderRadius.circular(10 * s),
              border: Border.all(
                color: AppColors.onInk.withValues(alpha: 0.08),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              digit,
              style: interTight(
                size: 32 * s,
                weight: 600,
                height: 1.0,
                letterSpacing: -1 * s,
                color: widget.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _TileHalf { top, bottom }

class _GateTag extends StatelessWidget {
  const _GateTag({required this.code, required this.scale});

  final String code;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: AppColors.onInk.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6 * s),
      ),
      child: Text(
        code,
        style: interTight(
          size: 10 * s,
          weight: 600,
          height: 1.2,
          letterSpacing: 1 * s,
          color: AppColors.onInk.withValues(alpha: 0.8),
        ),
      ),
    );
  }
}

/// The strip under the pass. This is the part that changes while the user
/// waits, so it is the part that earns the tap into the feed.
class _CrowdStrip extends StatelessWidget {
  const _CrowdStrip({
    required this.crowd,
    required this.spent,
    required this.onTap,
    required this.scale,
  });

  final VenueCrowd crowd;
  final bool spent;
  final VoidCallback? onTap;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final s = scale;
    final message = spent
        ? 'Chats fade in 2 hrs'
        : crowd.arrivedSince > 0
        ? '${crowd.total} in limbo here - ${crowd.arrivedSince} are new'
        : '${crowd.total} in limbo here';

    return Material(
      color: spent ? AppColors.bgMuted : AppColors.accent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Row(
            children: [
              SizedBox(
                width: (28 + 18 * (crowd.initials.length - 1)) * s,
                height: 28 * s,
                child: Stack(
                  children: [
                    for (var i = 0; i < crowd.initials.length; i++)
                      Positioned(
                        left: i * 18 * s,
                        child: Container(
                          width: 28 * s,
                          height: 28 * s,
                          decoration: BoxDecoration(
                            color: spent
                                ? AppColors.accentTint
                                : AppColors.onInk.withValues(
                                    alpha: 0.95 - i * 0.1,
                                  ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: spent
                                  ? AppColors.bgMuted
                                  : AppColors.accent,
                              width: 2 * s,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            crowd.initials[i],
                            style: interTight(
                              size: 12 * s,
                              weight: 600,
                              color: AppColors.accentStrong,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: Text(
                  message,
                  style: interTight(
                    size: 13 * s,
                    weight: 600,
                    height: 1.3,
                    letterSpacing: -0.1 * s,
                    color: spent ? AppColors.textSecondary : AppColors.onInk,
                  ),
                ),
              ),
              if (!spent)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20 * s,
                  color: AppColors.onInk,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _clock(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
