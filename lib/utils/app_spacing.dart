import 'package:flutter/material.dart';

/// AppSpacing - Centralized spacing and padding management
/// 
/// Provides responsive, consistent spacing across the entire app.
/// Uses fixed breakpoints for predictable behavior across different screen sizes.
/// 
/// Usage:
/// ```dart
/// // Responsive horizontal padding
/// Padding(
///   padding: AppSpacing.horizontal(context),
///   child: YourWidget(),
/// )
/// 
/// // Standard spacing constants
/// SizedBox(height: AppSpacing.medium)
/// ```
class AppSpacing {
  // Private constructor to prevent instantiation
  AppSpacing._();

  // ============================================================================
  // RESPONSIVE PADDING
  // ============================================================================

  /// Returns responsive horizontal padding based on screen width
  /// 
  /// Breakpoints:
  /// - < 360px: 16px (Small phones like iPhone SE)
  /// - < 600px: 20px (Normal phones - most devices)
  /// - < 900px: 32px (Tablets)
  /// - >= 900px: 48px (Desktop/Large screens)
  static double getHorizontalPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) return 16.0;  // Small phones
    if (width < 600) return 20.0;  // Normal phones
    if (width < 900) return 32.0;  // Tablets
    return 48.0;  // Desktop/Large screens
  }

  // ============================================================================
  // STANDARD SPACING CONSTANTS
  // ============================================================================

  /// Extra small spacing (4px) - For tight layouts
  static const double xs = 4.0;

  /// Small spacing (8px) - For compact elements
  static const double small = 8.0;

  /// Medium spacing (16px) - Default spacing
  static const double medium = 16.0;

  /// Large spacing (24px) - For section separation
  static const double large = 24.0;

  /// Extra large spacing (32px) - For major sections
  static const double xlarge = 32.0;

  /// Extra extra large spacing (48px) - For screen-level separation
  static const double xxlarge = 48.0;

  // ============================================================================
  // HELPER METHODS - Common EdgeInsets patterns
  // ============================================================================

  /// Returns symmetric horizontal padding based on screen size
  /// 
  /// Example:
  /// ```dart
  /// Padding(
  ///   padding: AppSpacing.horizontal(context),
  ///   child: Text('Responsive padding'),
  /// )
  /// ```
  static EdgeInsets horizontal(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
    );
  }

  /// Returns symmetric vertical padding with responsive horizontal padding
  /// 
  /// Example:
  /// ```dart
  /// Padding(
  ///   padding: AppSpacing.horizontalWithVertical(context, vertical: 16),
  ///   child: Text('Responsive padding'),
  /// )
  /// ```
  static EdgeInsets horizontalWithVertical(
    BuildContext context, {
    required double vertical,
  }) {
    return EdgeInsets.symmetric(
      horizontal: getHorizontalPadding(context),
      vertical: vertical,
    );
  }

  /// Returns EdgeInsets with responsive horizontal padding and custom vertical values
  /// 
  /// Example:
  /// ```dart
  /// Padding(
  ///   padding: AppSpacing.fromLTRB(context, top: 16, bottom: 24),
  ///   child: Text('Custom vertical padding'),
  /// )
  /// ```
  static EdgeInsets fromLTRB(
    BuildContext context, {
    double? top,
    double? bottom,
  }) {
    final horizontalPadding = getHorizontalPadding(context);
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      top ?? 0,
      horizontalPadding,
      bottom ?? 0,
    );
  }

  /// Returns uniform padding on all sides based on screen size
  /// 
  /// Example:
  /// ```dart
  /// Padding(
  ///   padding: AppSpacing.all(context),
  ///   child: Text('Uniform padding'),
  /// )
  /// ```
  static EdgeInsets all(BuildContext context) {
    return EdgeInsets.all(getHorizontalPadding(context));
  }

  /// Returns EdgeInsets with only horizontal padding (no vertical)
  /// Useful for ListView.builder padding
  /// 
  /// Example:
  /// ```dart
  /// ListView.builder(
  ///   padding: AppSpacing.horizontalOnly(context),
  ///   itemBuilder: (context, index) => ListTile(...),
  /// )
  /// ```
  static EdgeInsets horizontalOnly(BuildContext context) {
    return EdgeInsets.only(
      left: getHorizontalPadding(context),
      right: getHorizontalPadding(context),
    );
  }

  // ============================================================================
  // FIXED PADDING HELPERS - For non-responsive scenarios
  // ============================================================================

  /// Standard horizontal padding (20px) - For fixed layouts
  static const EdgeInsets horizontalStandard = EdgeInsets.symmetric(
    horizontal: 20.0,
  );

  /// Small horizontal padding (16px) - For compact layouts
  static const EdgeInsets horizontalSmall = EdgeInsets.symmetric(
    horizontal: 16.0,
  );

  /// Large horizontal padding (24px) - For spacious layouts
  static const EdgeInsets horizontalLarge = EdgeInsets.symmetric(
    horizontal: 24.0,
  );

  // ============================================================================
  // VERTICAL SPACING HELPERS
  // ============================================================================

  /// Returns a SizedBox with extra small height (4px)
  static const Widget verticalXs = SizedBox(height: xs);

  /// Returns a SizedBox with small height (8px)
  static const Widget verticalSmall = SizedBox(height: small);

  /// Returns a SizedBox with medium height (16px)
  static const Widget verticalMedium = SizedBox(height: medium);

  /// Returns a SizedBox with large height (24px)
  static const Widget verticalLarge = SizedBox(height: large);

  /// Returns a SizedBox with extra large height (32px)
  static const Widget verticalXlarge = SizedBox(height: xlarge);

  /// Returns a SizedBox with extra extra large height (48px)
  static const Widget verticalXxlarge = SizedBox(height: xxlarge);

  // ============================================================================
  // HORIZONTAL SPACING HELPERS
  // ============================================================================

  /// Returns a SizedBox with extra small width (4px)
  static const Widget horizontalXs = SizedBox(width: xs);

  /// Returns a SizedBox with small width (8px)
  static const Widget horizontalSmallSpace = SizedBox(width: small);

  /// Returns a SizedBox with medium width (16px)
  static const Widget horizontalMedium = SizedBox(width: medium);

  /// Returns a SizedBox with large width (24px)
  static const Widget horizontalLargeSpace = SizedBox(width: large);

  /// Returns a SizedBox with extra large width (32px)
  static const Widget horizontalXlarge = SizedBox(width: xlarge);
}
