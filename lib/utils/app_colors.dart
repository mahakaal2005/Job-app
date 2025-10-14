import 'package:flutter/material.dart';

class AppColors {
  // Primary Blue Palette - Electric Blue Focus
  static const Color primaryBlue = Color(0xFF0066FF);
  static const Color darkBlue = Color(0xFF0052CC);
  static const Color lightBlue = Color(0xFFE6F2FF);
  static const Color accentBlue = Color(0xFF3385FF);
  static const Color neonBlue = Color(0xFF00D4FF);
  static const Color deepBlue = Color(0xFF003D99);
  static const Color royalBlue = Color(0xFF4169E1);

  // Core Colors - Pure Contrast
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color richBlack = Color(0xFF0A0A0A);
  static const Color softBlack = Color(0xFF1A1A1A);
  static const Color charcoalBlack = Color(0xFF2C2C2C);
  static const Color offWhite = Color(0xFFFCFCFC);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color creamWhite = Color(0xFFFAFAFA);

  // Beige Accents - Warm Neutrals
  static const Color lightBeige = Color(0xFFF5F5DC);
  static const Color warmBeige = Color(0xFFE8E2D4);
  static const Color softBeige = Color(0xFFF0EAE2);
  static const Color paleBeige = Color(0xFFFAF8F5);

  // Neutral Shades - Monochrome Palette
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color grey = Color(0xFF666666);
  static const Color lightGrey = Color(0xFFE8E8E8);
  static const Color softGrey = Color(0xFFF2F2F2);
  static const Color borderGrey = Color(0xFFD1D1D1);
  static const Color silverGrey = Color(0xFFC0C0C0);
  static const Color smokeyGrey = Color(0xFF8A8A8A);

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
  static const Color beigeBackground = Color(0xFFF8F6F3);

  // Text Colors - High Contrast
  static const Color primaryText = Color(0xFF000000);
  static const Color secondaryText = Color(0xFF4A4A4A);
  static const Color hintText = Color(0xFF999999);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color blueText = primaryBlue;
  static const Color mutedText = Color(0xFF6B6B6B);

  // Interactive Colors
  static const Color hoverColor = Color(0xFFF0F0F0);
  static const Color pressedColor = Color(0xFFE0E0E0);
  static const Color focusColor = Color(0x1A0066FF);
  static const Color dividerColor = Color(0xFFEEEEEE);
  static const Color activeColor = primaryBlue;

  // Enhanced Gradient Collections
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, deepBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blackGradient = LinearGradient(
    colors: [black, charcoalBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [richBlack, softBlack],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [neonBlue, primaryBlue, deepBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient whiteGradient = LinearGradient(
    colors: [white, creamWhite],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient beigeGradient = LinearGradient(
    colors: [paleBeige, warmBeige],
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

  // Premium Gradients
  static const LinearGradient elegantBlue = LinearGradient(
    colors: [royalBlue, primaryBlue, accentBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient sophisticatedDark = LinearGradient(
    colors: [black, charcoalBlack, darkGrey],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Glassmorphism Effects
  static const Color glassWhite = Color(0x40FFFFFF);
  static const Color glassBlack = Color(0x40000000);
  static const Color glassBlue = Color(0x400066FF);
  static const Color glassBeige = Color(0x40F5F5DC);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color shadowDark = Color(0x4D000000);
  static const Color blueShadow = Color(0x330066FF);
  static const Color blackShadow = Color(0x26000000);

  // Brand Specific
  static const Color brandAccent = neonBlue;
  static const Color brandSecondary = deepBlue;
  static const Color brandNeutral = smokeyGrey;
  static const Color brandLight = lightBeige;
  
  // Look Gig Brand Colors
  static const Color lookGigPurple = Color(0xFF130160);
  static const Color lookGigLightGray = Color(0xFFF9F9F9);
  static const Color lookGigDescriptionText = Color(0xFF524B6B);
  static const Color lookGigActiveIcon = Color(0xFF7551FF);
  static const Color lookGigDarkPurple = Color(0xFF0D0140);
  static const Color lookGigInactiveIcon = Color(0xFFA49EB5);
  static const Color lookGigProfileText = Color(0xFF150B3D);
  static const Color lookGigProfileGradientStart = Color(0xFF7551FF);
  static const Color lookGigProfileGradientEnd = Color(0xFFA993FF);
  
  // Profile Screen Specific Colors (from Figma)
  static const Color profileHeaderGradientStart = Color(0xFF7551FF);
  static const Color profileHeaderGradientEnd = Color(0xFFA993FF);
  static const Color profileCardShadow = Color(0x2E99ABC6);
  static const Color profileSectionText = Color(0xFF150B3D);

  // Card & Surface Colors
  static const Color cardElevated = Color(0xFFFFFFFF);
  static const Color cardSoft = Color(0xFFF8F9FA);
  static const Color surfaceElevated = Color(0xFFFFFFFF);
  static const Color surfaceDim = Color(0xFFF5F5F5);
}