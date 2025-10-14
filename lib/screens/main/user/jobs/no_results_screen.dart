import 'package:flutter/material.dart';

class NoResultsScreen extends StatefulWidget {
  final String searchQuery;
  final VoidCallback? onBack;

  const NoResultsScreen({
    super.key,
    required this.searchQuery,
    this.onBack,
  });

  @override
  State<NoResultsScreen> createState() => _NoResultsScreenState();
}

class _NoResultsScreenState extends State<NoResultsScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.searchQuery.isNotEmpty ? widget.searchQuery : '',
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    // Navigate back to FilteredJobsScreen with new search query
    // We'll pop back and let the FilteredJobsScreen handle the search
    Navigator.pop(context, query.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Padding(
              padding: const EdgeInsets.only(
                top: 30,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: Column(
                children: [
                  // Back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (widget.onBack != null) {
                            widget.onBack!();
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: const Icon(
                          Icons.arrow_back,
                          size: 24,
                          color: Color(0xFF524B6B),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Search bar
                  Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () {
                            _performSearch(_searchController.text);
                          },
                          child: const Icon(
                            Icons.search,
                            color: Color(0xFFAAA6B9),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF524B6B),
                              fontFamily: 'Open Sans',
                              height: 1.362,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: widget.searchQuery.isEmpty ? 'Search jobs...' : null,
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFFAAA6B9),
                                fontFamily: 'Open Sans',
                                height: 1.362,
                              ),
                            ),
                            onFieldSubmitted: (value) {
                              _performSearch(value);
                            },
                            onChanged: (value) {
                              // Optional: Could implement real-time search here
                              // For now, we'll wait for user to press Enter or submit
                            },
                            textInputAction: TextInputAction.search,
                          ),
                        ),
                        const SizedBox(width: 15), // Right padding
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Body content - centered
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Illustration
                    Image.asset(
                      'assets/images/no_results_illustration.png',
                      width: 156.32,
                      height: 176.82,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 156.32,
                          height: 176.82,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 60),
                    
                    // Text content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        children: [
                          // Title
                          const Text(
                            'No results found',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF150B3D),
                              fontFamily: 'Open Sans',
                              height: 1.362,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Description
                          const Text(
                            'The search could not be found, please check spelling or write another word.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF524B6B),
                              fontFamily: 'Open Sans',
                              height: 1.362,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
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