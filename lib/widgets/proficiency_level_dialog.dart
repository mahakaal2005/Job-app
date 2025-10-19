import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class ProficiencyLevelDialog extends StatefulWidget {
  final int initialLevel;
  final String title;

  const ProficiencyLevelDialog({
    super.key,
    required this.initialLevel,
    required this.title,
  });

  @override
  State<ProficiencyLevelDialog> createState() => _ProficiencyLevelDialogState();
}

class _ProficiencyLevelDialogState extends State<ProficiencyLevelDialog> {
  late int _selectedLevel;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.initialLevel;
  }

  void _selectLevel(int level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _done() {
    Navigator.pop(context, _selectedLevel);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Background overlay (positioned at x: 0, y: 0 from Figma)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: const Color(0xFF2C373B).withOpacity(0.6), // From Figma fill_O4QYDC
            ),
            
            // Dialog content (positioned at x: 20, y: 73 from Figma)
            Positioned(
              left: 20,
              top: 73,
              child: Container(
                width: 335,
                height: 666,
                decoration: BoxDecoration(
                  color: AppColors.white, // From Figma fill_5S7EI7
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Top divider line (positioned at x: 173, y: 103 from Figma)
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Container(
                        width: 30,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B5858), // From Figma stroke_YVN1W0
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 41),
                    
                    // Levels list (positioned at x: 50, y: 144 from Figma)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: 11, // Levels 0-10
                                itemBuilder: (context, index) {
                                  final level = 10 - index; // Reverse order (10 to 0)
                                  final isSelected = _selectedLevel == level;
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 25),
                                    child: GestureDetector(
                                      onTap: () => _selectLevel(level),
                                      child: Row(
                                        children: [
                                          // Level text
                                          Text(
                                            'Level $level',
                                            style: const TextStyle(
                                              fontFamily: 'Open Sans',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 14,
                                              height: 1.362,
                                              color: Color(0xFF524B6B), // From Figma fill_3PVYQ6
                                            ),
                                          ),
                                          
                                          const Spacer(),
                                          
                                          // Radio button (positioned at x: 257, y: 1 from Figma)
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected 
                                                    ? const Color(0xFFFF9228)
                                                    : const Color(0xFF524B6B),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Center(
                                                    child: Container(
                                                      width: 12,
                                                      height: 12,
                                                      decoration: const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color(0xFFFF9228),
                                                      ),
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Done button (positioned at x: 50, y: 659 from Figma)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(50, 0, 50, 30),
                      child: GestureDetector(
                        onTap: _done,
                        child: Container(
                          width: 275,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF130160), // From Figma fill_IXQUHH
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
                              'DONE',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                height: 1.302,
                                letterSpacing: 0.84,
                                color: AppColors.white, // From Figma fill_5S7EI7
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}