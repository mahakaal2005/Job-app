import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/utils/app_colors.dart';

class EditJobScreen extends StatefulWidget {
  final Job job;

  const EditJobScreen({Key? key, required this.job}) : super(key: key);

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryRangeController = TextEditingController();
  final _requirementController = TextEditingController();
  final _benefitController = TextEditingController();
  final _skillController = TextEditingController();
  final _responsibilityController = TextEditingController();

  String _selectedEmploymentType = 'Full-time';
  String _selectedExperienceLevel = 'Entry Level';
  List<String> _requirements = [];
  List<String> _benefits = [];
  List<String> _requiredSkills = [];
  List<String> _responsibilities = [];
  bool _isLoading = false;

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Freelance',
    'Internship',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Mid Level',
    'Senior Level',
    'Executive Level',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    _titleController.text = widget.job.title;
    _descriptionController.text = widget.job.description;
    _locationController.text = widget.job.location;
    _salaryRangeController.text = widget.job.salaryRange;
    _selectedEmploymentType = widget.job.employmentType;
    _selectedExperienceLevel = widget.job.experienceLevel;
    _requirements = List<String>.from(widget.job.requirements);
    _benefits = List<String>.from(widget.job.benefits);
    _requiredSkills = List<String>.from(widget.job.requiredSkills);
    _responsibilities = List<String>.from(widget.job.responsibilities);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryRangeController.dispose();
    _requirementController.dispose();
    _benefitController.dispose();
    _skillController.dispose();
    _responsibilityController.dispose();
    super.dispose();
  }

  void _addRequirement() {
    if (_requirementController.text.trim().isNotEmpty) {
      setState(() {
        _requirements.add(_requirementController.text.trim());
        _requirementController.clear();
      });
    }
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  void _addBenefit() {
    if (_benefitController.text.trim().isNotEmpty) {
      setState(() {
        _benefits.add(_benefitController.text.trim());
        _benefitController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefits.removeAt(index);
    });
  }

  void _addSkill() {
    if (_skillController.text.trim().isNotEmpty) {
      setState(() {
        _requiredSkills.add(_skillController.text.trim());
        _skillController.clear();
      });
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _requiredSkills.removeAt(index);
    });
  }

  void _addResponsibility() {
    if (_responsibilityController.text.trim().isNotEmpty) {
      setState(() {
        _responsibilities.add(_responsibilityController.text.trim());
        _responsibilityController.clear();
      });
    }
  }

  void _removeResponsibility(int index) {
    setState(() {
      _responsibilities.removeAt(index);
    });
  }

  Future<void> _updateJob() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedJob = widget.job.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        salaryRange: _salaryRangeController.text.trim(),
        requirements: _requirements,
        benefits: _benefits,
        requiredSkills: _requiredSkills,
        responsibilities: _responsibilities,
        updatedAt: DateTime.now(),
      );

      await JobService.updateJob(updatedJob);
      
      Navigator.pop(context, updatedJob);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update job: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Job',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.whiteText),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _updateJob,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: AppColors.whiteText,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Basic Information',
                [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Job Title',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Please enter job title' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Job Description',
                    maxLines: 4,
                    validator: (value) =>
                        value?.isEmpty == true ? 'Please enter job description' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Please enter location' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Employment Type',
                    value: _selectedEmploymentType,
                    items: _employmentTypes,
                    onChanged: (value) => setState(() => _selectedEmploymentType = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    label: 'Experience Level',
                    value: _selectedExperienceLevel,
                    items: _experienceLevels,
                    onChanged: (value) => setState(() => _selectedExperienceLevel = value!),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _salaryRangeController,
                    label: 'Salary Range (Optional)',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildListSection(
                'Requirements',
                _requirements,
                _requirementController,
                'Add requirement',
                _addRequirement,
                _removeRequirement,
              ),
              const SizedBox(height: 24),
              _buildListSection(
                'Required Skills',
                _requiredSkills,
                _skillController,
                'Add skill',
                _addSkill,
                _removeSkill,
              ),
              const SizedBox(height: 24),
              _buildListSection(
                'Responsibilities',
                _responsibilities,
                _responsibilityController,
                'Add responsibility',
                _addResponsibility,
                _removeResponsibility,
              ),
              const SizedBox(height: 24),
              _buildListSection(
                'Benefits',
                _benefits,
                _benefitController,
                'Add benefit',
                _addBenefit,
                _removeBenefit,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: AppColors.primaryText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.secondaryText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surfaceColor,
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.dividerColor),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            style: TextStyle(color: AppColors.primaryText),
            dropdownColor: AppColors.cardBackground,
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection(
    String title,
    List<String> items,
    TextEditingController controller,
    String hintText,
    VoidCallback onAdd,
    Function(int) onRemove,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: AppColors.secondaryText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(16),
                ),
                child: const Icon(Icons.add, color: AppColors.whiteText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isNotEmpty)
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onRemove(index),
                      icon: Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}