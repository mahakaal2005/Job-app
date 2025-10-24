import 'package:flutter/material.dart';
import 'package:get_work_app/utils/app_colors.dart';

class SkillSearchScreen extends StatefulWidget {
  final List<String> selectedSkills;
  final List<String> originalSkills;

  const SkillSearchScreen({
    super.key,
    required this.selectedSkills,
    this.originalSkills = const [],
  });

  @override
  State<SkillSearchScreen> createState() => _SkillSearchScreenState();
}

class _SkillSearchScreenState extends State<SkillSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredSkills = [];
  List<String> _selectedSkills = [];

  // Comprehensive list of skills based on Figma design and common skills
  final List<String> _allSkills = [
    'Graphic Design',
    'Graphic Thinking', 
    'UI/UX Design',
    'Adobe InDesign',
    'Web Design',
    'InDesign',
    'Canva Design',
    'User Interface Design',
    'Product Design',
    'User Experience Design',
    'Leadership',
    'Teamwork',
    'Target oriented',
    'Responsibility',
    'Good communication skills',
    'Consistent',
    'English',
    'Visioner',
    'Adobe Photoshop',
    'Adobe Illustrator',
    'Figma',
    'Sketch',
    'Prototyping',
    'Wireframing',
    'User Research',
    'Usability Testing',
    'Information Architecture',
    'Interaction Design',
    'Visual Design',
    'Brand Design',
    'Logo Design',
    'Print Design',
    'Digital Marketing',
    'Social Media Marketing',
    'Content Creation',
    'Copywriting',
    'SEO',
    'Analytics',
    'Project Management',
    'Agile',
    'Scrum',
    'Time Management',
    'Problem Solving',
    'Critical Thinking',
    'Creativity',
    'Innovation',
    'Adaptability',
    'Collaboration',
    'Communication',
    'Presentation Skills',
    'Public Speaking',
    'Negotiation',
    'Customer Service',
    'Sales',
    'Business Development',
    'Strategic Planning',
    'Data Analysis',
    'Research',
    'Microsoft Office',
    'Excel',
    'PowerPoint',
    'Google Workspace',
    'Slack',
    'Trello',
    'Asana',
    'Notion',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkills = List.from(widget.selectedSkills);
    // Start with empty search - show all skills
    _filterSkills('');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSkills(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredSkills = List.from(_allSkills);
      } else {
        _filteredSkills = _allSkills
            .where((skill) => skill.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _filterSkills('');
  }

  void _applySelection() {
    Navigator.pop(context, _selectedSkills);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_3QOY7J
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button (positioned at x: 20, y: 30 from Figma)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, _selectedSkills),
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
                        color: Color(0xFF150B3D), // From Figma fill_NX740F
                      ),
                    ),

                    const SizedBox(height: 52),

                    // Search bar with current search (positioned at x: 0, y: 52 from Figma)
                    Container(
                      width: double.infinity,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.white, // From Figma fill_872M80
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF130160), // Blue border
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Search icon (positioned at x: 15, y: 8 from Figma)
                          const Padding(
                            padding: EdgeInsets.only(left: 15),
                            child: Icon(
                              Icons.search,
                              size: 24,
                              color: Color(0xFFAAA6B9),
                            ),
                          ),
                          
                          // Search input (positioned at x: 49, y: 12 from Figma)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 10, right: 10),
                              child: TextField(
                                controller: _searchController,
                                onChanged: _filterSkills,
                                style: const TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: Color(0xFF150A33), // From Figma fill_CCO26X
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  errorBorder: InputBorder.none,
                                  disabledBorder: InputBorder.none,
                                  hintText: 'Search skills',
                                  hintStyle: TextStyle(
                                    fontFamily: 'DM Sans',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 12,
                                    height: 1.302,
                                    color: Color(0xFFAAA6B9),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ),
                          
                          // Clear/Remove button (positioned at x: 301, y: 8 from Figma)
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: _clearSearch,
                              child: const Padding(
                                padding: EdgeInsets.only(right: 10),
                                child: Icon(
                                  Icons.close,
                                  size: 24,
                                  color: Color(0xFFA8A8A8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Skills list (positioned at x: 0, y: 132 from Figma)
                    Expanded(
                      child: _buildSkillsList(),
                    ),
                  ],
                ),
              ),
            ),

            // Apply button (if skills are selected)
            if (_selectedSkills.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(81, 0, 81, 50),
                child: GestureDetector(
                  onTap: _applySelection,
                  child: Container(
                    width: 213,
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
                        'APPLY',
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
        ),
      ),
    );
  }

  Widget _buildSkillsList() {
    if (_filteredSkills.isEmpty) {
      return const Center(
        child: Text(
          'No skills found.\nTry a different search term.',
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
      itemCount: _filteredSkills.length,
      itemBuilder: (context, index) {
        final skill = _filteredSkills[index];
        final isSelected = _selectedSkills.contains(skill);
        final isNewSkill = isSelected && !widget.originalSkills.contains(skill);

        return Padding(
          padding: const EdgeInsets.only(bottom: 30), // 46px spacing from Figma
          child: GestureDetector(
            onTap: () => _toggleSkill(skill),
            child: SizedBox(
              width: 131, // From Figma layout_U6KIXB
              child: Row(
                children: [
                  // Skill name
                  Expanded(
                    child: Text(
                      skill,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        height: 1.302,
                        color: isNewSkill
                            ? const Color(0xFFFF9228) // Orange for new skills
                            : isSelected 
                                ? const Color(0xFF130160) // Purple for existing selected
                                : const Color(0xFF524B6B), // Gray for unselected
                      ),
                    ),
                  ),
                  
                  // Selection indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: isNewSkill 
                          ? const Color(0xFFFF9228) // Orange for new skills
                          : const Color(0xFF130160), // Purple for existing
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