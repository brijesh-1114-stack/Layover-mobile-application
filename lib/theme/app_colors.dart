import 'package:flutter/material.dart';

/// Colour tokens, mirroring the Figma `Color` variable collection.
class AppColors {
  const AppColors._();

  static const ink = Color(0xFF0D0D0F);
  static const onInk = Color(0xFFFFFFFF);
  static const paper = Color(0xFFFFFFFF);
  static const surface = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0D0D0F);
  static const textSecondary = Color(0xFF667085);
  static const textMuted = Color(0xFFA3AAB8);
  static const bgMuted = Color(0xFFEEF1F5);
  static const border = Color(0xFFE4E7EC);
  static const accent = Color(0xFF0B79F0);
  static const accentStrong = Color(0xFF0A5FC7);
  static const accentTint = Color(0xFFE7F2FE);

  /// The three blurred circles that make the hero glow on screen 01.
  static const glowOuter = Color(0xFF6EC4FF);
  static const glowMid = Color(0xFF2CCCFE);
  static const glowCore = Color(0xFF0052FE);

  /// Screen 02 uses its own slightly cooler glow, anchored above the frame.
  static const glowTopOuter = Color(0xFF7BCDFE);
  static const glowTopMid = Color(0xFF2CCCFE);
  static const glowTopCore = Color(0xFF0576FF);

  /// Onboarding step list.
  static const stepActive = Color(0xFF0052FE);
  static const stepTitleActive = Color(0xFF0D0D0F);
  static const stepInactive = Color(0xFF5D5D5D);
  static const stepDescription = Color(0xFF7A7A7A);
}
