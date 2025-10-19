import 'package:flutter/material.dart';
import 'package:get_work_app/widgets/custom_checkbox.dart';
import 'package:get_work_app/widgets/custom_range_slider_thumb.dart';

class JobFilterScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onApplyFilters;
  final Map<String, dynamic>? initialFilters;

  const JobFilterScreen({
    super.key, 
    this.onApplyFilters,
    this.initialFilters,
  });

  @override
  State<JobFilterScreen> createState() => _JobFilterScreenState();
}

class _JobFilterScreenState extends State<JobFilterScreen> {
  // Filter state variables - default to empty/unselected state
  String _selectedLastUpdate = '';
  String _selectedWorkplace = '';
  String _selectedJobType = '';
  String _selectedPositionLevel = '';
  List<String> _selectedCities = [];
  double _minSalary = 10;
  double _maxSalary = 200;
  String _selectedExperience = '';
  List<String> _selectedSpecializations = [];

  // Dropdown state variables (expanded by default)
  bool _isLastUpdateExpanded = true;
  bool _isWorkplaceExpanded = true;
  bool _isJobTypeExpanded = true;
  bool _isPositionLevelExpanded = true;
  bool _isCityExpanded = true;
  bool _isSalaryExpanded = true;
  bool _isExperienceExpanded = true;
  bool _isSpecializationExpanded = true;

