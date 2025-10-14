import 'package:flutter/material.dart';

class FieldOfStudySelectionScreen extends StatefulWidget {
  final String? selectedField;

  const FieldOfStudySelectionScreen({
    super.key,
    this.selectedField,
  });

  @override
  State<FieldOfStudySelectionScreen> createState() => _FieldOfStudySelectionScreenState();
}

class _FieldOfStudySelectionScreenState extends State<FieldOfStudySelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredFields = [];
  
  // Fields of study from Figma + additional common fields
  final List<String> _fieldsOfStudy = [
    // From Figma design
    'Information Technology',
    'Business Information Systems',
    'Computer Information Science',
    'Computer Information Systems',
    'Health Information Management',
    'History and Information',
    'Information Assurance',
    'Information Security',
    'Information Systems',
    'Information Systems Major',
    
    // Additional common fields of study
    'Computer Science',
    'Software Engineering',
    'Data Science',
    'Artificial Intelligence',
    'Machine Learning',
    'Cybersecurity',
    'Network Security',
    'Web Development',
    'Mobile App Development',
    'Database Management',
    'Business Administration',
    'Marketing',
    'Finance',
    'Accounting',
    'Economics',
    'Management',
    'Human Resources',
    'International Business',
    'Entrepreneurship',
    'Engineering',
    'Mechanical Engineering',
    'Electrical Engineering',
    'Civil Engineering',
    'Chemical Engineering',
    'Biomedical Engineering',
    'Aerospace Engineering',
    'Environmental Engineering',
    'Medicine',
    'Nursing',
    'Pharmacy',
    'Dentistry',
    'Psychology',
    'Biology',
    'Chemistry',
    'Physics',
    'Mathematics',
    'Statistics',
    'English Literature',
    'History',
    'Philosophy',
    'Political Science',
    'Sociology',
    'Anthropology',
    'Communications',
    'Journalism',
    'Media Studies',
    'Graphic Design',
    'Fine Arts',
    'Music',
    'Theater Arts',
    'Architecture',
    'Interior Design',
    'Fashion Design',
    'Education',
    'Elementary Education',
    'Secondary Education',
    'Special Education',
    'Law',
    'Criminal Justice',
    'Social Work',
    'Public Administration',
    'International Relations',
    'Environmental Science',
    'Geography',
    'Geology',
    'Agriculture',
    'Veterinary Medicine',
    'Sports Science',
    'Nutrition',
    'Hospitality Management',
    'Tourism Management',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _filteredFields = List.from(_fieldsOfStudy);
    if (widget.selectedField != null) {
      _searchController.text = widget.selectedField!;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterFields();
    setState(() {}); // Trigger rebuild for clear icon visibility
  }

  void _filterFields() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFields = _fieldsOfStudy
          .where((field) => field.toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectField(String field) {
    Navigator.pop(context, field);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredFields = List.from(_fieldsOfStudy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_AJZKRB
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
                        color: const Color(0xFF524B6B), // From Figma stroke_MU89YJ
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

            // Content section (positioned at x: 20, y: 94 from Figma)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 64, 20, 0), // 94 - 30 = 64
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title (positioned at x: 0, y: 0 from Figma)
                    const Text(
                      'Field of study',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF150B3D), // From Figma fill_667XBN
                      ),
                    ),

                    const SizedBox(height: 52), // Gap to search box

                    // Search box (positioned at x: 0, y: 52 from Figma)
                    Container(
                      width: 335, // From Figma dimensions
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF), // From Figma fill_M0LEHT
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
                            blurRadius: 62,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Search icon (positioned at x: 15, y: 8 from Figma)
                          Padding(
                            padding: const EdgeInsets.only(left: 15),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: Image.asset(
                                'assets/images/search_icon.png',
                                width: 24,
                                height: 24,
                                color: const Color(0xFFAAA6B9), // From Figma stroke_Q9CAF5
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.search,
                                    size: 24,
                                    color: Color(0xFFAAA6B9),
                                  );
                                },
                              ),
                            ),
                          ),

                          // Divider line (positioned at x: 118, y: 13 from Figma)
                          Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            width: 1,
                            height: 14,
                            color: const Color(0xFF7551FF), // From Figma stroke_WKAS6Z
                          ),

                          // Text input (positioned at x: 49, y: 12 from Figma)
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                disabledBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                hintText: 'Search field of study...',
                                hintStyle: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xFFAAA6B9),
                                ),
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                              style: const TextStyle(
                                fontFamily: 'DM Sans',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Color(0xFF150A33), // From Figma fill_L6WF5I
                              ),
                            ),
                          ),

                          // Remove/Clear icon (positioned at x: 301, y: 8 from Figma)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    key: const ValueKey('clear_icon'),
                                    onTap: _clearSearch,
                                    child: const Padding(
                                      padding: EdgeInsets.only(right: 15),
                                      child: Icon(
                                        Icons.close,
                                        size: 24,
                                        color: Color(0xFF150A33), // From Figma stroke_IMMU1N
                                      ),
                                    ),
                                  )
                                : const SizedBox(
                                    key: ValueKey('empty'),
                                    width: 15,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40), // Gap to fields list

                    // Fields of study list (positioned at x: 0, y: 132 from Figma)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredFields.length,
                        itemBuilder: (context, index) {
                          final field = _filteredFields[index];
                          final isSelected = field == widget.selectedField;
                          
                          return GestureDetector(
                            onTap: () => _selectField(field),
                            child: Container(
                              width: 294, // From Figma dimensions
                              margin: const EdgeInsets.only(bottom: 30), // Gap between items
                              child: Text(
                                field,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: isSelected 
                                      ? const Color(0xFF7551FF) // Highlight selected
                                      : const Color(0xFF524B6B), // From Figma fill_8E5TH4
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}