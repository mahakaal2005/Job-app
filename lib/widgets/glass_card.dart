import 'package:flutter/material.dart';
import 'package:glass_kit/glass_kit.dart';
import 'package:get_work_app/utils/app_colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer.frostedGlass(
      width: double.infinity,
      height: 200, // Default height, will be overridden by child
      borderRadius: BorderRadius.circular(24),
      blur: 15,
      frostedOpacity: 0.2,
      child: Padding(padding: padding, child: child),
    );
  }
}