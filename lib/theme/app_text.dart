import 'package:flutter/material.dart';

/// Inter Tight is bundled as a single variable font, so the weight axis has to
/// be driven explicitly with [FontVariation] — `fontWeight` alone does not move
/// a variable axis on every platform.
TextStyle interTight({
  required double size,
  required int weight,
  Color? color,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    fontFamily: 'InterTight',
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
  );
}
