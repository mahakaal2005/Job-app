import 'package:flutter/material.dart';

class CustomRangeSliderThumbShape extends RangeSliderThumbShape {
  final double thumbRadius;
  final Color thumbColor;
  final Color borderColor;
  final double borderWidth;

  const CustomRangeSliderThumbShape({
    this.thumbRadius = 15.0,
    this.thumbColor = const Color(0xFFFF9228),
    this.borderColor = const Color(0xFFFF9228),
    this.borderWidth = 3.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;

    // Draw outer dark black border (thick)
    final Paint outerBorderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0; // Thick black border

    // Draw inner white fill
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw the thumb with black border and white center
    canvas.drawCircle(center, thumbRadius, fillPaint); // White fill first
    canvas.drawCircle(center, thumbRadius, outerBorderPaint); // Black border on top
  }
}