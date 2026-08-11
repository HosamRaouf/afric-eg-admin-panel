import 'dart:ui';

import 'package:flutter/material.dart';

import 'colors.dart';

class GlassTheme extends ThemeExtension<GlassTheme> {
  final Color glassBackground;
  final Color glassBorder;
  final double glassBlur;
  final Color glassGlow;
  final double glassOpacity;

  const GlassTheme({
    this.glassBackground = AppColors.glassBg,
    this.glassBorder = AppColors.glassBorder,
    this.glassBlur = 24.0,
    this.glassGlow = AppColors.glassBg,
    this.glassOpacity = 0.10,
  });

  static const light = GlassTheme();
  static const dark = GlassTheme();

  @override
  GlassTheme copyWith({
    Color? glassBackground,
    Color? glassBorder,
    double? glassBlur,
    Color? glassGlow,
    double? glassOpacity,
  }) {
    return GlassTheme(
      glassBackground: glassBackground ?? this.glassBackground,
      glassBorder: glassBorder ?? this.glassBorder,
      glassBlur: glassBlur ?? this.glassBlur,
      glassGlow: glassGlow ?? this.glassGlow,
      glassOpacity: glassOpacity ?? this.glassOpacity,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      glassBackground: Color.lerp(glassBackground, other.glassBackground, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassBlur: lerpDouble(glassBlur, other.glassBlur, t) ?? glassBlur,
      glassGlow: Color.lerp(glassGlow, other.glassGlow, t)!,
      glassOpacity:
          lerpDouble(glassOpacity, other.glassOpacity, t) ?? glassOpacity,
    );
  }
}

class GlassStyles {
  static BoxDecoration card({
    double radius = 16,
    Color? bg,
    Color? border,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: bg ?? AppColors.glassBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? AppColors.glassBorder),
      boxShadow: shadows ??
          [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
    );
  }

  static BoxDecoration pill({
    Color? bg,
    Color? border,
  }) {
    return BoxDecoration(
      color: bg ?? AppColors.glassBg,
      borderRadius: BorderRadius.circular(100),
      border: Border.all(color: border ?? AppColors.glassBorder),
    );
  }

  static BoxDecoration glassButton({
    double radius = 12,
    Color? bg,
    Color? border,
  }) {
    return BoxDecoration(
      color: bg ?? AppColors.glassBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border ?? AppColors.glassBorder),
    );
  }

  static BoxDecoration hero({
    double radius = 24,
  }) {
    return BoxDecoration(
      color: AppColors.glassBg,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.glassBorder),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration ceremony() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.gold.withValues(alpha: 0.12),
          AppColors.gold.withValues(alpha: 0.04),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      boxShadow: [
        BoxShadow(
          color: AppColors.gold.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
