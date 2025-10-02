import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/utils/glassmorphism_utils.dart';

class Floating3DButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isPrimary;
  final bool isSecondary;
  final double elevation;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const Floating3DButton({
    super.key,
    required this.child,
    required this.onTap,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    this.borderRadius = 16.0,
    this.isPrimary = false,
    this.isSecondary = false,
    this.elevation = 8.0,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: GlassmorphismUtils.floating3DButton(
        padding: padding,
        borderRadius: borderRadius,
        isPrimary: isPrimary,
        elevation: elevation,
        backgroundColor: backgroundColor,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

/// Specialized 3D Action Button (like Withdraw/Deposit in reference)
class Action3DButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final Color? customColor;

  const Action3DButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    return Floating3DButton(
      onTap: onTap,
      isPrimary: isPrimary,
      borderRadius: 20.0,
      elevation: 10.0,
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 18.0),
      backgroundColor: customColor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isPrimary 
                ? AppColors.textOnAccent 
                : AppColors.primaryAccent,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: isPrimary 
                ? AppColors.textOnAccent 
                : AppColors.primaryAccent,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3D Chip Button (for filters, categories, etc.)
class Chip3DButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSelected;
  final IconData? icon;

  const Chip3DButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isSelected = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Floating3DButton(
      onTap: onTap,
      isPrimary: isSelected,
      borderRadius: 25.0,
      elevation: isSelected ? 8.0 : 4.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: isSelected 
                ? AppColors.textOnAccent 
                : AppColors.textSecondary,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(
              color: isSelected 
                ? AppColors.textOnAccent 
                : AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}