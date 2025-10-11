import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class MyGigsScreen extends StatelessWidget {
  const MyGigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.lightGrey,
      child: Center(
        child: Text(
          'My Gigs',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }
}