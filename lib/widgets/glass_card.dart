import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/glassmorphism_utils.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;
  final bool isActive;
  final double elevation;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.margin = const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
    this.gradient,
    this.isActive = false,
    this.elevation = 12.0,
    this.borderRadius = 24.0,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismUtils.floating3DCard(
      padding: padding,
      margin: margin,
      isActive: isActive,
      elevation: elevation,
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: child,
      ),
    );
  }
}

/// Enhanced 3D Glass Card for special use cases
class Enhanced3DGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool isActive;
  final double elevation;
  final double borderRadius;
  final Color? accentColor;

  const Enhanced3DGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20.0),
    this.margin = const EdgeInsets.all(8.0),
    this.isActive = false,
    this.elevation = 15.0,
    this.borderRadius = 28.0,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismUtils.floating3DContainer(
      padding: padding,
      margin: margin,
      elevation: elevation,
      borderRadius: borderRadius,
      backgroundColor: isActive 
        ? AppColors.cardGlassActive 
        : AppColors.cardGlass,
      borderColor: isActive
        ? (accentColor ?? AppColors.primaryAccent).withValues(alpha: 0.5)
        : AppColors.glassBorder,
      child: child,
    );
  }
}