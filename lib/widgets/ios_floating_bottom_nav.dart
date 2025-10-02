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
          // Premium floating effect with multiple shadow layers
          boxShadow: [
            // Main elevated shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 35,
              offset: const Offset(0, 15),
              spreadRadius: 0,
            ),
            // Closer definition shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
              spreadRadius: -2,
            ),
            // Ambient glow shadow
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 50,
              offset: const Offset(0, 25),
              spreadRadius: -8,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(33),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              decoration: BoxDecoration(
                // Optimized glassmorphism gradient for background visibility
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.75),
                    Colors.white.withValues(alpha: 0.65),
                    Colors.grey.shade50.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
                borderRadius: BorderRadius.circular(33),
                // Subtle glossy border for background visibility
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.0,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8), // Much tighter spacing
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Better edge alignment
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
            // Pure black circle like green app - solid, not gradient
            color: isSelected ? Colors.black : Colors.transparent,
            borderRadius: BorderRadius.circular(29),
            // Enhanced shadow for selected pill
            boxShadow: isSelected 
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                      spreadRadius: -1,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              isSelected ? item.activeIcon : item.inactiveIcon,
              color: isSelected 
                  ? Colors.white // White icon on black circle
                  : Colors.grey.shade600, // Gray outline icons like green app
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