  // Options
  final List<String> _lastUpdateOptions = [
    'Recent',
    'Last week',
    'Last month',
    'Any time',
  ];
  final List<String> _workplaceOptions = ['On-site', 'Remote', 'Hybrid'];
  final List<String> _jobTypeOptions = [
    'Full time',
    'Part-time',
    'Apprenticeship',
    'Contarct',
    'Project-based',
  ];
  final List<String> _positionLevelOptions = [
    'Junior',
    'Senior',
    'Leader',
    'Manager',
  ];
  final List<String> _cityOptions = [
    'California, USA',
    'Texaz, USA',
    'New York, USA',
    'Florida, USA',
  ];
  final List<String> _experienceOptions = [
    'No experience',
    'Less than a year',
    '1-3 years',
    '3-5 years',
    '5-10 years',
    'More than 10 years',
  ];
  final List<String> _specializationOptions = [
    'Design',
    'Programmer',
    'Finance',
    'Education',
    'Health',
    'Restuarant',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    if (widget.initialFilters != null) {
      final filters = widget.initialFilters!;
      setState(() {
        _selectedLastUpdate = filters['lastUpdate'] ?? '';
        _selectedWorkplace = filters['workplace'] ?? '';
        _selectedJobType = filters['jobType'] ?? '';
        _selectedPositionLevel = filters['positionLevel'] ?? '';
        _selectedCities = List<String>.from(filters['cities'] ?? []);
        _minSalary = (filters['minSalary'] ?? 10).toDouble();
        _maxSalary = (filters['maxSalary'] ?? 200).toDouble();
        _selectedExperience = filters['experience'] ?? '';
        _selectedSpecializations = List<String>.from(filters['specializations'] ?? []);
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedLastUpdate = '';
      _selectedWorkplace = '';
      _selectedJobType = '';
      _selectedPositionLevel = '';
      _selectedCities = [];
      _minSalary = 10;
      _maxSalary = 200;
      _selectedExperience = '';
      _selectedSpecializations = [];
    });
    
    // Show minimal toast message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filters reset'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
      ),
    );
  }

  void _applyFilters() {
    final filters = {
      'lastUpdate': _selectedLastUpdate,
      'workplace': _selectedWorkplace,
      'jobType': _selectedJobType,
      'positionLevel': _selectedPositionLevel,
      'cities': _selectedCities,
      'minSalary': _minSalary,
      'maxSalary': _maxSalary,
      'experience': _selectedExperience,
      'specializations': _selectedSpecializations,
    };

    // Navigate back first, then apply filters
    Navigator.pop(context, filters);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('JobFilterScreen build called');
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(
        children: [
          // Header
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(
                top: 30,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back,
                      size: 24,
                      color: Color(0xFF524B6B),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Filter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF000000),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24), // Balance the back button
                ],
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLastUpdateSection(),
                  const SizedBox(height: 20),
                  _buildWorkplaceSection(),
                  const SizedBox(height: 20),
                  _buildJobTypeSection(),
                  const SizedBox(height: 20),
                  _buildPositionLevelSection(),
                  const SizedBox(height: 20),
                  _buildCitySection(),
                  const SizedBox(height: 20),
                  _buildSalarySection(),
                  const SizedBox(height: 20),
                  _buildExperienceSection(),
                  const SizedBox(height: 20),
                  _buildSpecializationSection(),
                ],
              ),
            ),
          ),

          // Bottom bar
          Container(
            height: 78,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFACC8D3).withValues(alpha: 0.2),
                  blurRadius: 83,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Reset button
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Container(
                      width: 75,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFFACC8D3,
                            ).withValues(alpha: 0.4),
                            blurRadius: 72,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFFF9228),
                            fontFamily: 'Open Sans',
                            height: 1.362,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  // Apply Now button
                  Expanded(
                    child: GestureDetector(
                      onTap: _applyFilters,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF130160),
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
                            'APPLY NOW',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              fontFamily: 'DM Sans',
                              letterSpacing: 0.9,
                              height: 1.302,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastUpdateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isLastUpdateExpanded = !_isLastUpdateExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Last update',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isLastUpdateExpanded ? 0 : 3.14159, // 180 degrees when collapsed
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isLastUpdateExpanded) ...[
          const SizedBox(height: 38),
          ..._lastUpdateOptions.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildRadioOption(
                option,
                _selectedLastUpdate == option,
                () => setState(() => _selectedLastUpdate = option),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildWorkplaceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isWorkplaceExpanded = !_isWorkplaceExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Type of workplace',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isWorkplaceExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isWorkplaceExpanded) ...[
          const SizedBox(height: 38),
          ..._workplaceOptions.map(
            (option) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildRadioOption(
                option,
                _selectedWorkplace == option,
                () => setState(() => _selectedWorkplace = option),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildJobTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isJobTypeExpanded = !_isJobTypeExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Job type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isJobTypeExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isJobTypeExpanded) ...[
          const SizedBox(height: 31),
          Wrap(
          spacing: 15,
          runSpacing: 15,
          children:
              _jobTypeOptions.map((option) {
                final isSelected = _selectedJobType == option;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedJobType = option;
                    });
                  },
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFFCA34D)
                              : const Color(0xFFCBC9D4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color:
                            isSelected ? Colors.white : const Color(0xFF524B6B),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                  ),
                );
              }).toList(),
          ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildPositionLevelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isPositionLevelExpanded = !_isPositionLevelExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Position level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isPositionLevelExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isPositionLevelExpanded) ...[
          const SizedBox(height: 31),
        Wrap(
          spacing: 15,
          runSpacing: 15,
          children:
              _positionLevelOptions.map((option) {
                final isSelected = _selectedPositionLevel == option;
                return GestureDetector(
                  onTap: () => setState(() => _selectedPositionLevel = option),
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? const Color(0xFFFCA34D)
                              : const Color(0xFFCBC9D4).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color:
                            isSelected ? Colors.white : const Color(0xFF524B6B),
                        fontFamily: 'DM Sans',
                        height: 1.302,
                      ),
                    ),
                  ),
                );
              }).toList(),
          ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildCitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isCityExpanded = !_isCityExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'City',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isCityExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isCityExpanded) ...[
          const SizedBox(height: 38),
        ..._cityOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildCheckboxOption(
              option,
              _selectedCities.contains(option),
              () {
                setState(() {
                  if (_selectedCities.contains(option)) {
                    _selectedCities.remove(option);
                  } else {
                    _selectedCities.add(option);
                  }
                });
              },
            ),
          ),
        ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildSalarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isSalaryExpanded = !_isSalaryExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Salary',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isSalaryExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isSalaryExpanded) ...[
          const SizedBox(height: 40),
          // Functional RangeSlider
          SizedBox(
            width: 335,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFFFF9228), // Orange track between handles
                inactiveTrackColor: const Color(0xFFCCC4C2), // Gray track outside handles
                thumbColor: Colors.white,
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 25,
                ),
                trackHeight: 4, // Slightly thicker for better visibility
                rangeThumbShape: const CustomRangeSliderThumbShape(
                  thumbRadius: 12, // Slightly smaller for better proportion
                  thumbColor: Colors.white,
                  borderColor: Colors.black, // Dark black border
                  borderWidth: 4, // Thick black border
                ),
                rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                activeTickMarkColor: Colors.transparent,
                inactiveTickMarkColor: Colors.transparent,
              ),
              child: RangeSlider(
                values: RangeValues(_minSalary, _maxSalary),
                min: 10,
                max: 200,
                divisions: 38, // (200-10)/5 = 38 divisions for 5k increments
                onChanged: (RangeValues values) {
                  setState(() {
                    _minSalary = values.start;
                    _maxSalary = values.end;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Salary range labels
          SizedBox(
            width: 335,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${_minSalary.round()}k',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF150B3D),
                    fontFamily: 'DM Sans',
                    height: 1.302,
                  ),
                ),
                Text(
                  '\$${_maxSalary.round()}k',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF150B3D),
                    fontFamily: 'DM Sans',
                    height: 1.302,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildExperienceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExperienceExpanded = !_isExperienceExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Experience',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isExperienceExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isExperienceExpanded) ...[
          const SizedBox(height: 38),
        ..._experienceOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildRadioOption(
              option,
              _selectedExperience == option,
              () => setState(() => _selectedExperience = option),
            ),
          ),
        ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildSpecializationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _isSpecializationExpanded = !_isSpecializationExpanded),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Specialization',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF150B3D),
                  fontFamily: 'DM Sans',
                  height: 1.302,
                ),
              ),
              Transform.rotate(
                angle: _isSpecializationExpanded ? 0 : 3.14159,
                child: Image.asset(
                  'assets/images/dropdown_icon.png',
                  width: 10,
                  height: 10,
                  color: const Color(0xFF150B3D),
                ),
              ),
            ],
          ),
        ),
        if (_isSpecializationExpanded) ...[
          const SizedBox(height: 38),
        ..._specializationOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: _buildCheckboxOption(
              option,
              _selectedSpecializations.contains(option),
              () {
                setState(() {
                  if (_selectedSpecializations.contains(option)) {
                    _selectedSpecializations.remove(option);
                  } else {
                    _selectedSpecializations.add(option);
                  }
                });
              },
            ),
          ),
        ),
        ],
        const SizedBox(height: 20),
        Container(width: 335, height: 0.5, color: const Color(0xFFDEE1E7)),
      ],
    );
  }

  Widget _buildRadioOption(String text, bool isSelected, VoidCallback onTap) {
    debugPrint('JobFilterScreen: Building radio button for "$text", selected: $isSelected');
    return GestureDetector(
      onTap: () {
        debugPrint('JobFilterScreen: Radio button "$text" tapped');
        onTap();
      },
      child: Row(
        children: [
          CustomRadioButton(
            isSelected: isSelected,
            onTap: onTap,
          ),
          const SizedBox(width: 15),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF524B6B),
              fontFamily: 'DM Sans',
              height: 1.302,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxOption(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    debugPrint('JobFilterScreen: Building checkbox for "$text", selected: $isSelected');
    return GestureDetector(
      onTap: () {
        debugPrint('JobFilterScreen: Checkbox "$text" tapped');
        onTap();
      },
      child: Row(
        children: [
          CustomCheckbox(
            isSelected: isSelected,
            onTap: onTap,
          ),
          const SizedBox(width: 15),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFF524B6B),
              fontFamily: 'DM Sans',
              height: 1.302,
            ),
          ),
        ],
      ),
    );
  }
}
