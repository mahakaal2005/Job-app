// lib/utils/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Canvas & surfaces - Deep, rich backgrounds for luxury feel
  static const Color background = Color(0xFF0B0A0A);           // deep near-black
  static const Color surface = Color(0xFF141313);             // primary card surface
  static const Color surfaceElevated = Color(0xFF1F1716);     // elevated surfaces

  // Reddish-orange family - Rich, warm accent colors
  static const Color accentPop = Color(0xFFFF5E3A);          // vivid decorative (use sparingly)
  static const Color primaryAccent = Color(0xFFE14A2B);      // main brand red-orange (decorative / headings)
  static const Color accentLight = Color(0xFFE14A2B);        // alias for compatibility
  static const Color accentDeep = Color(0xFFB73A24);         // functional accent (white text passes)
  static const Color accentCore = Color(0xFF9A2E20);         // primary CTA / very safe for white text
  static const Color accentDark = Color(0xFF9A2E20);         // alias for compatibility

  // Metallic sheen for premium surfaces
  static const Color sheenStart = Color(0xFFD9774C);
  static const Color sheenEnd = Color(0xFF9C4B2D);

  // Text - High contrast for readability
  static const Color textPrimary = Color(0xFFF6F4F3);        // high contrast white
  static const Color textSecondary = Color(0xFFB19D98);      // muted text
  static const Color textHigh = Color(0xFFF6F4F3);           // alias for textPrimary
  static const Color textMuted = Color(0xFFB19D98);          // alias for textSecondary
  static const Color textOnAccent = Color(0xFFFFFFFF);       // white text on accents

  // Glass / tint (warm reddish tint) - Sophisticated glassmorphism
  static const Color glass05 = Color(0x0F0F0D0C);           // very subtle glass
  static const Color glass10 = Color(0x1A0F0D0C);           // light glass overlay
  static const Color glass15 = Color(0x260F0D0C);           // card backgrounds
  static const Color glass20 = Color(0x330F0D0C);           // prominent cards
  static const Color glass25 = Color(0x400F0D0C);           // active elements
  static const Color glass30 = Color(0x4D0F0D0C);           // strong glass effect
  
  static const Color glassTint05 = Color(0x0F0F0D0C);       // very subtle
  static const Color glassTint12 = Color(0x29130F1E);       // stronger overlay
  static const Color glassBorder = Color(0x33FFFFFF);       // soft border
  static const Color glassSpecular = Color(0x2FFFFFFF);     // tiny highlight

  // Glass borders and effects
  static const Color glassBorderLight = Color(0x26FFFFFF);   // 15% white border
  static const Color glassBorderStrong = Color(0x66FFFFFF); // 40% white border

  // Dark glass variants
  static const Color glassDark05 = Color(0x0D000000);       // 5% black
  static const Color glassDark10 = Color(0x1A000000);       // 10% black
  static const Color glassDark15 = Color(0x26000000);       // 15% black
  static const Color glassDark20 = Color(0x33000000);       // 20% black

  // Legacy glass colors for compatibility
  static const Color glassWhite = Color(0x2AFFFFFF);
  static const Color glassBlack = Color(0x1A000000);
  static const Color glassGray = Color(0xFFB19D98);         // Updated to match textMuted for consistency
  static const Color cardGlass = Color(0x1A0F0D0C);         // 10% warm tint for main cards
  static const Color cardGlassSecondary = Color(0x0D0F0D0C); // 5% warm tint for secondary cards
  static const Color cardGlassActive = Color(0x260F0D0C);   // 15% warm tint for active/hover

  // States - Refined state colors
  static const Color success = Color(0xFF3E8E60);
  static const Color successColor = Color(0xFF3E8E60);      // alias for compatibility
  static const Color warning = Color(0xFFC38F1A);
  static const Color warningColor = Color(0xFFC38F1A);      // alias for compatibility
  static const Color error = Color(0xFFD94B4B);
  static const Color errorColor = Color(0xFFD94B4B);        // alias for compatibility

  // Status colors with glass effect
  static const Color errorGlass = Color(0x26D94B4B);        // Error red with glass
  static const Color successGlass = Color(0x263E8E60);      // Success green with glass
  static const Color warningGlass = Color(0x26C38F1A);      // Warning yellow with glass

  // Shadows - Soft, sophisticated shadows
  static const Color shadowLight = Color(0x20000000);
  static const Color shadowSoft = Color(0x20000000);        // alias for shadowLight
  static const Color shadowMedium = Color(0x30000000);      // medium shadow
  static const Color blueShadow = Color(0x20E14A2B);        // accent-colored shadow

  // UI Elements - Supporting colors
  static const Color border = Color(0xFF2C2C2C);
  static const Color dividerColor = Color(0xFF3C3C3C);
  static const Color surfaceColor = Color(0xFF141313);      // alias for surface

  // Gradient combinations for luxury effects
  static const List<Color> glassGradient = [
    Color(0x260F0D0C), // 15% warm tint
    Color(0x0D0F0D0C), // 5% warm tint
  ];

  static const List<Color> glassGradientStrong = [
    Color(0x400F0D0C), // 25% warm tint
    Color(0x1A0F0D0C), // 10% warm tint
  ];

  // Premium metallic gradients
  static const List<Color> metallicGradient = [
    Color(0xFFD9774C), // sheenStart
    Color(0xFF9C4B2D), // sheenEnd
  ];

  // Accent gradients for luxury feel
  static const List<Color> accentGradient = [
    Color(0xFFE14A2B), // primaryAccent
    Color(0xFFB73A24), // accentDeep
  ];

  static const List<Color> accentGradientVibrant = [
    Color(0xFFFF5E3A), // accentPop
    Color(0xFFE14A2B), // primaryAccent
  ];
}