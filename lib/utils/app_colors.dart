// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Canvas & surfaces - Black base for Red+Black+Gray scheme
  static const Color background = Color(0xFF000000);       // Pure black background
  static const Color surface = Color(0xFF0A0A0A);          // Very dark gray surface
  static const Color surfaceElevated = Color(0xFF1A1A1A);  // Elevated dark gray

  // Header gradient family - SOPHISTICATED GRAY gradient for header
  static const Color headerDark = Color(0xFF1A1A1A);      // Deep dark gray - header top
  static const Color headerCore = Color(0xFF2A2A2A);      // Medium dark gray - header upper
  static const Color headerMid = Color(0xFF3A3A3A);       // Medium gray - header middle
  static const Color headerLight = Color(0xFF4A4A4A);     // Light gray - header lower
  
  // Brand accent family - MINIMAL RED for buttons and accents only
  static const Color primaryAccent = Color(0xFFDC2626);   // True red - buttons and accents
  static const Color accentDeep = Color(0xFFB91C3C);      // Deep red - pressed states
  static const Color accentLight = Color(0xFFEF4444);     // Light red - hover states
  static const Color accentPop = Color(0xFFF87171);       // Very light red - subtle highlights
  
  // Backwards compatibility aliases for existing code
  static const Color accentDark = accentDeep;             // Alias for accentDeep
  static const Color accentCore = primaryAccent;          // Alias for primaryAccent

  // Metallic sheen for premium surfaces (gray metallic for header)
  static const Color sheenStart = Color(0xFF6A6A6A);      // Light gray metallic
  static const Color sheenEnd = Color(0xFF3A3A3A);        // Dark gray metallic

  // Text - Gray scale for Red+Black+Gray scheme
  static const Color textPrimary = Color(0xFFFFFFFF);      // Pure white text
  static const Color textSecondary = Color(0xFFC4C4C4);    // Light gray text
  static const Color textHigh = Color(0xFFFFFFFF);         // High contrast white
  static const Color textMuted = Color(0xFF808080);        // Medium gray text
  static const Color textOnAccent = Color(0xFFFFFFFF);     // White on red

  // Glass / tint (brand-based) - Red-black tints for seamless flow
  static const Color glass05 = Color(0x0D1A0808);
  static const Color glass10 = Color(0x1A1A0808);
  static const Color glass15 = Color(0x261A0808);
  static const Color glass20 = Color(0x331A0808);
  static const Color glass25 = Color(0x401A0808);
  static const Color glass30 = Color(0x4D1A0808);

  static const Color glassTint05 = Color(0x0D1A0808);
  static const Color glassTint12 = Color(0x1F1A0808);
  static const Color glassBorder = Color(0x33F7EFEE);
  static const Color glassSpecular = Color(0x28F7EFEE);

  static const Color glassBorderLight = Color(0x26F7EFEE);
  static const Color glassBorderStrong = Color(0x66F7EFEE);

  static const Color glassDark05 = Color(0x0D0C0807);
  static const Color glassDark10 = Color(0x1A0C0807);
  static const Color glassDark15 = Color(0x260C0807);
  static const Color glassDark20 = Color(0x330C0807);
  static const Color glassDark25 = Color(0x400C0807);

  static const Color glassWhite = Color(0x26F7EFEE);
  static const Color glassBlack = Color(0x1A0C0807);
  static const Color glassGray = Color(0xFFB8A9A7);
  static const Color cardGlass = Color(0x1A1A0808);
  static const Color cardGlassSecondary = Color(0x0D1A0808);
  static const Color cardGlassActive = Color(0x26E53E3E);  // Active cards use true red tint

  // ---- RED-ONLY State Tokens (replaced green/yellow/blue) ----
  // These are distinct tints of your red so they are visually different
  // but remain within the single-red brand system.

  // "Positive" state - Using corrected red variations
  static const Color statePositive = Color(0xFFDC2626); // true red
  static const Color statePositiveGlass = Color(
    0x26DC2626,
  ); // glass overlay variant

  // "Warning" state - Using lighter red
  static const Color stateWarning = Color(0xFFF87171); // light red
  static const Color stateWarningGlass = Color(0x26F87171); // glass overlay

  // "Error" state - Using deep red
  static const Color stateError = Color(
    0xFFB91C3C,
  ); // deep red
  static const Color stateErrorGlass = Color(0x26B91C3C); // error glass

  // "Info" state - Using gray for neutral info
  static const Color stateInfo = Color(0xFF808080); // medium gray
  static const Color stateInfoGlass = Color(0x26808080); // info glass

  // Backwards compatible aliases kept but mapped to the red-only tokens:
  static const Color success = statePositive;
  static const Color successColor = statePositive;
  static const Color successGlass = statePositiveGlass;

  static const Color warning = stateWarning;
  static const Color warningColor = stateWarning;
  static const Color warningGlass = stateWarningGlass;

  static const Color error = stateError;
  static const Color errorColor = stateError;
  static const Color errorGlass = stateErrorGlass;

  static const Color info = stateInfo;
  static const Color infoGlass = stateInfoGlass;

  // Shadows - subtle, red accent shadow for premium glow
  static const Color shadowLight = Color(0x22000000);
  static const Color shadowSoft = Color(0x22000000);
  static const Color shadowMedium = Color(0x33000000);
  static const Color accentShadow = Color(0x20DC2626);  // True red shadow

  // UI Elements - Supporting colors
  static const Color border = Color(0xFF151313);
  static const Color dividerColor = Color(0xFF261E1D);
  static const Color surfaceColor = Color(0xFF050101);

  // Gradients (Red-tinted for seamless flow)
  static const List<Color> glassGradient = [
    Color(0x261A0808),
    Color(0x0D1A0808),
  ];

  static const List<Color> glassGradientStrong = [
    Color(0x401A0808),
    Color(0x1A1A0808),
  ];

  static const List<Color> metallicGradient = [
    Color(0xFFFF8A75),
    Color(0xFFB33A2C),
  ];

  static const List<Color> accentGradient = [
    Color(0xFFDC2626),  // True red
    Color(0xFFB91C3C),  // Deep red
  ];

  static const List<Color> accentGradientVibrant = [
    Color(0xFFF87171),  // Light red
    Color(0xFFDC2626),  // True red
  ];
}
