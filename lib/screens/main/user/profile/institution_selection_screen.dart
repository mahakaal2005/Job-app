import 'package:flutter/material.dart';

class InstitutionSelectionScreen extends StatefulWidget {
  final String? selectedInstitution;

  const InstitutionSelectionScreen({
    super.key,
    this.selectedInstitution,
  });

  @override
  State<InstitutionSelectionScreen> createState() => _InstitutionSelectionScreenState();
}

class _InstitutionSelectionScreenState extends State<InstitutionSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredInstitutions = [];
  
  // Institutions from Figma + additional common institutions
  final List<String> _institutions = [
    // From Figma design
    'University of Oxford',
    'National University of Lesotho International School',
    'University of Chester CE Academy',
    'University of Chester Academy Northwich',
    'University of Birmingham School',
    'Bloomsburg University of Pennsylvania',
    'California University of Pennsylvania',
    'Clarion University of Pennsylvania',
    'East Stroudsburg State University of Pennsylvania',
    
    // Additional common institutions
    'Harvard University',
    'Stanford University',
    'Massachusetts Institute of Technology (MIT)',
    'University of Cambridge',
    'California Institute of Technology (Caltech)',
    'University of Chicago',
    'Princeton University',
    'Yale University',
    'Columbia University',
    'University of Pennsylvania',
    'Duke University',
    'Northwestern University',
    'Johns Hopkins University',
    'University of California, Berkeley',
    'University of California, Los Angeles (UCLA)',
    'University of Michigan',
    'New York University (NYU)',
    'University of Toronto',
    'University of British Columbia',
    'McGill University',
    'University of Melbourne',
    'University of Sydney',
    'Australian National University',
    'University of Tokyo',
    'Kyoto University',
    'National University of Singapore',
    'Nanyang Technological University',
    'University of Hong Kong',
    'Peking University',
    'Tsinghua University',
    'Indian Institute of Technology (IIT)',
    'Indian Institute of Science',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _filteredInstitutions = List.from(_institutions);
    if (widget.selectedInstitution != null) {
      _searchController.text = widget.selectedInstitution!;
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterInstitutions();
    setState(() {}); // Trigger rebuild for clear icon visibility
  }

  void _filterInstitutions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredInstitutions = _institutions
          .where((institution) => institution.toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectInstitution(String institution) {
    Navigator.pop(context, institution);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _filteredInstitutions = List.from(_institutions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9), // From Figma fill_K9ZG1F
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
                        color: const Color(0xFF524B6B), // From Figma stroke_XXUKHG
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
                      'Institution name',
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.302,
                        color: Color(0xFF150B3D), // From Figma fill_R2E3Y4
                      ),
                    ),

                    const SizedBox(height: 52), // Gap to search box

                    // Search box (positioned at x: 0, y: 52 from Figma)
                    Container(
                      width: 335, // From Figma dimensions
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF), // From Figma fill_NJV3JP
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
                                color: const Color(0xFFAAA6B9), // From Figma stroke_1D7VO7
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

                          // Divider line (positioned at x: 122, y: 13 from Figma)
                          Container(
                            margin: const EdgeInsets.only(left: 10, right: 10),
                            width: 1,
                            height: 14,
                            color: const Color(0xFF7551FF), // From Figma stroke_X58OKV
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
                                hintText: 'Search institution...',
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
                                color: Color(0xFF150A33), // From Figma fill_KYDDLO
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
                                        color: Color(0xFF150A33), // From Figma stroke_E4MY81
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

                    const SizedBox(height: 40), // Gap to institution list

                    // Institutions list (positioned at x: 0, y: 132 from Figma)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _filteredInstitutions.length,
                        itemBuilder: (context, index) {
                          final institution = _filteredInstitutions[index];
                          final isSelected = institution == widget.selectedInstitution;
                          
                          return GestureDetector(
                            onTap: () => _selectInstitution(institution),
                            child: Container(
                              width: 294, // From Figma dimensions
                              margin: const EdgeInsets.only(bottom: 30), // Gap between items
                              child: Text(
                                institution,
                                style: TextStyle(
                                  fontFamily: 'DM Sans',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  height: 1.302,
                                  color: isSelected 
                                      ? const Color(0xFF7551FF) // Highlight selected
                                      : const Color(0xFF524B6B), // From Figma fill_UGABZK
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