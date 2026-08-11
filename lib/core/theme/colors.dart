import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand fills: primary CTA backgrounds, filled selection pills, session
  // block header bars, brand-tint scrims/chips.
  static const Color primary = Color(0xFF7B1B37);

  // Elevated warm surface: gradient stops, earned-stamp radial fills.
  static const Color darkBase = Color(0xFF3B1514);

  // App background (scaffold + explicit page overrides).
  static const Color deepBlack = Color(0xFF1a0a0b);

  // Meta / secondary accent: meta icons, time labels, hall badges, links.
  // NOT for live, selected, or premium states.
  static const Color accent = Color(0xFFC68C98);

  // Selected / active / attention: active nav + underline tabs, voted
  // questions, "New" badges, countdown, text on brand-tint bars.
  static const Color highlight = Color(0xFFFAC7C7);

  // Light warm surface for avatar initial chips (paired with deepBlack text).
  static const Color surface = Color(0xFFECD9DA);

  // Premium / achievement gold: progression arcs & bars, level chips,
  // ceremony cards, sponsored badges, leaderboard, CTA rings, brand tagline.
  static const Color gold = Color(0xFFD4A847);
  static const Color goldLight = Color(0xFFF0C96A);

  // Status semantics.
  static const Color liveRed = Color(0xFFFF4444);
  static const Color liveRedLight = Color(0xFFFF6B6B);
  static const Color alertRed = Color(0xFFFF5E5E);
  static const Color pointsGreen = Color(0xFF4ADE80);
  static const Color pinnedGold = Color(0xFFFBD070);
  static const Color answeredGreen = Color(0xFF5DD77A);

  // Text tokens.
  static const Color textWhite = Color(0xFFFFFFFF);

  static const Color glassBg = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x2EFFFFFF);
  static const Color glassBgStrong = Color(0x33FFFFFF);

  static const Color textSecondary = Color(0x8CFFFFFF);
  static const Color textTertiary = Color(0x59FFFFFF);
  static const Color textDisabled = Color(0x3DFFFFFF);

  static const Color navInactive = Color(0x66FFFFFF);
}
