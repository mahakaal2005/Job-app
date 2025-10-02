import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_colors.dart';

class GlassmorphismUtils {
  /// Creates a 3D floating glassmorphism container (matching reference design)
  static Widget floating3DContainer({
    required Widget child,
    double borderRadius = 20.0,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.5,
    double blur = 25.0,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    bool hasShadow = true,
    double elevation = 12.0,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: hasShadow ? [
          // Primary shadow for depth
          BoxShadow(
            color: AppColors.glassDark20,
            blurRadius: elevation * 2,
            offset: Offset(0, elevation * 0.8),
            spreadRadius: -2,
          ),
          // Secondary shadow for floating effect
          BoxShadow(
            color: AppColors.glassDark15,
            blurRadius: elevation * 3,
            offset: Offset(0, elevation * 1.5),
            spreadRadius: -4,
          ),
          // Subtle glow effect
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.1),
            blurRadius: elevation,
            offset: Offset(0, elevation * 0.3),
            spreadRadius: 0,
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glass15,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.glassWhite.withValues(alpha: 0.15),
                  AppColors.glass10,
                  AppColors.glassDark10,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a TRUE glassmorphism container with enhanced blur effect (matching reference design)
  static Widget glassContainer({
    required Widget child,
    double borderRadius = 16.0,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
    double blur = 20.0, // Increased blur for better effect
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    bool hasShadow = true,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow:
            hasShadow
                ? [
                  BoxShadow(
                    color: AppColors.glassDark10,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: AppColors.glassDark05,
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                    spreadRadius: 0,
                  ),
                ]
                : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.glass15,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: AppColors.glassGradient,
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates a portfolio-style glass card (matching the reference design)
  static Widget portfolioCard({
    required Widget child,
    double borderRadius = 24.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20.0),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 4.0,
    ),
    bool isActive = false,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassDark15,
            blurRadius: 30,
            offset: const Offset(0, 12),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.glassDark10,
            blurRadius: 60,
            offset: const Offset(0, 24),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25), // Enhanced blur
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: isActive ? AppColors.cardGlassActive : AppColors.cardGlass,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color:
                    isActive
                        ? AppColors.glassBorderStrong
                        : AppColors.glassBorder,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isActive
                        ? AppColors.glassGradientStrong
                        : AppColors.glassGradient,
                stops: const [0.0, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates iOS-style floating bottom navigation with TRUE glass effect
  static Widget glassBottomNav({
    required Widget child,
    EdgeInsetsGeometry margin = const EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 32,
    ),
    double borderRadius = 28.0,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassDark20,
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: AppColors.glassDark10,
            blurRadius: 80,
            offset: const Offset(0, 40),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 30,
            sigmaY: 30,
          ), // Strong blur for nav
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glass20,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.glassBorderStrong,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: AppColors.glassGradientStrong,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates financial/portfolio style glass button
  static Widget portfolioButton({
    required Widget child,
    required VoidCallback onTap,
    double borderRadius = 16.0,
    Color? backgroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 16.0,
    ),
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.glassDark10,
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                color:
                    isPrimary
                        ? AppColors.primaryAccent.withValues(alpha: 0.9)
                        : backgroundColor ?? AppColors.glass20,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color:
                      isPrimary ? AppColors.primaryAccent : AppColors.glassBorder,
                  width: 1.0,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Creates enhanced glass drawer (side navigation)
  static Widget glassDrawer({required Widget child, double width = 300}) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: AppColors.glassDark20,
            blurRadius: 50,
            offset: const Offset(-10, 0),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glass10,
              border: Border(
                left: BorderSide(color: AppColors.glassBorder, width: 1.5),
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [AppColors.glass15, AppColors.glass10],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates 3D floating button with premium glossy effect (like green app reference)
  static Widget floating3DButton({
    required Widget child,
    required VoidCallback onTap,
    double borderRadius = 16.0,
    Color? backgroundColor,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(
      horizontal: 24.0,
      vertical: 16.0,
    ),
    bool isPrimary = false,
    double elevation = 8.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            // Main elevated shadow for depth
            BoxShadow(
              color: isPrimary 
                ? AppColors.primaryAccent.withValues(alpha: 0.25)
                : AppColors.glassDark20,
              blurRadius: elevation * 2.5,
              offset: Offset(0, elevation * 1.2),
              spreadRadius: -2,
            ),
            // Closer definition shadow
            BoxShadow(
              color: isPrimary
                ? AppColors.primaryAccent.withValues(alpha: 0.15)
                : AppColors.glassDark15,
              blurRadius: elevation,
              offset: Offset(0, elevation * 0.5),
              spreadRadius: -1,
            ),
            // Subtle glow for premium effect
            BoxShadow(
              color: isPrimary 
                ? AppColors.primaryAccent.withValues(alpha: 0.1)
                : AppColors.glassWhite.withValues(alpha: 0.05),
              blurRadius: elevation * 1.5,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: isPrimary 
                    ? AppColors.primaryAccent.withValues(alpha: 0.3)
                    : AppColors.glassBorder,
                  width: 1.2,
                ),
                gradient: isPrimary ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryAccent.withValues(alpha: 0.95),
                    AppColors.primaryAccent.withValues(alpha: 0.85),
                    AppColors.accentDeep.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ) : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.glassWhite.withValues(alpha: 0.2),
                    AppColors.glass15,
                    AppColors.glass10,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: Center(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Creates premium 3D floating card with dramatic elevation (like green app reference)
  static Widget floating3DCard({
    required Widget child,
    double borderRadius = 24.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20.0),
    EdgeInsetsGeometry margin = const EdgeInsets.symmetric(
      vertical: 8.0,
      horizontal: 4.0,
    ),
    bool isActive = false,
    double elevation = 12.0,
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Main dramatic elevation shadow
          BoxShadow(
            color: AppColors.glassDark20.withValues(alpha: 0.25),
            blurRadius: elevation * 3.5,
            offset: Offset(0, elevation * 1.5),
            spreadRadius: -2,
          ),
          // Mid-level definition shadow
          BoxShadow(
            color: AppColors.glassDark15.withValues(alpha: 0.18),
            blurRadius: elevation * 2,
            offset: Offset(0, elevation * 0.8),
            spreadRadius: -4,
          ),
          // Close contact shadow
          BoxShadow(
            color: AppColors.glassDark10.withValues(alpha: 0.12),
            blurRadius: elevation,
            offset: Offset(0, elevation * 0.3),
            spreadRadius: -1,
          ),
          // Ambient floating shadow
          BoxShadow(
            color: AppColors.glassDark05.withValues(alpha: 0.08),
            blurRadius: elevation * 5,
            offset: Offset(0, elevation * 2.5),
            spreadRadius: -8,
          ),
          // Accent glow for active state
          if (isActive) BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: 0.15),
            blurRadius: elevation * 1.5,
            offset: Offset(0, elevation * 0.5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: isActive
                  ? AppColors.glassBorderStrong.withValues(alpha: 0.8)
                  : AppColors.glassBorder.withValues(alpha: 0.6),
                width: 1.2,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.glassWhite.withValues(alpha: isActive ? 0.18 : 0.15),
                  isActive ? AppColors.glass25 : AppColors.glass20,
                  isActive ? AppColors.glass15 : AppColors.glass10,
                  AppColors.glassDark05,
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius - 1),
                // Subtle glossy highlight for premium effect
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.08),
                    Colors.white.withValues(alpha: 0.03),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  /// Creates 3D floating header with glassmorphic background
  static Widget floating3DHeader({
    required Widget child,
    double borderRadius = 28.0,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20.0),
    EdgeInsetsGeometry margin = const EdgeInsets.all(16.0),
  }) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.glassDark25,
            blurRadius: 25,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: AppColors.glassDark15,
            blurRadius: 50,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.glassBorderStrong,
                width: 1.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.headerDark.withValues(alpha: 0.95),
                  AppColors.headerCore.withValues(alpha: 0.9),
                  AppColors.headerMid.withValues(alpha: 0.85),
                  AppColors.headerLight.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  /// Creates portfolio-style stat card (like in reference image)
  static Widget portfolioStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    Color accentColor = AppColors.primaryAccent,
    EdgeInsetsGeometry margin = const EdgeInsets.all(8.0),
  }) {
    return floating3DCard(
      margin: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              floating3DContainer(
                padding: const EdgeInsets.all(12),
                backgroundColor: accentColor.withValues(alpha: 0.15),
                borderColor: accentColor.withValues(alpha: 0.3),
                borderRadius: 12,
                elevation: 6,
                child: Icon(icon, color: accentColor, size: 24),
              ),
              Icon(Icons.more_horiz, color: AppColors.glassGray, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.glassGray,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: accentColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
