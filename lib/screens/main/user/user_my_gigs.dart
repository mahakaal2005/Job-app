import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class MyGigsScreen extends StatelessWidget {
  const MyGigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.background, // Use our dark theme background instead of lightGrey
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                'My Gigs',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // Use our white text instead of black
                ),
              ),
            ),
          ),
          // Bottom spacing for floating navigation
          SizedBox(height: MediaQuery.of(context).padding.bottom + 100),
        ],
      ),
    );
  }
}
