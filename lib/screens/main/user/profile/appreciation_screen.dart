import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_work_app/services/auth_services.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:get_work_app/widgets/custom_date_picker.dart';

class AppreciationScreen extends StatefulWidget {
  final Map<String, dynamic>? appreciationToEdit;

  const AppreciationScreen({super.key, this.appreciationToEdit});

  @override
  State<AppreciationScreen> createState() => _AppreciationScreenState();
}

class _AppreciationScreenState extends State<AppreciationScreen> {
  final TextEditingController _awardNameController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  Map<String, dynamic> _originalData = {};

  @override
  void initState() {
    super.initState();
    if (widget.appreciationToEdit != null) {
      _populateFields();
    }
    _addListeners();
  }

  @override
  void dispose() {
    _removeListeners();
    _awardNameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final appreciation = widget.appreciationToEdit!;
    _awardNameController.text = appreciation['title'] ?? '';
    _categoryController.text = appreciation['organization'] ?? '';
    _descriptionController.text = appreciation['description'] ?? '';
    
    // Parse dates
    if (appreciation['startDate'] != null) {
      _startDate = _parseDate(appreciation['startDate']);
    }
    if (appreciation['endDate'] != null) {
      _endDate = _parseDate(appreciation['endDate']);
    }

    _originalData = Map<String, dynamic>.from(appreciation);
  }

  DateTime? _parseDate(dynamic dateValue) {
    try {
      if (dateValue is String && dateValue.isNotEmpty) {
        return DateTime.tryParse(dateValue);
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

  void _addListeners() {
    _awardNameController.addListener(_checkForChanges);
    _categoryController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }

  void _removeListeners() {
    _awardNameController.removeListener(_checkForChanges);
    _categoryController.removeListener(_checkForChanges);
    _descriptionController.removeListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = widget.appreciationToEdit != null
        ? (_awardNameController.text != (_originalData['title'] ?? '') ||
           _categoryController.text != (_originalData['organization'] ?? '') ||
           _descriptionController.text != (_originalData['description'] ?? '') ||
           _startDate != _parseDate(_originalData['startDate']) ||
           _endDate != _parseDate(_originalData['endDate']))
        : (_awardNameController.text.isNotEmpty ||
           _categoryController.text.isNotEmpty ||
           _descriptionController.text.isNotEmpty ||
           _startDate != null ||
           _endDate != null);

    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }

  Future<void> _saveAppreciation() async {
    if (!_validateInputs()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employer' ? 'employers' : 'users_specific';

        final appreciationData = {
          'title': _awardNameController.text.trim(),
          'organization': _categoryController.text.trim(),
          'description': _descriptionController.text.trim(),
          'startDate': _startDate?.toIso8601String() ?? '',
          'endDate': _endDate?.toIso8601String() ?? '',
        };

        // Get current user document
        final docRef = FirebaseFirestore.instance.collection(collectionName).doc(user.uid);
        final doc = await docRef.get();
        
        List<Map<String, dynamic>> appreciations = [];
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['appreciations'] is List) {
            appreciations = List<Map<String, dynamic>>.from(data['appreciations']);
          }
        }

        if (widget.appreciationToEdit != null) {
          // Update existing appreciation
          final index = appreciations.indexWhere((app) => 
            app['title'] == _originalData['title'] &&
            app['organization'] == _originalData['organization'] &&
            app['startDate'] == _originalData['startDate']
          );
          if (index != -1) {
            appreciations[index] = appreciationData;
          }
        } else {
          // Add new appreciation
          appreciations.add(appreciationData);
        }

        await docRef.update({
          'appreciations': appreciations,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          _showSuccessSnackBar(widget.appreciationToEdit != null 
              ? 'Appreciation updated successfully!' 
              : 'Appreciation added successfully!');
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error saving appreciation: $e');
      }
    }
  }

  bool _validateInputs() {
    if (_awardNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Award name is required');
      return false;
    }
    if (_categoryController.text.trim().isEmpty) {
      _showErrorSnackBar('Category/Achievement is required');
      return false;
    }
    if (_startDate == null) {
      _showErrorSnackBar('Start date is required');
      return false;
    }
    if (_endDate == null) {
      _showErrorSnackBar('End date is required');
      return false;
    }
    if (_startDate!.isAfter(_endDate!)) {
      _showErrorSnackBar('Start date must be before end date');
      return false;
    }
    return true;
  }

  void _showRemoveConfirmation() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildRemoveConfirmationModal(),
    );
  }

  Widget _buildRemoveConfirmationModal() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // Top divider line
          Padding(
            padding: const EdgeInsets.only(top: 25),
            child: Container(
              width: 30,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF130160),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 25),
          
