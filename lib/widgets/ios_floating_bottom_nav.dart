import 'dart:ui';

import 'package:flutter/material.dart';

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
      color: Colors.transparent,
      // Shorter horizontal margins for more compact width
      padding: EdgeInsets.only(
        left: 45,
        right: 45,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Container(
        height: 66, // Slightly increased height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(33),
          // Premium shadow system for maximum visibility and depth
          boxShadow: [
            // Primary elevation shadow - stronger for better separation
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 35,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            // Definition shadow for crisp professional edges
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -2,
            ),
            // Ambient floating shadow for premium depth
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -5,
            ),
            // Close contact shadow for content separation
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 15,
              sigmaY: 15,
            ), // Refined blur for crisp glassmorphic effect with better readability
            child: Container(
              decoration: BoxDecoration(
                // Premium glassmorphic background - professional opacity for clear visibility
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.85), // Strong top layer for visibility
                    Colors.white.withOpacity(0.75), // Solid middle layer
                    Colors.grey.shade100.withOpacity(0.9), // Strong base for contrast
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(33),
                // Refined border for clean definition
                border: Border.all(
                  color: Colors.white.withOpacity(0.8), // Strong border for definition
                  width: 1.2, // Slightly thicker for premium feel
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                ), // Much tighter spacing
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween, // Better edge alignment
                  children: List.generate(
                    widget.items.length,
                    (index) => _buildNavItem(index),
                  ),
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
    final isFirstItem = index == 0;
    final isLastItem = index == widget.items.length - 1;

    return GestureDetector(
      onTap: () => widget.onTap(index),
      child: Container(
        // Minimal padding for tighter spacing between icons
        padding: EdgeInsets.only(
          left: isFirstItem ? 0 : 2,
          right: isLastItem ? 0 : 2,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: 58, // Slightly larger selection pill
          height: 58,
          decoration: BoxDecoration(
            // Premium black selection circle with maximum contrast
            color:
                isSelected
                    ? Colors.black // Pure black for maximum contrast on light background
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(29),
            // Premium shadow for selected state - enhanced visibility
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        spreadRadius: 0,
                      ),
                    ]
                    : null,
          ),
          child: Center(
            child: Icon(
              isSelected ? item.activeIcon : item.inactiveIcon,
              color:
                  isSelected
                      ? Colors.white // White icon on black circle
                      : Colors.grey.shade800, // Darker for maximum contrast on light background
              size: 24, // Slightly larger icon for bigger pill
            ),
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
