import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/profile/language_detail_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedLanguage;

  final List<Map<String, String>> _availableLanguages = [
    {'name': 'Arabic', 'flag': 'assets/images/arabic_flag.png'},
    {'name': 'Indonesian', 'flag': 'assets/images/indonesian_flag_selected.png'},
    {'name': 'Malaysian', 'flag': 'assets/images/malaysian_flag-5481af.png'},
    {'name': 'English', 'flag': 'assets/images/english_flag_unselected.png'},
    {'name': 'French', 'flag': 'assets/images/french_flag.png'},
    {'name': 'German', 'flag': 'assets/images/german_flag.png'},
    {'name': 'Hindi', 'flag': 'assets/images/hindi_flag.png'},
    {'name': 'Italian', 'flag': 'assets/images/italian_flag.png'},
    {'name': 'Japanese', 'flag': 'assets/images/japanese_flag.png'},
    {'name': 'Korean', 'flag': 'assets/images/korean_flag.png'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return _availableLanguages;
    }
    return _availableLanguages
        .where((language) => 
            language['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _selectLanguage(String languageName) async {
    setState(() {
      _selectedLanguage = languageName;
    });
    
    // Find the flag for this language
    final languageData = _availableLanguages.firstWhere(
      (lang) => lang['name'] == languageName,
      orElse: () => {'name': languageName, 'flag': 'assets/images/indonesian_flag.png'},
    );
    
    // Navigate to language detail screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LanguageDetailScreen(
          languageName: languageName,
          languageFlag: languageData['flag']!,
        ),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      // Language was configured, return to main language screen
      Navigator.pop(context, result);
    }
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
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_WD4S5D
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
                        color: Color(0xFF150B3D), // From Figma fill_0DUQOU
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Search bar (positioned at x: 0, y: 52 from Figma)
                    Container(
                      width: 335,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white, // From Figma fill_D2F2T2
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Search icon (positioned at x: 15, y: 8 from Figma)
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                'assets/images/language_search_icon.png',
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.search,
                                    size: 24,
                                    color: Color(0xFFAAA6B9),
                                  );
                                },
                              ),
                            ),
                          ),
                          
                          // Search text field (positioned at x: 49, y: 12 from Figma)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 15),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() {
                                    _searchQuery = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  hintText: 'Search skills',
                                  hintStyle: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: Color(0xFFAAA6B9), // From Figma fill_Y4G84D
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  focusedErrorBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(0xFF150B3D),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Languages list
                    Expanded(
                      child: _buildLanguagesList(),
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

  Widget _buildLanguagesList() {
    final filteredLanguages = _filteredLanguages;

    if (filteredLanguages.isEmpty) {
      return const Center(
        child: Text(
          'No languages found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF524B6B),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredLanguages.length,
      itemBuilder: (context, index) {
        final language = filteredLanguages[index];
        final languageName = language['name']!;
        final isSelected = _selectedLanguage == languageName;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: GestureDetector(
            onTap: () => _selectLanguage(languageName),
            child: Container(
              width: 335,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFFA993FF) // From Figma fill_IQE48K (selected)
                    : AppColors.white, // From Figma fill_D2F2T2 (unselected)
                borderRadius: BorderRadius.circular(isSelected ? 15 : 10),
                boxShadow: isSelected 
                    ? [
                        BoxShadow(
                          color: const Color(0xFF99ABC6).withOpacity(0.18),
                          blurRadius: 62,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Flag icon (positioned at x: 15, y: 9 from Figma)
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: isSelected 
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: Image.asset(
                          language['flag']!,
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
                  ),
                  
                  // Language name (positioned at x: 55, y: 16 from Figma)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        languageName,
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 12,
                          height: 1.302,
                          color: isSelected 
                              ? AppColors.white // From Figma fill_D2F2T2 (selected text)
                              : const Color(0xFF150B3D), // From Figma fill_0DUQOU (unselected text)
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}