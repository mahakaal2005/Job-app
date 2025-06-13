import 'package:flutter/material.dart';
import 'package:get_work_app/provider/emp_job_provider.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/user/student_ob_screen/skills_list.dart';
import 'package:get_work_app/utils/app_colors.dart';
import 'package:provider/provider.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({Key? key}) : super(key: key);

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _responsibilityController = TextEditingController();
  final _requirementController = TextEditingController();
  final _skillSearchController = TextEditingController();
  final _benefitsController = TextEditingController();

  String _selectedEmploymentType = 'Full-time';
  String _selectedExperienceLevel = 'Entry Level';
  List<String> _selectedSkills = [];
  List<String> _responsibilities = [];
  List<String> _requirements = [];
  List<String> _benefits = [];
  List<String> _filteredSkills = [];
  bool _isLoading = false;
  bool _showSkillSuggestions = false;
  String _selectedWorkFrom = 'On-site';

  final List<String> _employmentTypes = [
    'Full-time',
    'Part-time',
    'Contract',
    'Internship',
  ];

  final List<String> _experienceLevels = [
    'Entry Level',
    'Mid Level',
    'Senior Level',
    'Executive Level',
  ];

  final List<String> _workFromOptions = ['On-site', 'Remote'];

  @override
  void initState() {
    super.initState();
    _filteredSkills = List.from(allSkills);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _responsibilityController.dispose();
    _requirementController.dispose();
    _skillSearchController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = List.from(allSkills);
        _showSkillSuggestions = false;
      } else {
        _filteredSkills =
            allSkills
                .where(
                  (skill) =>
                      skill.toLowerCase().contains(query.toLowerCase()) &&
                      !_selectedSkills.contains(skill),
                )
                .toList();
        _showSkillSuggestions = _filteredSkills.isNotEmpty;
      }
    });
  }

  void _addSkill(String skill) {
    if (!_selectedSkills.contains(skill)) {
      setState(() {
        _selectedSkills.add(skill);
        _skillSearchController.clear();
        _showSkillSuggestions = false;
        _filteredSkills.clear();
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _selectedSkills.remove(skill);
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

  void _addRequirement() {
    if (_requirementController.text.trim().isNotEmpty) {
      setState(() {
        _requirements.add(_requirementController.text.trim());
        _requirementController.clear();
      });
    }
  }

  void _removeResponsibility(int index) {
    setState(() {
      _responsibilities.removeAt(index);
    });
  }

  void _removeRequirement(int index) {
    setState(() {
      _requirements.removeAt(index);
    });
  }

  void _addBenefit() {
    if (_benefitsController.text.trim().isNotEmpty) {
      setState(() {
        _benefits.add(_benefitsController.text.trim());
        _benefitsController.clear();
      });
    }
  }

  void _removeBenefit(int index) {
    setState(() {
      _benefits.removeAt(index);
    });
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSkills.isEmpty) {
      _showSnackBar('Please select at least one skill', isError: true);
      return;
    }

    if (_responsibilities.isEmpty) {
      _showSnackBar('Please add at least one responsibility', isError: true);
      return;
    }

    if (_requirements.isEmpty) {
      _showSnackBar('Please add at least one requirement', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final job = Job(
        id: '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        employmentType: _selectedEmploymentType,
        experienceLevel: _selectedExperienceLevel,
        salaryRange: _salaryController.text.trim(),
        requiredSkills: _selectedSkills,
        responsibilities: _responsibilities,
        requirements: _requirements,
        companyName: '',
        companyLogo: '',
        employerId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        benefits: _benefits,
        applicantsCount: 0,
        isActive: true,
        viewCount: 0,
        workFrom: _selectedWorkFrom,
      );

      await Provider.of<JobProvider>(context, listen: false).addJob(job);
      _showSnackBar('Job created successfully!');
      Navigator.pop(context, true);
    } catch (e) {
      _showSnackBar('Failed to create job: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text(
          'Create New Job',
          style: TextStyle(
            color: AppColors.whiteText,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.whiteText),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () {
          // Hide skill suggestions when tapping outside
          setState(() {
            _showSkillSuggestions = false;
          });
          FocusScope.of(context).unfocus();
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildInputField(
                'Job Title *',
                _titleController,
                'Enter job title',
                Icons.work,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                'Job Description *',
                _descriptionController,
                'Describe the job role',
                Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 20),
              _buildBenefitsSection(),
              const SizedBox(height: 20),
              _buildInputField(
                'Location *',
                _locationController,
                'Enter job location',
                Icons.location_on,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                'Employment Type *',
                _selectedEmploymentType,
                _employmentTypes,
                (value) => setState(() => _selectedEmploymentType = value!),
                Icons.work_outline,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                'Work From',
                _selectedWorkFrom,
                _workFromOptions,
                (value) => setState(() => _selectedWorkFrom = value!),
                Icons.work_outlined,
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                'Experience Level *',
                _selectedExperienceLevel,
                _experienceLevels,
                (value) => setState(() => _selectedExperienceLevel = value!),
                Icons.trending_up,
              ),
              const SizedBox(height: 20),
              _buildInputField(
                'Salary Range *',
                _salaryController,
                'e.g., ₹50,000 - ₹80,000',
                Icons.currency_rupee,
              ),
              const SizedBox(height: 20),
              _buildSearchableSkillsSection(),
              const SizedBox(height: 20),
              _buildListSection(
                'Responsibilities *',
                _responsibilities,
                _responsibilityController,
                _addResponsibility,
                _removeResponsibility,
                'Add responsibility',
              ),
              const SizedBox(height: 20),
              _buildListSection(
                'Requirements *',
                _requirements,
                _requirementController,
                _addRequirement,
                _removeRequirement,
                'Add requirement',
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _createJob,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.whiteText,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.whiteText,
                          ),
                        )
                        : const Text(
                          'Create Job',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableSkillsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Required Skills *',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Search Input Field
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _skillSearchController,
            style: TextStyle(color: AppColors.primaryText),
            onChanged: _filterSkills,
            onTap: () {
              if (_skillSearchController.text.isNotEmpty) {
                _filterSkills(_skillSearchController.text);
              }
            },
            decoration: InputDecoration(
              hintText: 'Search and add skills...',
              hintStyle: TextStyle(color: AppColors.hintText),
              prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue),
              suffixIcon:
                  _skillSearchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.grey),
                        onPressed: () {
                          _skillSearchController.clear();
                          setState(() {
                            _showSkillSuggestions = false;
                            _filteredSkills.clear();
                          });
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        // Skill Suggestions Dropdown
        if (_showSkillSuggestions && _filteredSkills.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  _filteredSkills.length > 5 ? 5 : _filteredSkills.length,
              itemBuilder: (context, index) {
                final skill = _filteredSkills[index];
                return ListTile(
                  dense: true,
                  title: Text(
                    skill,
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 14,
                    ),
                  ),
                  leading: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                  onTap: () => _addSkill(skill),
                  hoverColor: AppColors.primaryBlue.withOpacity(0.1),
                );
              },
            ),
          ),

        // Selected Skills Display
        if (_selectedSkills.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Selected Skills (${_selectedSkills.length})',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _selectedSkills.map((skill) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          skill,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => _removeSkill(skill),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Benefits *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _benefitsController,
                decoration: InputDecoration(
                  hintText: 'Add job benefits',
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onFieldSubmitted: (_) => _addBenefit(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addBenefit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Icon(Icons.add, color: AppColors.whiteText),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_benefits.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _benefits.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(_benefits[index]),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline,
                      color: AppColors.error,
                    ),
                    onPressed: () => _removeBenefit(index),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: AppColors.primaryText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.hintText),
              prefixIcon: Icon(icon, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            style: TextStyle(color: AppColors.primaryText),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryBlue),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppColors.cardBackground,
              contentPadding: const EdgeInsets.all(16),
            ),
            dropdownColor: AppColors.cardBackground,
            items:
                items.map((item) {
                  return DropdownMenuItem(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(color: AppColors.primaryText),
                    ),
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
    VoidCallback onAdd,
    void Function(int) onRemove,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: controller,
                  style: TextStyle(color: AppColors.primaryText),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(color: AppColors.hintText),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.cardBackground,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add, color: AppColors.whiteText),
              ),
            ),
          ],
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.dividerColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
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
      ],
    );
  }
}
