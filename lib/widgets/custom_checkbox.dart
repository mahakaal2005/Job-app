import 'package:flutter/material.dart';

class CustomCheckbox extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double size;

  const CustomCheckbox({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.size = 20, // Slightly larger to match the design
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('CustomCheckbox: Building checkbox, isSelected: $isSelected');
    
    return GestureDetector(
      onTap: () {
        debugPrint('CustomCheckbox: Checkbox tapped, current state: $isSelected');
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4), // Rounded corners like in the image
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFFF9228) // Orange border when selected
                : const Color(0xFF9CA3AF), // Light gray border when unselected
            width: 2,
          ),
          color: Colors.transparent, // NO FILL - always transparent background
        ),
        child: isSelected
            ? const Icon(
                Icons.check,
                color: Color(0xFFFF9228), // Orange checkmark (same color as border)
                size: 14, // Proper size for the checkmark
              )
            : null,
      ),
    );
  }
}

class CustomRadioButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;
  final double size;
  final Color selectedColor;
  final Color unselectedColor;

  const CustomRadioButton({
    super.key,
    required this.isSelected,
    required this.onTap,
    this.size = 18,
    this.selectedColor = const Color(0xFFFF9228),
    this.unselectedColor = const Color(0xFF524B6B),
  });

  @override
  Widget build(BuildContext context) {
    debugPrint('CustomRadioButton: Building radio button, isSelected: $isSelected');
    
    return GestureDetector(
      onTap: () {
        debugPrint('CustomRadioButton: Radio button tapped, current state: $isSelected');
        onTap();
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? selectedColor : unselectedColor,
            width: 1.5,
          ),
          color: Colors.transparent,
        ),
        child: isSelected
            ? Center(
                child: Container(
                  width: size * 0.67, // 12/18 = 0.67
                  height: size * 0.67,
                  decoration: BoxDecoration(
                    color: selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}