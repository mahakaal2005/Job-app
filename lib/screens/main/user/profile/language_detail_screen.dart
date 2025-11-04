import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/proficiency_level_dialog.dart';

class LanguageDetailScreen extends StatefulWidget {
  final String languageName;
  final String languageFlag;

  const LanguageDetailScreen({
    super.key,
    required this.languageName,
    required this.languageFlag,
  });

  @override
  State<LanguageDetailScreen> createState() => _LanguageDetailScreenState();
}

class _LanguageDetailScreenState extends State<LanguageDetailScreen> {
  bool _isFirstLanguage = false;
  int _oralLevel = 10;
  int _writtenLevel = 0;
  bool _isSaving = false;



  void _showOralLevelSelector() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => ProficiencyLevelDialog(
        initialLevel: _oralLevel,
        title: 'Oral Level',
      ),
    );
    
    if (result != null) {
      setState(() {
        _oralLevel = result;
      });
    }
  }

  void _showWrittenLevelSelector() async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) => ProficiencyLevelDialog(
        initialLevel: _writtenLevel,
        title: 'Written Level',
      ),
    );
    
    if (result != null) {
      setState(() {
        _writtenLevel = result;
      });
    }
  }

  void _saveLanguage() {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    // Create language object
    final languageData = {
      'name': widget.languageName,
      'type': _isFirstLanguage ? 'First language' : 'Second language',
      'oralLevel': _oralLevel,
      'writtenLevel': _writtenLevel,
    };

    // Return the language data to previous screen
    Navigator.pop(context, languageData);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_G29UD8
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (positioned at x: 20, y: 30 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: Image.asset(
                        'assets/images/language_search_back_icon.png',
                        width: 24,
                        height: 24,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF150A33),
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area (positioned at x: 20, y: 94 from Figma)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (positioned at x: 0, y: 0 from Figma)
                    const Text(
                      'Add Language',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF150A33), // From Figma fill_PWJ2I3
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Language section (positioned at x: 0, y: 52 from Figma)
                    Container(
                      width: 335,
                      decoration: BoxDecoration(
                        color: AppColors.white, // From Figma fill_T70EMH
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          // Language selection row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                            child: Row(
                              children: [
                                // "Language" label
                                const Text(
                                  'Language',
                                  style: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: Color(0xFF150B3D), // From Figma fill_55RLAC
                                  ),
                                ),
                                
                                const Spacer(),
                                
                                // Flag icon (positioned at x: 202, y: 0 from Figma)
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 4,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      widget.languageFlag,
                                      width: 30,
                                      height: 30,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          width: 30,
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF7551FF),
                                            borderRadius: BorderRadius.circular(28),
                                          ),
                                          child: const Icon(
                                            Icons.language,
                                            size: 16,
                                            color: AppColors.white,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 10),
                                
                                // Language name
                                Text(
                                  widget.languageName,
                                  style: const TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: Color(0xFF524B6B), // From Figma fill_6L16FY
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Divider line (positioned at x: 15, y: 70 from Figma)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                            child: Container(
                              width: 305,
                              height: 0.5,
                              color: const Color(0xFFDEE1E7), // From Figma stroke_MXYG94
                            ),
                          ),
                          
                          // First language checkbox
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isFirstLanguage = !_isFirstLanguage;
                                });
                              },
                              child: Row(
                                children: [
                                  const Text(
                                    'First language',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      height: 1.302,
                                      color: Color(0xFF150B3D), // From Figma fill_55RLAC
                                    ),
                                  ),
                                  
                                  const Spacer(),
                                  
                                  // Circular checkbox
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: _isFirstLanguage 
                                            ? const Color(0xFF2F51A7)
                                            : const Color(0xFFAAA6B9),
                                        width: 2,
                                      ),
                                    ),
                                    child: _isFirstLanguage
                                        ? Center(
                                            child: Container(
                                              width: 12,
                                              height: 12,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: Color(0xFF2F51A7),
                                              ),
                                            ),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Proficiency level section (positioned at x: 0, y: 206 from Figma)
                    Container(
                      width: 335,
                      height: 187,
                      decoration: BoxDecoration(
                        color: AppColors.white, // From Figma fill_T70EMH
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          // Oral level (positioned at x: 15, y: 27 from Figma)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 27, 15, 0),
                            child: GestureDetector(
                              onTap: _showOralLevelSelector,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Oral',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      height: 1.302,
                                      color: Color(0xFF150B3D), // From Figma fill_55RLAC
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 15),
                                  
                                  Text(
                                    'level $_oralLevel',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      height: 1.302,
                                      color: Color(0xFFAAA6B9), // From Figma fill_E55HMC
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          // Divider line (positioned at x: 15, y: 94 from Figma)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 20, 15, 0),
                            child: Container(
                              width: 305,
                              height: 0.5,
                              color: const Color(0xFFDEE1E7), // From Figma stroke_MXYG94
                            ),
                          ),
                          
                          // Written level (positioned at x: 15, y: 113 from Figma)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(15, 19, 15, 0),
                            child: GestureDetector(
                              onTap: _showWrittenLevelSelector,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Written',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      height: 1.302,
                                      color: Color(0xFF150B3D), // From Figma fill_55RLAC
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 15),
                                  
                                  Text(
                                    _writtenLevel == 0 
                                        ? 'Choose your speaking skill level'
                                        : 'level $_writtenLevel',
                                    style: const TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      height: 1.302,
                                      color: Color(0xFFAAA6B9), // From Figma fill_E55HMC
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Proficiency level note (positioned at x: 15, y: 408 from Figma)
                    const Padding(
                      padding: EdgeInsets.only(left: 15),
                      child: Text(
                        'Proficiency level : 0 - Poor, 10 - Very good',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: Color(0xFFAAA6B9), // From Figma fill_E55HMC
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Save button (positioned at x: 81, y: 670 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(81, 0, 81, 50),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveLanguage,
                child: Container(
                  width: 213,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF130160), // From Figma fill_FXKEH8
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF99ABC6).withOpacity(0.18),
                        blurRadius: 62,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'SAVE',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              height: 1.302,
                              letterSpacing: 0.84,
                              color: AppColors.white, // From Figma fill_T70EMH
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
