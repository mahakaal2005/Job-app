import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/profile/skill_search_screen.dart';

class SkillsScreen extends StatefulWidget {
  const SkillsScreen({super.key});

  @override
  State<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends State<SkillsScreen> {
  List<String> _selectedSkills = [];
  List<String> _originalSkills = []; // Track original skills to identify new ones
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserSkills();
  }

  Future<void> _loadUserSkills() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employer' ? 'employers' : 'users_specific';

        final doc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null) {
          final skills = doc.data()!['skills'];
          if (skills is List) {
            setState(() {
              _selectedSkills = List<String>.from(skills);
              _originalSkills = List<String>.from(skills); // Store original skills
              _isLoading = false;
            });
          } else {
            setState(() {
              _selectedSkills = [];
              _originalSkills = [];
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _selectedSkills = [];
            _originalSkills = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading skills: $e');
    }
  }

  Future<void> _saveSkills() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employer' ? 'employers' : 'users_specific';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
          'skills': _selectedSkills,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update profile completion status
        AuthService.updateProfileCompletionStatus();

        if (mounted) {
          _showSuccessSnackBar('Skills saved successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving skills: $e');
      }
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
    });
  }

  Future<void> _navigateToSkillSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SkillSearchScreen(
          selectedSkills: _selectedSkills,
          originalSkills: _originalSkills,
        ),
      ),
    );

    if (result != null && result is List<String>) {
      setState(() {
        _selectedSkills = result;
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
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_WT2HB1
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
                        'assets/images/about_me_back_icon.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF524B6B),
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF524B6B),
                            size: 24,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (positioned at x: 0, y: 0 from Figma)
                    const Text(
                      'Add Skill',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF150B3D), // From Figma fill_DT3Q30
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Search bar (positioned at x: 0, y: 52 from Figma)
                    GestureDetector(
                      onTap: _navigateToSkillSearch,
                      child: Container(
                        width: 335,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.white, // From Figma fill_CA85JC
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Search icon (positioned at x: 15, y: 8 from Figma)
                            const Padding(
                              padding: EdgeInsets.only(left: 15),
                              child: Icon(
                                Icons.search,
                                size: 24,
                                color: Color(0xFFAAA6B9), // From Figma fill_ZF2IXW
                              ),
                            ),
                            
                            // Search text (positioned at x: 49, y: 12 from Figma)
                            const Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text(
                                'Search skills',
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(0xFFAAA6B9), // From Figma fill_ZF2IXW
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Skills grid (positioned at x: 0, y: 122 from Figma)
                    Expanded(
                      child: _buildSkillsGrid(),
                    ),
                  ],
                ),
              ),
            ),

            // Save button (positioned at x: 81, y: 672 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(81, 0, 81, 50),
              child: GestureDetector(
                onTap: _isSaving ? null : _saveSkills,
                child: Container(
                  width: 213,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF130160), // From Figma fill_UQPIB7
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
                              color: AppColors.white, // From Figma fill_CA85JC
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

  Widget _buildSkillsGrid() {
    if (_selectedSkills.isEmpty) {
      return const Center(
        child: Text(
          'No skills added yet.\nTap the search bar to add skills.',
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

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _selectedSkills.asMap().entries.map((entry) {
        final index = entry.key;
        final skill = entry.value;
        
        // Highlight NEW skills that weren't in the original list
        final isHighlighted = !_originalSkills.contains(skill);

        return _buildSkillChip(skill, isHighlighted);
      }).toList(),
    );
  }

  Widget _buildSkillChip(String skill, bool isHighlighted) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? const Color(0xFFFF9228) // From Figma fill_L1IL8Z (orange)
            : const Color(0xFFCBC9D4).withOpacity(0.2), // From Figma fill_CNKLBU with opacity
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Skill text
          Text(
            skill,
            style: TextStyle(
              fontFamily: isHighlighted ? 'Open Sans' : 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              height: isHighlighted ? 1.362 : 1.302,
              color: isHighlighted 
                  ? AppColors.white // From Figma fill_CA85JC
                  : const Color(0xFF524B6B), // From Figma fill_E8YV6V
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove button
          GestureDetector(
            onTap: () => _removeSkill(skill),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Icon(
                Icons.close,
                size: 16,
                color: isHighlighted 
                    ? AppColors.white
                    : const Color(0xFF150A33),
              ),
            ),
          ),
        ],
      ),
    );
  }
}