          // Title
          const Text(
            'Remove Appreciation ?',
            style: TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.302,
              color: Color(0xFF150B3D),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Description
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 63),
            child: Text(
              'Are you sure you want to remove this award?',
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
          
          const SizedBox(height: 48),
          
          // Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 29),
            child: Column(
              children: [
                // Continue Filling button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 317,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF130160),
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
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Undo Changes button
                GestureDetector(
                  onTap: () => _removeAppreciation(),
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
                          color: AppColors.white,
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
    );
  }

  Future<void> _removeAppreciation() async {
    Navigator.pop(context); // Close modal first
    
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await AuthService.getUserRole();
        final collectionName = role == 'employer' ? 'employers' : 'users_specific';

        final docRef = FirebaseFirestore.instance.collection(collectionName).doc(user.uid);
        final doc = await docRef.get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          List<Map<String, dynamic>> appreciations = [];
          if (data['appreciations'] is List) {
            appreciations = List<Map<String, dynamic>>.from(data['appreciations']);
          }

          // Remove the appreciation
          appreciations.removeWhere((app) => 
            app['title'] == _originalData['title'] &&
            app['organization'] == _originalData['organization'] &&
            app['startDate'] == _originalData['startDate']
          );

          await docRef.update({
            'appreciations': appreciations,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          if (mounted) {
            _showSuccessSnackBar('Appreciation removed successfully!');
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Error removing appreciation: $e');
      }
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
      _checkForChanges();
    }
  }

  Future<void> _selectEndDate() async {
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
      _checkForChanges();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_VHBSXZ
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

            // Content area (positioned at x: 20, y: 94 from Figma)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width.clamp(0, 375),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title (positioned at x: 0, y: 0 from Figma)
                        Text(
                          widget.appreciationToEdit != null ? 'Edit Appreciation' : 'Add Appreciation',
                          style: const TextStyle(
                            fontFamily: 'DM Sans',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            height: 1.302,
                            color: Color(0xFF150A33), // From Figma fill_H7HVAU
                          ),
                        ),

                        const SizedBox(height: 52),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Award name field (positioned at x: 0, y: 52 from Figma)
                                _buildInputField(
                                  label: 'Award name',
                                  controller: _awardNameController,
                                  height: 66,
                                ),

                                const SizedBox(height: 20),

                                // Category field (positioned at x: 0, y: 138 from Figma)
                                _buildInputField(
                                  label: 'Category/Achievement achieved',
                                  controller: _categoryController,
                                  height: 66,
                                ),

                                const SizedBox(height: 20),

                                // Date fields row
                                Row(
                                  children: [
                                    // Start date field
                                    Expanded(
                                      child: _buildDateField(
                                        label: 'Start date',
                                        date: _startDate,
                                        onTap: _selectStartDate,
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    // End date field
                                    Expanded(
                                      child: _buildDateField(
                                        label: 'End date',
                                        date: _endDate,
                                        onTap: _selectEndDate,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Description field (positioned at x: 0, y: 310 from Figma)
                                _buildInputField(
                                  label: 'Description',
                                  controller: _descriptionController,
                                  height: 181,
                                  isMultiline: true,
                                  placeholder: 'Write additional information here',
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

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 50),
              child: widget.appreciationToEdit != null
                  ? _buildEditModeButtons()
                  : _buildAddModeButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    double? width,
    double height = 66,
    bool isMultiline = false,
    String? placeholder,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF150A33), // From Figma fill_H7HVAU
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Input field
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white, // From Figma fill_NG1RWS
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF99ABC6).withOpacity(0.18),
                    blurRadius: 62,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                maxLines: isMultiline ? null : 1,
                expands: isMultiline,
                textAlignVertical: isMultiline ? TextAlignVertical.top : TextAlignVertical.center,
                decoration: InputDecoration(
                  hintText: placeholder,
                  hintStyle: const TextStyle(
                    fontFamily: 'DM Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.302,
                    color: Color(0xFFAAA6B9), // From Figma fill_QYBBI0
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isMultiline ? 20 : 12,
                  ),
                ),
                style: const TextStyle(
                  fontFamily: 'DM Sans',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  height: 1.302,
                  color: Color(0xFF524B6B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    double? width,
  }) {
    return SizedBox(
      height: 66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'DM Sans',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.302,
              color: Color(0xFF150A33),
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Date field
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF99ABC6).withOpacity(0.18),
                      blurRadius: 62,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
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
                          height: 1.302,
                          color: date != null 
                              ? const Color(0xFF524B6B)
                              : const Color(0xFFAAA6B9),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Color(0xFF524B6B),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddModeButton() {
    return Center(
      child: GestureDetector(
        onTap: _isSaving ? null : _saveAppreciation,
        child: Container(
          width: MediaQuery.of(context).size.width.clamp(213, 335),
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFF130160), // From Figma fill_QXYSVH
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
                      color: AppColors.white, // From Figma fill_NG1RWS
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditModeButtons() {
    return Row(
      children: [
        // Remove button (positioned at x: 0, y: 0 from Figma)
        Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : _showRemoveConfirmation,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFD6CDFE), // From Figma fill_BRO68C
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
                    color: AppColors.white, // From Figma fill_OX50L4
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 15),
        
        // Save button (positioned at x: 175, y: 0 from Figma)
        Expanded(
          child: GestureDetector(
            onTap: _isSaving ? null : _saveAppreciation,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF130160), // From Figma fill_4S06QI
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
                          color: AppColors.white, // From Figma fill_OX50L4
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