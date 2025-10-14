import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class AboutMeScreen extends StatefulWidget {
  const AboutMeScreen({super.key});

  @override
  State<AboutMeScreen> createState() => _AboutMeScreenState();
}

class _AboutMeScreenState extends State<AboutMeScreen> {
  final TextEditingController _aboutController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  String _originalText = '';
  bool _hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _loadAboutData();
  }

  @override
  void dispose() {
    _aboutController.removeListener(_onTextChanged);
    _aboutController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasChanges = _aboutController.text.trim() != _originalText.trim();
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Future<void> _loadAboutData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employee' ? 'employees' : 'users_specific';

        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        if (doc.exists && mounted) {
          final userData = doc.data() ?? {};
          setState(() {
            _originalText = userData['bio'] ?? '';
            _aboutController.text = _originalText;
            _isLoading = false;
          });

          // Listen for changes
          _aboutController.addListener(_onTextChanged);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Error loading about information: $e');
      }
    }
  }

  Future<void> _saveAboutData() async {
    if (_aboutController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter some information about yourself');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employee' ? 'employees' : 'users_specific';

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
              'bio': _aboutController.text.trim(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          setState(() {
            _originalText = _aboutController.text.trim();
            _hasUnsavedChanges = false;
          });
          _showSuccessSnackBar('About information saved successfully!');
          Navigator.pop(
            context,
            true,
          ); // Return true to indicate data was saved
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving about information: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.white,
              size: 20,
            ),
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

  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final result = await _showUndoModal();
      return result ?? false;
    }
    return true;
  }

  Future<bool?> _showUndoModal() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUndoModal(),
    );
  }

  void _showSaveConfirmation() {
    if (_hasUnsavedChanges) {
      _showSaveUndoModal();
    } else {
      // No changes, save directly
      _saveAboutData();
    }
  }

  Future<void> _showSaveUndoModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSaveUndoModal(),
    );
  }

  Widget _buildUndoModal() {
    return Stack(
      children: [
        // Background overlay - tap to dismiss
        GestureDetector(
          onTap: () => Navigator.pop(context, false),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF2C373B).withValues(alpha: 0.6),
          ),
        ),

        // Modal content with drag-to-dismiss
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // If dragging down, dismiss the modal
              if (details.delta.dy > 0) {
                Navigator.pop(context, false);
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Draggable area with divider line
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          // Enhanced drag sensitivity for the handle area
                          if (details.delta.dy > 2) {
                            Navigator.pop(context, false);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.lookGigProfileText,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Title
                      const Text(
                        'Undo Changes ?',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.302,
                          color: AppColors.lookGigProfileText,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          'Are you sure you want to change what you entered?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.302,
                            color: Color(0xFF524B6B),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 56),

                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 81),
                        child: Column(
                          children: [
                            // Continue Filling button
                            GestureDetector(
                              onTap: () => Navigator.pop(context, false),
                              child: Container(
                                width: 213,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.lookGigPurple,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF99ABC6,
                                      ).withValues(alpha: 0.18),
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
                                      color: AppColors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Undo Changes button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _aboutController.text = _originalText;
                                  _hasUnsavedChanges = false;
                                });
                                Navigator.pop(context, true);
                              },
                              child: Container(
                                width: 213,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6CDFE),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF99ABC6,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 62,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'UNDO CHANGES',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      height: 1.302,
                                      letterSpacing: 0.84,
                                      color: AppColors.white,
                                      decoration: TextDecoration.none,
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.lookGigLightGray,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.lookGigPurple),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.lookGigLightGray,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Header with back button
                    Padding(
                      padding: const EdgeInsets.all(20),
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
                                color: AppColors.lookGigProfileText,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.arrow_back,
                                    color: AppColors.lookGigProfileText,
                                    size: 24,
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // About me section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            // About me card
                            SizedBox(
                              width: 335,
                              height: 284,
                              child: Stack(
                                children: [
                                  // Title
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Text(
                                      'About me',
                                      style: const TextStyle(
                                        fontFamily: 'Open Sans',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        height: 1.362,
                                        color: AppColors.lookGigProfileText,
                                      ),
                                    ),
                                  ),

                                  // Input card
                                  Positioned(
                                    top: 52,
                                    left: 0,
                                    child: Container(
                                      width: 335,
                                      height: 232,
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF99ABC6,
                                            ).withValues(alpha: 0.18),
                                            blurRadius: 62,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Tell me about you.',
                                              style: TextStyle(
                                                fontFamily: 'Open Sans',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12,
                                                height: 1.362,
                                                color: Color(0xFFAAA6B9),
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Expanded(
                                              child: TextField(
                                                controller: _aboutController,
                                                maxLines: null,
                                                expands: true,
                                                textAlignVertical:
                                                    TextAlignVertical.top,
                                                decoration: const InputDecoration(
                                                  border: InputBorder.none,
                                                  enabledBorder:
                                                      InputBorder.none,
                                                  focusedBorder:
                                                      InputBorder.none,
                                                  errorBorder: InputBorder.none,
                                                  focusedErrorBorder:
                                                      InputBorder.none,
                                                  hintText:
                                                      'Write about yourself, your experience, skills, and what makes you unique...',
                                                  hintStyle: TextStyle(
                                                    fontFamily: 'Open Sans',
                                                    fontWeight: FontWeight.w400,
                                                    fontSize: 14,
                                                    color: Color(0xFFAAA6B9),
                                                  ),
                                                ),
                                                style: const TextStyle(
                                                  fontFamily: 'Open Sans',
                                                  fontWeight: FontWeight.w400,
                                                  fontSize: 14,
                                                  color:
                                                      AppColors
                                                          .lookGigProfileText,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Save button
                            Center(
                              child: GestureDetector(
                                onTap: _isSaving ? null : _showSaveConfirmation,
                                child: Container(
                                  width: 213,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: AppColors.lookGigPurple,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF99ABC6,
                                        ).withValues(alpha: 0.18),
                                        blurRadius: 62,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child:
                                        _isSaving
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
                                                color: AppColors.white,
                                              ),
                                            ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSaveUndoModal() {
    return Stack(
      children: [
        // Background overlay - tap to dismiss
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF2C373B).withValues(alpha: 0.6),
          ),
        ),

        // Modal content with drag-to-dismiss
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              // If dragging down, dismiss the modal
              if (details.delta.dy > 0) {
                Navigator.pop(context);
              }
            },
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Draggable area with divider line
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          // Enhanced drag sensitivity for the handle area
                          if (details.delta.dy > 2) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.lookGigProfileText,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 35),

                      // Title
                      const Text(
                        'Undo Changes ?',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.302,
                          color: AppColors.lookGigProfileText,
                          decoration: TextDecoration.none,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Subtitle
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          'Are you sure you want to change what you entered?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            height: 1.302,
                            color: Color(0xFF524B6B),
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 56),

                      // Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 81),
                        child: Column(
                          children: [
                            // Continue Filling button (SAVES the data when triggered from save button)
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context); // Close modal
                                _saveAboutData(); // Actually save the data
                              },
                              child: Container(
                                width: 213,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.lookGigPurple,
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF99ABC6,
                                      ).withValues(alpha: 0.18),
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
                                      color: AppColors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Undo Changes button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _aboutController.text = _originalText;
                                  _hasUnsavedChanges = false;
                                });
                                Navigator.pop(context); // Close modal
                                Navigator.pop(context); // Go back to profile
                              },
                              child: Container(
                                width: 213,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6CDFE),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF99ABC6,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 62,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'UNDO CHANGES',
                                    style: TextStyle(
                                      fontFamily: 'DM Sans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      height: 1.302,
                                      letterSpacing: 0.84,
                                      color: AppColors.white,
                                      decoration: TextDecoration.none,
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
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
