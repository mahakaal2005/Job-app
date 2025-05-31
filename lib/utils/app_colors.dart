import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Palette - Electric Blue Focus
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color darkBlue = Color(0xFF0052CC);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color accentBlue = Color(0xFF3385FF);
  static const Color neonBlue = Color(0xFF00D4FF);

  // Core Colors - Pure Contrast
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color richBlack = Color(0xFF0A0A0A);
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color offWhite = Color(0xFFFCFCFC);

  // Neutral Shades - Minimal Palette
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color softGrey = Color(0xFFF2F2F2);
  static const Color borderGrey = Color(0xFFD1D1D1);

  // Status Colors - Blue Tinted
  static const Color success = Color(0xFF00C851);
  static const Color successLight = Color(0xFFE8F8F0);
  static const Color error = Color(0xFFFF4444);
  static const Color errorLight = Color(0xFFFFE8E8);
  static const Color warning = Color(0xFFFFAA00);
  static const Color warningLight = Color(0xFFFFF4E6);
  static const Color info = primaryBlue;
  static const Color infoLight = lightBlue;

  // Background Colors - Clean & Modern
  static const Color backgroundColor = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF0F0F0F);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color darkCardBackground = Color(0xFF1C1C1C);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color darkSurfaceColor = Color(0xFF151515);

  // Text Colors - High Contrast
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF4A4A4A);
  static const Color hintText = Color(0xFF999999);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color blueText = primaryBlue;

  // Interactive Colors
  static const Color hoverColor = Color(0xFFF0F0F0);
  static const Color pressedColor = Color(0xFFE0E0E0);
  static const Color focusColor = Color(0x1A0066FF);
  static const Color dividerColor = Color(0xFFEEEEEE);

  // Gradient Collections - Modern & Bold
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, darkBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blackGradient = LinearGradient(
    colors: [black, softBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [neonBlue, primaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient whiteGradient = LinearGradient(
    colors: [white, offWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF00A043)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [error, Color(0xFFE63939)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassmorphism Effects
  static const Color glassWhite = Color(0x40FFFFFF);
  static const Color glassBlack = Color(0x40000000);
  static const Color glassBlue = Color(0x400066FF);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  static const Color blueShadow = Color(0x330066FF);

  // Brand Specific
  static const Color brandAccent = neonBlue;
  static const Color brandSecondary = darkBlue;
  static const Color brandNeutral = grey;
}