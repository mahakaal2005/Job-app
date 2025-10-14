import 'package:flutter/material.dart';

/// Utility class for color operations
class ColorUtils {
  /// Helper method to create color with alpha using the new withValues method
  /// This replaces the deprecated withOpacity method
  static Color withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }
  
  /// Common alpha values for consistency
  static const double veryLight = 0.1;
  static const double light = 0.2;
  static const double medium = 0.3;
  static const double semiTransparent = 0.5;
  static const double mostlyOpaque = 0.7;
  static const double almostOpaque = 0.9;
}