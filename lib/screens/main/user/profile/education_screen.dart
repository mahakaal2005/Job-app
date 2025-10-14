import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/screens/main/user/profile/education_level_selection_screen.dart';
import 'package:get_work_app/screens/main/user/profile/institution_selection_screen.dart';
import 'package:get_work_app/screens/main/user/profile/field_of_study_selection_screen.dart';
import 'package:get_work_app/widgets/custom_date_picker.dart';

class EducationScreen extends StatefulWidget {
  final Map<String, dynamic>? educationToEdit;

  const EducationScreen({super.key, this.educationToEdit});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _institutionController = TextEditingController();
  final TextEditingController _fieldController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentEducation = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    if (widget.educationToEdit != null) {
      _populateFields();
    }
    _addListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    _levelController.dispose();
    _institutionController.dispose();
    _fieldController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addListeners() {
    _levelController.addListener(_onFieldChanged);
    _institutionController.addListener(_onFieldChanged);
    _fieldController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _removeListeners() {
    _levelController.removeListener(_onFieldChanged);
    _institutionController.removeListener(_onFieldChanged);
    _fieldController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // For new education (add mode), never set unsaved changes
    if (widget.educationToEdit == null) {
      return;
    }
    
    final currentData = {
      'level': _levelController.text.trim(),
      'institution': _institutionController.text.trim(),
      'field': _fieldController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startDate': _startDate?.toIso8601String() ?? '',
      'endDate': _endDate?.toIso8601String() ?? '',
      'isCurrentEducation': _isCurrentEducation.toString(),
    };

    final hasChanges = !_mapsEqual(currentData, _originalData);
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;
    for (String key in map1.keys) {
      if (map1[key] != map2[key]) return false;
    }
    return true;
  }

  void _populateFields() {
    if (widget.educationToEdit != null) {
      final edu = widget.educationToEdit!;
      _levelController.text = edu['level'] ?? '';
      _institutionController.text = edu['institution'] ?? '';
      _fieldController.text = edu['field'] ?? '';
      _descriptionController.text = edu['description'] ?? '';
      _isCurrentEducation = edu['isCurrentEducation'] ?? false;

      // Safe date parsing with fallbacks
      if (edu['startDate'] != null) {
        _startDate = _parseDate(edu['startDate']);
      }

      if (edu['endDate'] != null && !_isCurrentEducation) {
        _endDate = _parseDate(edu['endDate']);
      }

      _originalData = {
        'level': _levelController.text.trim(),
        'institution': _institutionController.text.trim(),
        'field': _fieldController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDate?.toIso8601String() ?? '',
        'endDate': _endDate?.toIso8601String() ?? '',
        'isCurrentEducation': _isCurrentEducation.toString(),
      };
    }
  }

  DateTime? _parseDate(dynamic dateValue) {
    try {
      if (dateValue is String) {
        DateTime? parsed = DateTime.tryParse(dateValue);
        if (parsed != null) return parsed;

        // Try MM/yyyy format
        final parts = dateValue.split('/');
        if (parts.length == 2) {
          final month = int.tryParse(parts[0]);
          final year = int.tryParse(parts[1]);
          if (month != null && year != null && month >= 1 && month <= 12) {
            return DateTime(year, month);
          }
        }
      } else if (dateValue is Timestamp) {
        return dateValue.toDate();
      } else if (dateValue is DateTime) {
        return dateValue;
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    return null;
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      title: 'Start Date',
    );

    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && picked.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
      _onFieldChanged();
    }
  }

  Future<void> _selectEndDate() async {
    if (_isCurrentEducation) return;

    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(1950),
      lastDate: DateTime.now(),
      title: 'End Date',
    );

    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
      _onFieldChanged();
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showSaveConfirmation() {
    // For adding new education, always save directly
    if (widget.educationToEdit == null) {
      _saveEducation();
      return;
    }
    
    // For editing existing education, check for unsaved changes
    if (_hasUnsavedChanges) {
      _showSaveUndoModal();
    } else {
      // No changes, save directly
      _saveEducation();
    }
  }

  Future<void> _showSaveUndoModal() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildSaveUndoModal(),
    );
  }

  Future<void> _saveEducation() async {
    if (!_validateFields()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employee' ? 'employees' : 'users_specific';

        final educationData = {
          'level': _levelController.text.trim(),
          'institution': _institutionController.text.trim(),
          'field': _fieldController.text.trim(),
          'startDate': _startDate?.toIso8601String() ?? '',
          'endDate':
              _isCurrentEducation ? '' : (_endDate?.toIso8601String() ?? ''),
          'description': _descriptionController.text.trim(),
          'isCurrentEducation': _isCurrentEducation,
        };

        // Get current user document to check existing education data
        final doc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .get();

        List<Map<String, dynamic>> educationList = [];
        
        if (doc.exists && doc.data() != null) {
          final existingEducation = doc.data()!['education'];
          
          // Handle existing education data
          if (existingEducation is List) {
            educationList = List<Map<String, dynamic>>.from(existingEducation);
          } else if (existingEducation is Map<String, dynamic>) {
            educationList = [existingEducation];
          }
        }

        if (widget.educationToEdit != null) {
          // Editing existing education - find and replace
          final editIndex = educationList.indexWhere((edu) {
            return edu['level'] == widget.educationToEdit!['level'] &&
                   edu['institution'] == widget.educationToEdit!['institution'] &&
                   edu['field'] == widget.educationToEdit!['field'];
          });
          
          if (editIndex != -1) {
            educationList[editIndex] = educationData;
          } else {
            // If not found, add as new (fallback)
            educationList.add(educationData);
          }
        } else {
          // Adding new education
          educationList.add(educationData);
        }

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
              'education': educationList,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          _showSuccessSnackBar('Education saved successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving education: $e');
      }
    }
  }

  bool _validateFields() {
    if (_levelController.text.trim().isEmpty) {
      _showErrorSnackBar('Level of education is required');
      return false;
    }
    if (_institutionController.text.trim().isEmpty) {
      _showErrorSnackBar('Institution name is required');
      return false;
    }
    if (_startDate == null) {
      _showErrorSnackBar('Start date is required');
      return false;
    }

    if (_startDate!.isAfter(DateTime.now())) {
      _showErrorSnackBar('Start date cannot be in the future');
      return false;
    }

    if (!_isCurrentEducation) {
      if (_endDate == null) {
        _showErrorSnackBar('End date is required');
        return false;
      }

      if (_endDate!.isBefore(_startDate!)) {
        _showErrorSnackBar('End date cannot be before start date');
        return false;
      }

      if (_endDate!.isAfter(DateTime.now())) {
        _showErrorSnackBar('End date cannot be in the future');
        return false;
      }
    }

    return true;
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.educationToEdit == null, // Allow free navigation for new entries
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // For new education (add mode), always allow navigation
        if (widget.educationToEdit == null) {
          Navigator.of(context).pop();
          return;
        }
        
        // For editing existing education, show modal only if there are unsaved changes
        if (_hasUnsavedChanges) {
          final shouldPop = await _showUndoModal();
          if (shouldPop == true && context.mounted) {
            Navigator.of(context).pop();
          }
        } else {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_9ELGQ7
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                // Header with back button (positioned at x: 20, y: 30 from Figma)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _handleBackNavigation,
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: widget.educationToEdit != null
                              ? const Icon(
                                  Icons.close,
                                  color: Color(0xFF3B4657),
                                  size: 24,
                                )
                              : Image.asset(
                                  'assets/images/about_me_back_icon.png',
                                  width: 24,
                                  height: 24,
                                  color: const Color(0xFF3B4657),
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.arrow_back,
                                      color: Color(0xFF3B4657),
                                      size: 24,
                                    );
                                  },
                                ),
                        ),
                      ),

                    ],
                  ),
                ),

                // Education form section - optimized for full screen
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    40,
                    20,
                    0,
                  ), // Reduced top padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title - dynamic based on edit mode
                      Text(
                        widget.educationToEdit != null ? 'Change Education' : 'Add Education',
                        style: const TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          height: 1.302,
                          color: Color(0xFF150B3D),
                        ),
                      ),

                      const SizedBox(height: 32), // Reduced spacing
                      // Level of education field - tappable selection
                      _buildEducationLevelField(),

                      const SizedBox(height: 16), // Reduced spacing
                      // Institution name field - tappable selection
                      _buildInstitutionField(),

                      const SizedBox(height: 16), // Reduced spacing
                      // Field of study field - tappable selection
                      _buildFieldOfStudyField(),

                      const SizedBox(height: 16), // Reduced spacing
                      // Date fields row - responsive layout
                      Row(
                        children: [
                          // Start date - flexible width
                          Expanded(
                            child: _buildDatePickerField(
                              label: 'Start date',
                              date: _startDate,
                              onTap: _selectStartDate,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ), // Reduced gap to prevent overflow
                          // End date - flexible width
                          Expanded(
                            child: _buildDatePickerField(
                              label: 'End date',
                              date: _endDate,
                              onTap:
                                  _isCurrentEducation ? null : _selectEndDate,
                              enabled: !_isCurrentEducation,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16), // Reduced spacing
                      // Current education checkbox
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isCurrentEducation = !_isCurrentEducation;
                                if (_isCurrentEducation) {
                                  _endDate = null;
                                }
                              });
                              _onFieldChanged();
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(5),
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
                              child:
                                  _isCurrentEducation
                                      ? const Icon(
                                        Icons.check,
                                        size: 16,
                                        color: Color(0xFF524B6B),
                                      )
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 12), // Reduced gap
                          const Text(
                            'This is my education now',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              height: 1.302,
                              color: Color(0xFF524B6B),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16), // Reduced spacing
                      // Description field - reduced height
                      _buildDescriptionField(),

                      const SizedBox(
                        height: 24,
                      ), // Optimized spacing to fit screen without scrolling
                      // Button section - conditional layout
                      widget.educationToEdit != null
                          ? _buildEditButtons()
                          : _buildSaveButton(),

                      const SizedBox(height: 20), // Bottom padding
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Button widgets
  Widget _buildSaveButton() {
    return Center(
      child: GestureDetector(
        onTap: _isSaving ? null : _showSaveConfirmation,
        child: Container(
          width: 213,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF130160),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
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
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    return Row(
      children: [
        // Remove button (positioned at x: 0, width: 160 from Figma)
        Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : _showRemoveConfirmation,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CDFE), // From Figma fill_F06L9S
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                    blurRadius: 62,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'REMOVE',
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
        const SizedBox(width: 15), // Gap between buttons
        // Save button (positioned at x: 175, width: 160 from Figma)
        Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : _showSaveConfirmation,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF130160), // From Figma fill_17N595
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
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
                          color: AppColors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Navigation handling
  Future<void> _handleBackNavigation() async {
    // For new education (add mode), never show the undo modal
    if (widget.educationToEdit == null) {
      Navigator.pop(context);
      return;
    }
    
    // For editing existing education, show modal only if there are unsaved changes
    if (_hasUnsavedChanges) {
      final shouldPop = await _showUndoModal();
      if (shouldPop == true && mounted) {
        Navigator.pop(context);
      }
    } else {
      Navigator.pop(context);
    }
  }

  // Modal implementations
  Future<bool?> _showUndoModal() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildUndoModal(),
    );
  }

  Widget _buildUndoModal() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2C373B).withValues(alpha: 0.6),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 298,
            decoration: const BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: 30,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B5858),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 55),
                const Text(
                  'Undo Changes ?',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    height: 1.302,
                    color: Color(0xFF150B3D),
                  ),
                ),
                const SizedBox(height: 16),
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
                    ),
                  ),
                ),
                const SizedBox(height: 56),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 81),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          width: 213,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF130160),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
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
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          _resetToOriginalValues();
                          setState(() {
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
                                color: AppColors.white,
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
      ],
    );
  }

  Widget _buildSaveUndoModal() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF2C373B).withValues(alpha: 0.6),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
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
                      GestureDetector(
                        onVerticalDragUpdate: (details) {
                          if (details.delta.dy > 2) {
                            Navigator.pop(context);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 25),
                          child: Center(
                            child: Container(
                              width: 30,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B5858),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const SizedBox(height: 50),
                      const Text(
                        'Undo Changes ?',
                        style: TextStyle(
                          fontFamily: 'DM Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          height: 1.302,
                          color: Color(0xFF150B3D),
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 16),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 29),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _saveEducation();
                              },
                              child: Container(
                                width: 317,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF130160),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
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
                                      color: Color(0xFFFFFFFF),
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: () {
                                _resetToOriginalValues();
                                setState(() {
                                  _hasUnsavedChanges = false;
                                });
                                Navigator.pop(context);
                              },
                              child: Container(
                                width: 317,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6CDFE),
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
                                      color: Color(0xFFFFFFFF),
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

  void _resetToOriginalValues() {
    if (widget.educationToEdit != null) {
      _populateFields();
    } else {
      _levelController.clear();
      _institutionController.clear();
      _fieldController.clear();
      _descriptionController.clear();
      _startDate = null;
      _endDate = null;
      setState(() {
        _isCurrentEducation = false;
      });
    }
  }

  // Remove functionality
  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildRemoveModal(),
    );
  }

  Widget _buildRemoveModal() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color(0xFF2C373B).withValues(alpha: 0.6),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
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
                    // Drag handle
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 25),
                      child: Center(
                        child: Container(
                          width: 30,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5B5858),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 25),
                    
                    // Title (positioned at x: 108, y: 584 from Figma)
                    const Text(
                      'Remove Education ?',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF150B3D),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description (positioned at x: 55, y: 616 from Figma)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 55),
                      child: Text(
                        'Are you sure you want to delete this education?',
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
                    
                    const SizedBox(height: 45),
                    
                    // Buttons (positioned at x: 29, y: 677 from Figma)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 29),
                      child: Column(
                        children: [
                          // Cancel button (width: 317, height: 50 from Figma)
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 317,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFF130160), // From Figma fill_2UAMPF
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                                    blurRadius: 62,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'CANCEL',
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
                          
                          // Remove button (positioned at y: 60 from button group, width: 317, height: 50)
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _removeEducation();
                            },
                            child: Container(
                              width: 317,
                              height: 50,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD6CDFE), // From Figma fill_BVXY7Z
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Center(
                                child: Text(
                                  'REMOVE',
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _removeEducation() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employee' ? 'employees' : 'users_specific';

        // Get current user document to check existing education data
        final doc = await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .get();

        if (doc.exists && doc.data() != null && widget.educationToEdit != null) {
          final existingEducation = doc.data()!['education'];
          List<Map<String, dynamic>> educationList = [];
          
          // Handle existing education data
          if (existingEducation is List) {
            educationList = List<Map<String, dynamic>>.from(existingEducation);
          } else if (existingEducation is Map<String, dynamic>) {
            educationList = [existingEducation];
          }

          // Remove the specific education entry
          educationList.removeWhere((edu) {
            return edu['level'] == widget.educationToEdit!['level'] &&
                   edu['institution'] == widget.educationToEdit!['institution'] &&
                   edu['field'] == widget.educationToEdit!['field'];
          });

          // Update with remaining education entries or delete if empty
          if (educationList.isEmpty) {
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .update({
              'education': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          } else {
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .update({
              'education': educationList,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        if (mounted) {
          _showSuccessSnackBar('Education removed successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error removing education: $e');
      }
    }
  }

  // Education level selection field
  Widget _buildEducationLevelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Level of education',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _navigateToEducationLevelSelection,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _levelController.text.isEmpty 
                          ? 'e.g., Bachelor\'s Degree, Master\'s Degree'
                          : _levelController.text,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _levelController.text.isEmpty
                            ? const Color(0xFFAAA6B9)
                            : const Color(0xFF524B6B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF524B6B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToEducationLevelSelection() async {
    final selectedLevel = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => EducationLevelSelectionScreen(
          selectedLevel: _levelController.text.isEmpty ? null : _levelController.text,
        ),
      ),
    );

    if (selectedLevel != null && mounted) {
      setState(() {
        _levelController.text = selectedLevel;
      });
      _onFieldChanged(); // Trigger unsaved changes detection
    }
  }

  // Institution selection field
  Widget _buildInstitutionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Institution name',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _navigateToInstitutionSelection,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _institutionController.text.isEmpty 
                          ? 'e.g., Harvard University'
                          : _institutionController.text,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _institutionController.text.isEmpty
                            ? const Color(0xFFAAA6B9)
                            : const Color(0xFF524B6B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF524B6B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToInstitutionSelection() async {
    final selectedInstitution = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => InstitutionSelectionScreen(
          selectedInstitution: _institutionController.text.isEmpty ? null : _institutionController.text,
        ),
      ),
    );

    if (selectedInstitution != null && mounted) {
      setState(() {
        _institutionController.text = selectedInstitution;
      });
      _onFieldChanged(); // Trigger unsaved changes detection
    }
  }

  // Field of study selection field
  Widget _buildFieldOfStudyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Field of study',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _navigateToFieldOfStudySelection,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _fieldController.text.isEmpty 
                          ? 'e.g., Computer Science'
                          : _fieldController.text,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: _fieldController.text.isEmpty
                            ? const Color(0xFFAAA6B9)
                            : const Color(0xFF524B6B),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFF524B6B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToFieldOfStudySelection() async {
    final selectedField = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => FieldOfStudySelectionScreen(
          selectedField: _fieldController.text.isEmpty ? null : _fieldController.text,
        ),
      ),
    );

    if (selectedField != null && mounted) {
      setState(() {
        _fieldController.text = selectedField;
      });
      _onFieldChanged(); // Trigger unsaved changes detection
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D), // From Figma fill_0Q2PAI
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 40, // From Figma dimensions
          decoration: BoxDecoration(
            color: AppColors.white, // From Figma fill_89PS7B
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF99ABC6,
                ).withValues(alpha: 0.18), // From Figma effect_UY03LD
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            enabled: enabled,
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFAAA6B9), // From Figma fill_X9EOAS
              ),
            ),
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color:
                  enabled ? const Color(0xFF524B6B) : const Color(0xFFAAA6B9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField({
    required String label,
    required DateTime? date,
    required VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D), // From Figma fill_0Q2PAI
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 40, // From Figma dimensions
            decoration: BoxDecoration(
              color: enabled ? AppColors.white : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                  blurRadius: 62,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      date != null ? _formatDate(date) : 'Select date',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color:
                            date != null
                                ? (enabled
                                    ? const Color(0xFF524B6B)
                                    : const Color(0xFFAAA6B9))
                                : const Color(0xFFAAA6B9),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: Image.asset(
                      'assets/images/calendar_icon_new.png',
                      width: 16,
                      height: 16,
                      color: enabled
                          ? const Color(0xFF524B6B)
                          : const Color(0xFFAAA6B9),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: enabled
                              ? const Color(0xFF524B6B)
                              : const Color(0xFFAAA6B9),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Description',
          style: TextStyle(
            fontFamily: 'DM Sans',
            fontWeight: FontWeight.w700,
            fontSize: 12,
            height: 1.302,
            color: Color(0xFF150B3D), // From Figma fill_0Q2PAI
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 140, // Increased height for better user experience
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                blurRadius: 62,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _descriptionController,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: EdgeInsets.all(20),
              hintText: 'Write additional information here',
              hintStyle: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFAAA6B9), // From Figma fill_X9EOAS
              ),
            ),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF524B6B), // From Figma fill_KQFXHD
            ),
          ),
        ),
      ],
    );
  }

  Future<bool?> _showUnsavedChangesDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text(
              'You have unsaved changes. Are you sure you want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }
}
