import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class IOSFloatingBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<IOSBottomNavItem> items;

  const IOSFloatingBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  State<IOSFloatingBottomNav> createState() => _IOSFloatingBottomNavState();
}

class _IOSFloatingBottomNavState extends State<IOSFloatingBottomNav> {
  @override
  Widget build(BuildContext context) {
    return Container(
      // Transparent background - no black background
      color: Colors.transparent,
      // Position lower with reduced bottom padding
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8, // Reduced from 20 to 8
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), // Increased blur for better glass effect
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              // More translucent for better glassmorphism
              color: Colors.white.withValues(alpha: 0.15), // Reduced from 0.95 to 0.15
              borderRadius: BorderRadius.circular(35),
              // Enhanced glass border
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3), // Increased border opacity
                width: 1.0, // Increased border width
              ),
              // Multiple gradient layers for glass effect
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.25), // Top highlight
                  Colors.white.withValues(alpha: 0.10), // Bottom shadow
                ],
                stops: const [0.0, 1.0],
              ),
              // Enhanced shadow for floating effect
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2), // Increased shadow opacity
                  blurRadius: 30, // Increased blur
                  offset: const Offset(0, 15), // Increased offset
                  spreadRadius: -2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 60,
                  offset: const Offset(0, 30),
                  spreadRadius: -5,
                ),
                // Additional inner glow
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  widget.items.length,
                  (index) => _buildNavItem(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final isSelected = widget.currentIndex == index;
    final item = widget.items[index];

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          // Enhanced selected state with glassmorphism
          color: isSelected 
              ? const Color(0xFF1A1A1A).withValues(alpha: 0.9) // Darker with transparency
              : Colors.transparent,
          borderRadius: BorderRadius.circular(27),
          // Add subtle border for selected state
          border: isSelected 
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 0.5,
                )
              : null,
          // Add subtle shadow for selected state
          boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            isSelected ? item.activeIcon : item.inactiveIcon,
            color: isSelected 
                ? Colors.white // White icon on dark background
                : Colors.white.withValues(alpha: 0.7), // More visible on translucent background
            size: 24,
          ),
        ),
      ),
    );
  }
}

class IOSBottomNavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const IOSBottomNavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}