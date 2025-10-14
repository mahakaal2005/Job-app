import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class DeleteLanguageModal extends StatelessWidget {
  final String languageName;

  const DeleteLanguageModal({
    super.key,
    required this.languageName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 308,
      decoration: const BoxDecoration(
        color: AppColors.white, // From Figma fill_ES6TUJ
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Top divider line (positioned at x: 173, y: 529 from Figma)
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF150B3D), // From Figma stroke_TU2VB4
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Title (positioned at x: 103, y: 579 from Figma)
          Text(
            'Remove $languageName ?',
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.302,
              color: Color(0xFF150B3D), // From Figma fill_C2YN3W
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description (positioned at x: 28, y: 611 from Figma)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              'Are you sure you want to delete this $languageName language?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFF524B6B), // From Figma fill_PQ4ZW7
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Buttons (positioned at x: 29, y: 672 from Figma)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                // Continue Filling button
                GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    width: 317,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160), // From Figma fill_C1F8DF
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF99ABC6).withOpacity(0.18),
                          blurRadius: 62,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'CONTINUE FILLING',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          letterSpacing: 0.84,
                          color: AppColors.white, // From Figma fill_ES6TUJ
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Undo Changes button
                GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    width: 317,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6CDFE), // From Figma fill_JP537T
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text(
                        'UNDO CHANGES',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          height: 1.302,
                          letterSpacing: 0.84,
                          color: AppColors.white, // From Figma fill_ES6TUJ
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}