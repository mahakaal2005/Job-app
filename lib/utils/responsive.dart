import 'package:flutter/material.dart';

/// Responsive utility class for adaptive UI across different screen sizes
/// 
/// Usage:
/// - Responsive.wp(context, 50) = 50% of screen width
/// - Responsive.hp(context, 10) = 10% of screen height
/// - Responsive.sp(context, 16) = Scaled font size based on screen
class Responsive {
  /// Get percentage of screen width
  /// Example: Responsive.wp(context, 50) returns 50% of screen width
  static double wp(BuildContext context, double percentage) {
    final width = MediaQuery.of(context).size.width;
    return (percentage / 100) * width;
  }

  /// Get percentage of screen height
  /// Example: Responsive.hp(context, 10) returns 10% of screen height
  static double hp(BuildContext context, double percentage) {
    final height = MediaQuery.of(context).size.height;
    return (percentage / 100) * height;
  }

  /// Get responsive font size based on screen width
  /// Scales font size proportionally to screen width
  /// Base width: 375px (iPhone X/11/12 standard)
  static double sp(BuildContext context, double size) {
    final width = MediaQuery.of(context).size.width;
    return size * (width / 375);
  }

  /// Get screen width
  static double width(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double height(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if screen is small (< 360px width)
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if screen is medium (360px - 400px width)
  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 400;
  }

  /// Check if screen is large (>= 400px width)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 400;
  }

  /// Check if screen is tablet (>= 600px width)
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets padding(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    final scale = MediaQuery.of(context).size.width / 375;
    
    if (all != null) {
      return EdgeInsets.all(all * scale);
    }
    
    return EdgeInsets.only(
      left: (left ?? horizontal ?? 0) * scale,
      right: (right ?? horizontal ?? 0) * scale,
      top: (top ?? vertical ?? 0) * scale,
      bottom: (bottom ?? vertical ?? 0) * scale,
    );
  }

  /// Get responsive margin based on screen size
  static EdgeInsets margin(
    BuildContext context, {
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? right,
    double? top,
    double? bottom,
  }) {
    return padding(
      context,
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
    );
  }

  /// Get responsive border radius
  static BorderRadius borderRadius(BuildContext context, double radius) {
    final scale = MediaQuery.of(context).size.width / 375;
    return BorderRadius.circular(radius * scale);
  }

  /// Get responsive size for square widgets (icons, avatars, etc.)
  static double size(BuildContext context, double size) {
    final scale = MediaQuery.of(context).size.width / 375;
    return size * scale;
  }

  /// Get responsive button width (default 90% of screen width, max 400px)
  static double buttonWidth(BuildContext context, {double percentage = 90, double? maxWidth}) {
    final width = MediaQuery.of(context).size.width;
    final calculatedWidth = (percentage / 100) * width;
    return maxWidth != null ? calculatedWidth.clamp(0, maxWidth) : calculatedWidth;
  }

  /// Get responsive button height
  static double buttonHeight(BuildContext context, {double defaultHeight = 50}) {
    final scale = MediaQuery.of(context).size.width / 375;
    return defaultHeight * scale.clamp(0.9, 1.1); // Limit scaling between 90% and 110%
  }

  /// Get responsive card width (default 90% of screen width, max 400px)
  static double cardWidth(BuildContext context, {double percentage = 90, double? maxWidth}) {
    final width = MediaQuery.of(context).size.width;
    final calculatedWidth = (percentage / 100) * width;
    return maxWidth != null ? calculatedWidth.clamp(0, maxWidth) : calculatedWidth;
  }
}
