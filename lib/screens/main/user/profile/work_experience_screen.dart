import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_date_picker.dart';

class WorkExperienceScreen extends StatefulWidget {
  final Map<String, dynamic>? experienceToEdit;

  const WorkExperienceScreen({super.key, this.experienceToEdit});

  @override
  State<WorkExperienceScreen> createState() => _WorkExperienceScreenState();
}

class _WorkExperienceScreenState extends State<WorkExperienceScreen> {
  final TextEditingController _jobTitleController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isCurrentPosition = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    debugPrint(
      'WorkExperienceScreen initState - experienceToEdit: ${widget.experienceToEdit}',
    );

    // Add listeners first, then populate fields
    _addListeners();

    if (widget.experienceToEdit != null) {
      debugPrint('Experience data received: ${widget.experienceToEdit}');
      // Use WidgetsBinding to ensure the widget is fully built before populating
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _populateFields();
      });
    } else {
      debugPrint('No experience data - showing add mode');
    }
  }

  @override
  void dispose() {
    _removeListeners();
    _jobTitleController.dispose();
    _companyController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addListeners() {
    _jobTitleController.addListener(_onFieldChanged);
    _companyController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _removeListeners() {
    _jobTitleController.removeListener(_onFieldChanged);
    _companyController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    // For new work experience (add mode), never set unsaved changes
    if (widget.experienceToEdit == null) {
      return;
    }

    final currentData = {
      'jobTitle': _jobTitleController.text.trim(),
      'company': _companyController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startDate': _startDate?.toIso8601String() ?? '',
      'endDate': _endDate?.toIso8601String() ?? '',
      'isCurrentPosition': _isCurrentPosition.toString(),
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
    if (widget.experienceToEdit != null) {
      final exp = widget.experienceToEdit!;
      debugPrint('Populating fields with data: $exp');

      // Populate controllers first
      _jobTitleController.text = exp['position'] ?? exp['jobTitle'] ?? '';
      _companyController.text = exp['company'] ?? '';
      _descriptionController.text = exp['description'] ?? '';

      debugPrint('After setting controllers:');
      debugPrint('Job title controller: ${_jobTitleController.text}');
      debugPrint('Company controller: ${_companyController.text}');
      debugPrint('Description controller: ${_descriptionController.text}');

      // Then update state variables and trigger rebuild
      setState(() {
        _isCurrentPosition =
            exp['isCurrentJob'] ?? exp['isCurrentPosition'] ?? false;

        // Safe date parsing with fallbacks
        if (exp['startDate'] != null) {
          _startDate = _parseDate(exp['startDate']);
        } else {
          _startDate = null;
        }

        if (exp['endDate'] != null && !_isCurrentPosition) {
          _endDate = _parseDate(exp['endDate']);
        } else {
          _endDate = null;
        }
      });

      debugPrint('After setState:');
      debugPrint('Is current position: $_isCurrentPosition');
      debugPrint('Start date parsed: $_startDate');
      debugPrint('End date parsed: $_endDate');

      _originalData = {
        'jobTitle': _jobTitleController.text.trim(),
        'company': _companyController.text.trim(),
        'description': _descriptionController.text.trim(),
        'startDate': _startDate?.toIso8601String() ?? '',
        'endDate': _endDate?.toIso8601String() ?? '',
        'isCurrentPosition': _isCurrentPosition.toString(),
      };

      debugPrint('Original data set: $_originalData');

      // Force a rebuild to ensure UI updates
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _resetToOriginalValues() {
    if (widget.experienceToEdit != null) {
      final exp = widget.experienceToEdit!;
      setState(() {
        _jobTitleController.text = exp['position'] ?? exp['jobTitle'] ?? '';
        _companyController.text = exp['company'] ?? '';
        _descriptionController.text = exp['description'] ?? '';
        _isCurrentPosition =
            exp['isCurrentJob'] ?? exp['isCurrentPosition'] ?? false;

        // Reset dates
        if (exp['startDate'] != null) {
          _startDate = _parseDate(exp['startDate']);
        } else {
          _startDate = null;
        }

        if (exp['endDate'] != null && !_isCurrentPosition) {
          _endDate = _parseDate(exp['endDate']);
        } else {
          _endDate = null;
        }
      });
    } else {
      // For new experience, clear all fields
      setState(() {
        _jobTitleController.clear();
        _companyController.clear();
        _descriptionController.clear();
        _startDate = null;
        _endDate = null;
        _isCurrentPosition = false;
      });
    }
  }

  DateTime? _parseDate(dynamic dateValue) {
    try {
      if (dateValue is String) {
        // Try different date formats
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

        // Try yyyy-MM format
        final dashParts = dateValue.split('-');
        if (dashParts.length >= 2) {
          final year = int.tryParse(dashParts[0]);
          final month = int.tryParse(dashParts[1]);
          if (year != null && month != null && month >= 1 && month <= 12) {
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
        // If start date is after end date, clear end date
        if (_endDate != null && picked.isAfter(_endDate!)) {
          _endDate = null;
        }
      });
      _onFieldChanged();
    }
  }

  Future<void> _selectEndDate() async {
    if (_isCurrentPosition) return;

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
    if (_hasUnsavedChanges) {
      _showSaveUndoModal();
    } else {
      // No changes, save directly
      _saveWorkExperience();
    }
  }

  Future<void> _showSaveUndoModal() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildSaveUndoModal(),
    );
  }

  Future<void> _saveWorkExperience() async {
    if (!_validateFields()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        final experienceData = {
          'position': _jobTitleController.text.trim(),
          'company': _companyController.text.trim(),
          'startDate': _startDate?.toIso8601String() ?? '',
          'endDate':
              _isCurrentPosition ? '' : (_endDate?.toIso8601String() ?? ''),
          'description': _descriptionController.text.trim(),
          'isCurrentJob': _isCurrentPosition,
        };

        // Get current user document to check existing work experience data
        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        List<Map<String, dynamic>> experienceList = [];

        if (doc.exists && doc.data() != null) {
          final existingExperience = doc.data()!['workExperience'];

          // Handle existing work experience data
          if (existingExperience is List) {
            experienceList = List<Map<String, dynamic>>.from(
              existingExperience,
            );
          } else if (existingExperience is Map<String, dynamic>) {
            experienceList = [existingExperience];
          }
        }

        if (widget.experienceToEdit != null) {
          // Editing existing experience - find and replace
          final editIndex = experienceList.indexWhere((exp) {
            return exp['position'] == widget.experienceToEdit!['position'] &&
                exp['company'] == widget.experienceToEdit!['company'];
          });

          if (editIndex != -1) {
            experienceList[editIndex] = experienceData;
          } else {
            // If not found, add as new (fallback)
            experienceList.add(experienceData);
          }
        } else {
          // Adding new work experience
          experienceList.add(experienceData);
        }

        await FirebaseFirestore.instance
            .collection(collectionName)
            .doc(user.uid)
            .update({
              'workExperience': experienceList,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          _showSuccessSnackBar('Work experience saved successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving work experience: $e');
      }
    }
  }

  bool _validateFields() {
    if (_jobTitleController.text.trim().isEmpty) {
      _showErrorSnackBar('Job title is required');
      return false;
    }
    if (_companyController.text.trim().isEmpty) {
      _showErrorSnackBar('Company is required');
      return false;
    }
    if (_startDate == null) {
      _showErrorSnackBar('Start date is required');
      return false;
    }

    // Validate start date is not in the future
    if (_startDate!.isAfter(DateTime.now())) {
      _showErrorSnackBar('Start date cannot be in the future');
      return false;
    }

    if (!_isCurrentPosition) {
      if (_endDate == null) {
        _showErrorSnackBar('End date is required');
        return false;
      }

      // Validate end date is not before start date
      if (_endDate!.isBefore(_startDate!)) {
        _showErrorSnackBar('End date cannot be before start date');
        return false;
      }

      // Validate end date is not in the future
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
      canPop:
          widget.experienceToEdit ==
          null, // Allow free navigation for new entries
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // For new work experience (add mode), always allow navigation
        if (widget.experienceToEdit == null) {
          Navigator.of(context).pop();
          return;
        }

        // For editing existing work experience, check for unsaved changes
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

                    // Work experience form
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            // Title
                            Text(
                              widget.experienceToEdit != null
                                  ? 'Change work experience'
                                  : 'Add work experience',
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                height: 1.302,
                                color: AppColors.lookGigProfileText,
                              ),
                            ),

                            const SizedBox(height: 52),

                            // Job title field
                            _buildInputField(
                              controller: _jobTitleController,
                              label: 'Job title',
                              hintText: 'Enter job title',
                            ),

                            const SizedBox(height: 20),

                            // Company field
                            _buildInputField(
                              controller: _companyController,
                              label: 'Company',
                              hintText: 'Enter company name',
                            ),

                            const SizedBox(height: 20),

                            // Date fields row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDatePickerField(
                                    label: 'Start date',
                                    date: _startDate,
                                    onTap: _selectStartDate,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: _buildDatePickerField(
                                    label: 'End date',
                                    date: _endDate,
                                    onTap:
                                        _isCurrentPosition
                                            ? null
                                            : _selectEndDate,
                                    enabled: !_isCurrentPosition,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Current position checkbox
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isCurrentPosition = !_isCurrentPosition;
                                      if (_isCurrentPosition) {
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
                                      border: Border.all(
                                        color:
                                            _isCurrentPosition
                                                ? AppColors.lookGigPurple
                                                : const Color(0xFF524B6B),
                                        width: 1.5,
                                      ),
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
                                        _isCurrentPosition
                                            ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppColors.lookGigPurple,
                                            )
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 23),
                                const Text(
                                  'This is my position now',
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

                            const SizedBox(height: 20),

                            // Description field
                            _buildDescriptionField(),

                            const Spacer(),

                            // Buttons
                            if (widget.experienceToEdit != null) ...[
                              // Edit mode: Remove and Save buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _showDeleteConfirmation(),
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFD6CDFE),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap:
                                          _isSaving
                                              ? null
                                              : _showSaveConfirmation,
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: AppColors.lookGigPurple,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                                      fontWeight:
                                                          FontWeight.w700,
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
                              ),
                            ] else ...[
                              // Add mode: Single Save button
                              Center(
                                child: GestureDetector(
                                  onTap:
                                      _isSaving ? null : _showSaveConfirmation,
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
                            ],

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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    double? width,
    bool enabled = true,
  }) {
    return SizedBox(
      width: width ?? 335,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.302,
              color: AppColors.lookGigProfileText,
            ),
          ),
          const SizedBox(height: 10),
          Container(
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
                  color: Color(0xFFAAA6B9),
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
      ),
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
            color: AppColors.lookGigProfileText,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 40,
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
                      color:
                          enabled
                              ? const Color(0xFF524B6B)
                              : const Color(0xFFAAA6B9),
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.calendar_today,
                          size: 16,
                          color:
                              enabled
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
            color: AppColors.lookGigProfileText,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 335,
          height: 155,
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
              contentPadding: EdgeInsets.all(20),
              hintText: 'Write additional information here',
              hintStyle: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFAAA6B9),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF524B6B),
            ),
          ),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    // For new work experience (add mode), never show the undo modal
    if (widget.experienceToEdit == null) {
      return true;
    }

    // For editing existing work experience, show modal only if there are unsaved changes
    if (_hasUnsavedChanges) {
      final result = await _showUndoModal();
      return result ?? false;
    }
    return true;
  }

  Future<bool?> _showUndoModal() async {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildUndoModal(),
    );
  }

  Widget _buildUndoModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 30,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.lookGigProfileText,
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
              color: AppColors.lookGigProfileText,
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
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    if (widget.experienceToEdit != null) {
                      _populateFields();
                    } else {
                      _jobTitleController.clear();
                      _companyController.clear();
                      _descriptionController.clear();
                      _startDate = null;
                      _endDate = null;
                      setState(() {
                        _isCurrentPosition = false;
                      });
                    }
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
          SizedBox(
            height: 72 + bottomPadding,
          ), // Custom nav bar + system padding
        ],
      ),
    );
  }

  void _showDeleteConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => _buildDeleteModal(),
    );
  }

  Widget _buildDeleteModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white, // From Figma fill_TRW696
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20), // Add bottom padding
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
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF5B5858,
                      ), // From Figma stroke_6L2HZG
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Title (positioned at x: 80, y: 589 from Figma)
            const Text(
              'Remove Work Experience ?',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 20, // Made slightly bigger for better visibility
                height: 1.302,
                color: Color(0xFF150B3D), // From Figma fill_79EHDY
                decoration: TextDecoration.none,
              ),
            ),

            const SizedBox(height: 16),

            // Subtitle (positioned at x: 36, y: 621 from Figma)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 37),
              child: Text(
                'Are you sure you want to delete this work experience?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.302,
                  color: Color(0xFF524B6B), // From Figma fill_0JGF6G
                  decoration: TextDecoration.none,
                ),
              ),
            ),

            const SizedBox(height: 56),

            // Buttons (positioned at x: 21, y: 677 from Figma)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: [
                  // Continue Filling button (Cancel deletion)
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close modal without deleting
                    },
                    child: Container(
                      width: 317, // From Figma dimensions
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFF130160,
                        ), // From Figma fill_66BY4O
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
                            letterSpacing: 0.84, // 6% letter spacing from Figma
                            color: Color(0xFFFFFFFF), // From Figma fill_TRW696
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Remove button (Actually delete)
                  GestureDetector(
                    onTap: () {
                      _deleteWorkExperience(); // Actually delete the experience
                    },
                    child: Container(
                      width: 317, // From Figma dimensions
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(
                          0xFFD6CDFE,
                        ), // From Figma fill_PYBHAO
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
                            letterSpacing: 0.84, // 6% letter spacing from Figma
                            color: Color(0xFFFFFFFF), // From Figma fill_TRW696
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 72 + bottomPadding,
            ), // Custom nav bar + system padding
          ],
        ),
      ),
    );
  }

  Future<void> _deleteWorkExperience() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName =
            role == 'employer' ? 'employers' : 'users_specific';

        // Get current user document to check existing work experience data
        final doc =
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .get();

        if (doc.exists &&
            doc.data() != null &&
            widget.experienceToEdit != null) {
          final existingExperience = doc.data()!['workExperience'];
          List<Map<String, dynamic>> experienceList = [];

          // Handle existing work experience data
          if (existingExperience is List) {
            experienceList = List<Map<String, dynamic>>.from(
              existingExperience,
            );
          } else if (existingExperience is Map<String, dynamic>) {
            experienceList = [existingExperience];
          }

          // Remove the specific work experience entry
          experienceList.removeWhere((exp) {
            return exp['position'] == widget.experienceToEdit!['position'] &&
                exp['company'] == widget.experienceToEdit!['company'];
          });

          // Update with remaining experience entries or delete if empty
          if (experienceList.isEmpty) {
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .update({
                  'workExperience': FieldValue.delete(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          } else {
            await FirebaseFirestore.instance
                .collection(collectionName)
                .doc(user.uid)
                .update({
                  'workExperience': experienceList,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
          }
        }

        if (mounted) {
          Navigator.pop(context); // Close delete modal
          Navigator.pop(context, true); // Go back to profile
          _showSuccessSnackBar('Work experience deleted successfully!');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close delete modal
        _showErrorSnackBar('Error deleting work experience: $e');
      }
    }
  }

  Widget _buildSaveUndoModal() {
    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
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
                padding: const EdgeInsets.symmetric(vertical: 25),
                child: Center(
                  child: Container(
                    width: 30,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF5B5858,
                      ), // From Figma stroke_C4NVQI
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const SizedBox(height: 50),

            // Title
            const Text(
              'Save Changes?',
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

            // Subtitle
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 44),
              child: Text(
                'Do you want to save the changes you made?',
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

            // Buttons (positioned at x: 21, y: 677 from Figma)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 29),
              child: Column(
                children: [
                  // Save button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close modal
                      _saveWorkExperience(); // Save the data
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
                          'SAVE',
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

                  // Cancel button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Just close modal, don't save
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
                          'CANCEL',
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
            const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
