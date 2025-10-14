import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/profile/language_selection_screen.dart';
import 'package:get_work_app/widgets/delete_language_modal.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  List<Map<String, dynamic>> _userLanguages = [];
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserLanguages();
  }

  Future<void> _loadUserLanguages() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employee' ? 'employees' : 'users_specific';

        final doc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final languages = doc.data()!['languages'];
          if (languages is List) {
            setState(() {
              _userLanguages = List<Map<String, dynamic>>.from(
                languages.map((lang) => lang is Map<String, dynamic> 
                    ? lang 
                    : {
                        'name': lang.toString(),
                        'type': 'Second language',
                        'oralLevel': 5,
                        'writtenLevel': 5,
                      }
                )
              );
              _isLoading = false;
            });
          } else {
            setState(() {
              _userLanguages = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _userLanguages = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading languages: $e');
    }
  }

  Future<void> _saveLanguages() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employee' ? 'employees' : 'users_specific';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
          'languages': _userLanguages,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSuccessSnackBar('Languages saved successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving languages: $e');
      }
    }
  }

  void _showDeleteConfirmation(int index) async {
    final language = _userLanguages[index];
    final languageName = language['name'] ?? 'Unknown';
    
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DeleteLanguageModal(languageName: languageName),
    );
    
    if (result == true) {
      // User confirmed deletion
      setState(() {
        _userLanguages.removeAt(index);
      });
    }
  }

  void _navigateToAddLanguage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LanguageSelectionScreen(),
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      // Language was added, add it to the list
      setState(() {
        _userLanguages.add(result);
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.white, size: 20),
            const SizedBox(width: 12),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lookGigPurple),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_QW9E02
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
                        'assets/images/language_back_icon.png',
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
                    // Title and Add button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title (positioned at x: 0, y: 0 from Figma)
                        const Text(
                          'Language',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            height: 1.302,
                            color: Color(0xFF150B3D), // From Figma fill_LXPQ7F
                          ),
                        ),
                        
                        // Add Language button (positioned at top right)
                        GestureDetector(
                          onTap: _navigateToAddLanguage,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Add text
                              const Text(
                                'Add',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  height: 1.302,
                                  color: Color(0xFF7551FF), // From Figma fill_8S3ZND
                                ),
                              ),
                              
                              const SizedBox(width: 8),
                              
                              // Add icon in circular background
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF7551FF).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Image.asset(
                                      'assets/images/language_add_icon.png',
                                      width: 20,
                                      height: 20,
                                      color: const Color(0xFF7551FF),
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.add,
                                          size: 20,
                                          color: Color(0xFF7551FF),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 52),

                    // Languages list
                    Expanded(
                      child: _buildLanguagesList(),
                    ),
                  ],
                ),
              ),
            ),

            // Save button (positioned at x: 81, y: 671 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(81, 0, 81, 50),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveLanguages,
                child: Container(
                  width: 213,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF130160), // From Figma fill_3OA8R3
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
                              color: AppColors.white, // From Figma fill_7B7P8D
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

  Widget _buildLanguagesList() {
    if (_userLanguages.isEmpty) {
      return const Center(
        child: Text(
          'No languages added yet.\nTap "Add" to add your first language.',
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
      itemCount: _userLanguages.length,
      itemBuilder: (context, index) {
        final language = _userLanguages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: _buildLanguageCard(language, index),
        );
      },
    );
  }

  Widget _buildLanguageCard(Map<String, dynamic> language, int index) {
    final languageName = language['name'] ?? 'Unknown';
    final languageType = language['type'] ?? 'Second language';
    final oralLevel = language['oralLevel'] ?? 5;
    final writtenLevel = language['writtenLevel'] ?? 5;

    return Container(
      width: 335,
      height: 127,
      decoration: BoxDecoration(
        color: AppColors.white, // From Figma fill_7B7P8D
        borderRadius: BorderRadius.circular(15),
      ),
      child: Stack(
        children: [
          // Delete icon (positioned at x: 296, y: 23 from Figma)
          Positioned(
            right: 15,
            top: 23,
            child: GestureDetector(
              onTap: () => _showDeleteConfirmation(index),
              child: SizedBox(
                width: 24,
                height: 24,
                child: Image.asset(
                  'assets/images/language_delete_icon.png',
                  width: 24,
                  height: 24,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.delete_outline,
                      size: 24,
                      color: Color(0xFFFC4646),
                    );
                  },
                ),
              ),
            ),
          ),

          // Flag icon (positioned at x: 15, y: 20 from Figma)
          Positioned(
            left: 15,
            top: 20,
            child: Container(
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
                  _getLanguageFlag(languageName),
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

          // Language name and type (positioned at x: 55, y: 27 from Figma)
          Positioned(
            left: 55,
            top: 27,
            child: Text(
              '$languageName($languageType)',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFF150B3D), // From Figma fill_LXPQ7F
              ),
            ),
          ),

          // Oral level (positioned at x: 15, y: 65 from Figma)
          Positioned(
            left: 15,
            top: 65,
            child: Text(
              'Oral : Level $oralLevel',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFFAAA6B9), // From Figma fill_YWWR10
              ),
            ),
          ),

          // Written level (positioned at x: 15, y: 91 from Figma)
          Positioned(
            left: 15,
            top: 91,
            child: Text(
              'Written : Level $writtenLevel',
              style: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                height: 1.302,
                color: Color(0xFFAAA6B9), // From Figma fill_YWWR10
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getLanguageFlag(String languageName) {
    switch (languageName.toLowerCase()) {
      case 'indonesian':
        return 'assets/images/indonesian_flag.png';
      case 'english':
        return 'assets/images/english_flag.png';
      case 'arabic':
        return 'assets/images/arabic_flag.png';
      case 'malaysian':
        return 'assets/images/malaysian_flag-5481af.png';
      case 'french':
        return 'assets/images/french_flag.png';
      case 'german':
        return 'assets/images/german_flag.png';
      case 'hindi':
        return 'assets/images/hindi_flag.png';
      case 'italian':
        return 'assets/images/italian_flag.png';
      case 'japanese':
        return 'assets/images/japanese_flag.png';
      case 'korean':
        return 'assets/images/korean_flag.png';
      default:
        return 'assets/images/indonesian_flag.png'; // Default flag
    }
  }
}