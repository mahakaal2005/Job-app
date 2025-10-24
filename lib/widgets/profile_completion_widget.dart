import 'package:flutter/material.dart';

class ProfileCompletionWidget extends StatelessWidget {
  final bool showDetailedView;
  final VoidCallback? onCompletePressed;

  const ProfileCompletionWidget({
    super.key,
    this.showDetailedView = false,
    this.onCompletePressed,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Completely disabled
  }
}

class ProfileCompletionBadge extends StatelessWidget {
  const ProfileCompletionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // Completely disabled
  }
}