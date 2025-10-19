import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_work_app/screens/main/employer/new post/job_new_model.dart';
import 'package:get_work_app/screens/main/user/jobs/bookmark_provider.dart';
import 'package:get_work_app/screens/main/user/jobs/job_detail_screen_new.dart';
import 'package:get_work_app/screens/main/user/jobs/job_filter_screen.dart';
import 'package:get_work_app/screens/main/user/jobs/user_all_jobs_services.dart';
import 'package:get_work_app/screens/main/user/jobs/no_results_screen.dart';
import 'package:get_work_app/utils/salary_utils.dart';
import 'package:get_work_app/utils/image_utils.dart';

class FilteredJobsScreen extends StatefulWidget {
  final String filterType; // 'Remote', 'Full-time', 'Part-time'
  final String title; // Display title
  final VoidCallback? onBack; // Optional callback for back navigation
  final Map<String, dynamic>? additionalFilters; // Additional filters from filter screen

  const FilteredJobsScreen({
    super.key,
    required this.filterType,
    required this.title,
    this.onBack,
    this.additionalFilters,
  });

  @override
  State<FilteredJobsScreen> createState() => _FilteredJobsScreenState();
}

class _FilteredJobsScreenState extends State<FilteredJobsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  List<Job> _jobs = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  Map<String, dynamic> _currentFilters = {};
  
  // Search and filter state
  String _searchQuery = '';
  String _locationQuery = '';
  final List<String> _selectedChips = [];

  @override
  void initState() {
    super.initState();
    _currentFilters = widget.additionalFilters ?? {};
    // Leave controllers empty so placeholders show
    _searchController.text = '';
    _locationController.text = '';
    _searchQuery = '';
    _locationQuery = '';
    _loadFilteredJobs();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String _getSearchQueryFromFilters() {
    List<String> queryParts = [];
    
    // Add search query
    if (_searchQuery.isNotEmpty && _searchQuery.toLowerCase() != 'design') {
      queryParts.add(_searchQuery);
    }
    
    // Add location query
    if (_locationQuery.isNotEmpty && _locationQuery.toLowerCase() != 'california, usa') {
      queryParts.add(_locationQuery);
    }
    
    // Add selected chips
    if (_selectedChips.isNotEmpty) {
      queryParts.addAll(_selectedChips);
    }
    
    // Add basic filter type
    if (widget.filterType.isNotEmpty && widget.filterType != 'All') {
      queryParts.add(widget.filterType);
    }
    
    // Add job type filter
    if (_currentFilters['jobType'] != null && _currentFilters['jobType'].isNotEmpty) {
      queryParts.add(_currentFilters['jobType']);
    }
    
    // Add workplace filter
    if (_currentFilters['workplace'] != null && _currentFilters['workplace'].isNotEmpty) {
      queryParts.add(_currentFilters['workplace']);
    }
    
    // Add position level
    if (_currentFilters['positionLevel'] != null && _currentFilters['positionLevel'].isNotEmpty) {
      queryParts.add(_currentFilters['positionLevel']);
    }
    
    // Add specializations
    if (_currentFilters['specializations'] != null && (_currentFilters['specializations'] as List).isNotEmpty) {
      List<String> specs = List<String>.from(_currentFilters['specializations']);
      queryParts.addAll(specs);
    }
    
    // Add salary range if specified
    if (_currentFilters['minSalary'] != null && _currentFilters['maxSalary'] != null) {
      double minSalary = _currentFilters['minSalary'].toDouble();
      double maxSalary = _currentFilters['maxSalary'].toDouble();
      queryParts.add('\$${minSalary.round()}k-\$${maxSalary.round()}k');
    }
    
    return queryParts.isNotEmpty ? queryParts.join(' ') : 'Jobs';
  }

  Future<void> _loadFilteredJobs() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Use the same service as home screen to fetch all jobs
      final allJobs = await AllJobsService.getAllJobs(
        limit: 100, // Fetch more to ensure we have enough after filtering
        lastDocument: null,
      );

      // Apply all filters
      List<Job> filteredJobs = allJobs.where((job) {
        // Apply search query filter
        if (_searchQuery.isNotEmpty) {
          String searchLower = _searchQuery.toLowerCase().trim();
          debugPrint('Filtering with search query: "$searchLower"');
          
          // Split search query into words for better matching
          List<String> searchWords = searchLower.split(' ').where((word) => word.isNotEmpty).toList();
          
          bool matchesSearch = false;
          
          // Check if all search words match somewhere in the job
          if (searchWords.isNotEmpty) {
            matchesSearch = searchWords.every((word) {
              return job.title.toLowerCase().contains(word) ||
                  job.description.toLowerCase().contains(word) ||
                  job.companyName.toLowerCase().contains(word) ||
                  job.location.toLowerCase().contains(word) ||
                  job.experienceLevel.toLowerCase().contains(word) ||
                  job.employmentType.toLowerCase().contains(word) ||
                  job.salaryRange.toLowerCase().contains(word) ||
                  (job.workFrom != null && job.workFrom!.toLowerCase().contains(word)) ||
                  job.requiredSkills.any((skill) => skill.toLowerCase().contains(word));
            });
          }
          
          if (!matchesSearch) {
            debugPrint('Job "${job.title}" does not match search query');
            return false;
          }
        }

        // Apply location query filter
        if (_locationQuery.isNotEmpty) {
          bool matchesLocation = job.location.toLowerCase().contains(_locationQuery.toLowerCase());
          if (!matchesLocation) return false;
        }

        // Apply selected chips filter
        if (_selectedChips.isNotEmpty) {
          bool matchesChips = false;
          for (String chip in _selectedChips) {
            if (chip.toLowerCase() == 'senior designer' && 
                (job.title.toLowerCase().contains('senior') && job.title.toLowerCase().contains('design'))) {
              matchesChips = true;
              break;
            } else if (chip.toLowerCase() == 'designer' && 
                       job.title.toLowerCase().contains('design')) {
              matchesChips = true;
              break;
            } else if (chip.toLowerCase() == 'full-time' && 
                       (job.employmentType.toLowerCase() == 'full-time' || job.employmentType.toLowerCase() == 'full time')) {
              matchesChips = true;
              break;
            }
          }
          if (!matchesChips) return false;
        }

        // Apply basic filter type (Remote, Full-time, Part-time)
        bool matchesBasicFilter = true;
        if (widget.filterType == 'Remote') {
          matchesBasicFilter = job.workFrom != null &&
              job.workFrom!.toLowerCase() == 'remote';
        } else if (widget.filterType == 'Full-time') {
          matchesBasicFilter = job.employmentType.toLowerCase() == 'full-time' ||
              job.employmentType.toLowerCase() == 'full time';
        } else if (widget.filterType == 'Part-time') {
          matchesBasicFilter = job.employmentType.toLowerCase() == 'part-time' ||
              job.employmentType.toLowerCase() == 'part time';
        }

        if (!matchesBasicFilter) return false;

        // Apply additional filters if they exist
        if (_currentFilters.isNotEmpty) {
          // Workplace filter
          if (_currentFilters['workplace'] != null && _currentFilters['workplace'].isNotEmpty) {
            String workplace = _currentFilters['workplace'].toLowerCase();
            if (workplace == 'remote') {
              if (job.workFrom == null || job.workFrom!.toLowerCase() != 'remote') {
                return false;
              }
            } else if (workplace == 'hybrid') {
              if (job.workFrom == null || job.workFrom!.toLowerCase() != 'hybrid') {
                return false;
              }
            } else if (workplace == 'on-site') {
              if (job.workFrom != null && job.workFrom!.toLowerCase() != 'on-site' && job.workFrom!.toLowerCase() != '') {
                return false;
              }
            }
          }

          // Job type filter
          if (_currentFilters['jobType'] != null && _currentFilters['jobType'].isNotEmpty) {
            String filterJobType = _currentFilters['jobType'].toLowerCase();
            String jobType = job.employmentType.toLowerCase();
            if (!jobType.contains(filterJobType.replaceAll('-', ' '))) {
              return false;
            }
          }

          // Position level filter
          if (_currentFilters['positionLevel'] != null && _currentFilters['positionLevel'].isNotEmpty) {
            String filterLevel = _currentFilters['positionLevel'].toLowerCase();
            String jobLevel = job.experienceLevel.toLowerCase();
            if (!jobLevel.contains(filterLevel)) {
              return false;
            }
          }

          // City filter
          if (_currentFilters['cities'] != null && (_currentFilters['cities'] as List).isNotEmpty) {
            List<String> selectedCities = List<String>.from(_currentFilters['cities']);
            bool matchesCity = false;
            for (String city in selectedCities) {
              if (job.location.toLowerCase().contains(city.toLowerCase())) {
                matchesCity = true;
                break;
              }
            }
            if (!matchesCity) return false;
          }

          // Salary filter - only apply if not at full range (10-200)
          if (_currentFilters['minSalary'] != null && _currentFilters['maxSalary'] != null) {
            double minSalary = _currentFilters['minSalary'].toDouble();
            double maxSalary = _currentFilters['maxSalary'].toDouble();
            // Skip filter if at full range (no salary filter selected)
            bool isFullRange = minSalary == 10 && maxSalary == 200;
            if (!isFullRange && !SalaryUtils.isWithinSalaryRange(job.salaryRange, minSalary, maxSalary)) {
              return false;
            }
          }

          // Experience filter
          if (_currentFilters['experience'] != null && _currentFilters['experience'].isNotEmpty) {
            String filterExperience = _currentFilters['experience'].toLowerCase();
            String jobExperience = job.experienceLevel.toLowerCase();
            // This is a simplified match - you might want to implement more sophisticated matching
            if (!jobExperience.contains(filterExperience.split(' ')[0])) {
              return false;
            }
          }

          // Specialization filter
          if (_currentFilters['specializations'] != null && (_currentFilters['specializations'] as List).isNotEmpty) {
            List<String> selectedSpecs = List<String>.from(_currentFilters['specializations']);
            bool matchesSpec = false;
            for (String spec in selectedSpecs) {
              if (job.title.toLowerCase().contains(spec.toLowerCase()) ||
                  job.description.toLowerCase().contains(spec.toLowerCase()) ||
                  job.requiredSkills.any((skill) => skill.toLowerCase().contains(spec.toLowerCase()))) {
                matchesSpec = true;
                break;
              }
            }
            if (!matchesSpec) return false;
          }
        }

        return true;
      }).toList();

      // Already sorted by createdAt from the service
      // Limit to 50 jobs
      if (filteredJobs.length > 50) {
        filteredJobs = filteredJobs.sublist(0, 50);
      }

      // Check if no results found and navigate to NoResultsScreen
      // Check if filters are actually active (not just at default values)
      bool hasActiveFilters = _searchQuery.isNotEmpty || 
                             _locationQuery.isNotEmpty || 
                             _selectedChips.isNotEmpty ||
                             (_currentFilters['workplace'] != null && _currentFilters['workplace'].isNotEmpty) ||
                             (_currentFilters['jobType'] != null && _currentFilters['jobType'].isNotEmpty) ||
                             (_currentFilters['positionLevel'] != null && _currentFilters['positionLevel'].isNotEmpty) ||
                             (_currentFilters['cities'] != null && (_currentFilters['cities'] as List).isNotEmpty) ||
                             (_currentFilters['experience'] != null && _currentFilters['experience'].isNotEmpty) ||
                             (_currentFilters['specializations'] != null && (_currentFilters['specializations'] as List).isNotEmpty) ||
                             (_currentFilters['minSalary'] != null && _currentFilters['maxSalary'] != null && 
                              !(_currentFilters['minSalary'] == 10 && _currentFilters['maxSalary'] == 200));
      
      debugPrint('Filtered jobs count: ${filteredJobs.length}');
      debugPrint('Has active filters: $hasActiveFilters');
      debugPrint('Current filters: $_currentFilters');
      
      if (filteredJobs.isEmpty && hasActiveFilters && mounted) {
        setState(() {
          _isLoading = false;
        });
        
        debugPrint('No results found, navigating to NoResultsScreen');
        // Navigate to NoResultsScreen and handle returned search query
        final newSearchQuery = await Navigator.push<String>(
          context,
          MaterialPageRoute(
            builder: (context) => NoResultsScreen(
              searchQuery: _getSearchQueryFromFilters(),
            ),
          ),
        );
        
        // If user entered a new search query, update and search again
        if (newSearchQuery != null && newSearchQuery.isNotEmpty && mounted) {
          setState(() {
            _searchController.text = newSearchQuery;
            _searchQuery = newSearchQuery;
          });
          _loadFilteredJobs();
        } else if (mounted) {
          // User pressed back without entering new search - clear all filters
          debugPrint('User pressed back from NoResultsScreen - clearing all filters');
          setState(() {
            _currentFilters = {};
            _searchQuery = '';
            _locationQuery = '';
            _searchController.clear();
            _locationController.clear();
            _selectedChips.clear();
          });
          _loadFilteredJobs();
        }
        return;
      }

      if (mounted) {
        setState(() {
          _jobs = filteredJobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading filtered jobs: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load jobs. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      body: Column(children: [_buildHeader(), Expanded(child: _buildBody())]),
    );
  }

  Widget _buildHeader() {
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return SizedBox(
      width: double.infinity,
      height: 280 + statusBarHeight,
      child: Stack(
        children: [
          // Rounded background container with exact image (220px height)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 220 + statusBarHeight,
              child: Image.asset(
                'assets/images/header_background.png',
                width: double.infinity,
                height: 220 + statusBarHeight,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to gradient if image fails to load
                  return Container(
                    width: double.infinity,
                    height: 220 + statusBarHeight,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-0.707, -0.707),
                        end: Alignment(0.707, 0.707),
                        colors: [
                          Color(0xFF0D0140),
                          Color(0xFF36353C),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Content layer (on top of background)
          Padding(
            padding: EdgeInsets.only(top: statusBarHeight),
            child: Stack(
              children: [
                // Back button
                Positioned(
                  left: 20,
                  top: 30,
                  child: GestureDetector(
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
                      color: Colors.white,
                    ),
                  ),
                ),

                // Search field at (29, 88)
                Positioned(
                  left: 29,
                  top: 88,
                  child: Container(
                    width: 317,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.search,
                          color: Color(0xFFAAA6B9),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: TextFormField(
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                isDense: true,
                                hintText: 'Search jobs...',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFAAA6B9),
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              onChanged: (value) {
                                debugPrint('Search query changed: "$value"');
                                setState(() {
                                  _searchQuery = value;
                                });
                                _loadFilteredJobs();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),

                // Location field at (30, 145)
                Positioned(
                  left: 30,
                  top: 145,
                  child: Container(
                    width: 317,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFFFF9228),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Center(
                            child: TextFormField(
                              controller: _locationController,
                              textAlignVertical: TextAlignVertical.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF524B6B),
                                fontFamily: 'DM Sans',
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                                isDense: true,
                                hintText: 'Enter location...',
                                hintStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFAAA6B9),
                                  fontFamily: 'DM Sans',
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _locationQuery = value;
                                });
                                _loadFilteredJobs();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                      ],
                    ),
                  ),
                ),

                // Filter button at (26, 240) - BELOW the rounded background
                Positioned(
                  left: 26,
                  top: 240,
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JobFilterScreen(
                            initialFilters: _currentFilters,
                          ),
                        ),
                      );
                      
                      if (result != null && mounted) {
                        debugPrint('Filters applied: $result');
                        setState(() {
                          _currentFilters = result;
                        });
                        _loadFilteredJobs();
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF130160),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFB7BFC7).withValues(alpha: 0.25),
                            blurRadius: 150,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/filter_icon_correct.png',
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.tune,
                              color: Colors.white,
                              size: 24,
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Chip 1: "Senior designer" at (81, 240)
                Positioned(
                  left: 81,
                  top: 240,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedChips.contains('Senior designer')) {
                          _selectedChips.remove('Senior designer');
                        } else {
                          _selectedChips.add('Senior designer');
                        }
                      });
                      _loadFilteredJobs();
                    },
                    child: Container(
                      width: 114,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedChips.contains('Senior designer')
                            ? const Color(0xFF130160)
                            : const Color(0xFFCBC9D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Senior designer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _selectedChips.contains('Senior designer')
                                ? Colors.white
                                : const Color(0xFF524B6B),
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Chip 2: "Designer" at (210, 240)
                Positioned(
                  left: 210,
                  top: 240,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedChips.contains('Designer')) {
                          _selectedChips.remove('Designer');
                        } else {
                          _selectedChips.add('Designer');
                        }
                      });
                      _loadFilteredJobs();
                    },
                    child: Container(
                      width: 77,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedChips.contains('Designer')
                            ? const Color(0xFF130160)
                            : const Color(0xFFCBC9D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Designer',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _selectedChips.contains('Designer')
                                ? Colors.white
                                : const Color(0xFF524B6B),
                            fontFamily: 'DM Sans',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Chip 3: "Full-time" at (302, 240)
                Positioned(
                  left: 302,
                  top: 240,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_selectedChips.contains('Full-time')) {
                          _selectedChips.remove('Full-time');
                        } else {
                          _selectedChips.add('Full-time');
                        }
                      });
                      _loadFilteredJobs();
                    },
                    child: Container(
                      width: 94,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _selectedChips.contains('Full-time')
                            ? const Color(0xFF130160)
                            : const Color(0xFFCBC9D4).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Full-time',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: _selectedChips.contains('Full-time')
                                ? Colors.white
                                : const Color(0xFF524B6B),
                            fontFamily: 'DM Sans',
                          ),
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
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading jobs',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadFilteredJobs,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No ${widget.filterType} jobs found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new opportunities',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.all(20),
      itemCount: _jobs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 15),
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(Job job) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final isBookmarked = bookmarkProvider.isBookmarked(job.id);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => JobDetailScreenNew(
                  job: job,
                  isBookmarked: isBookmarked,
                  onBookmarkToggled: (jobId) {
                    bookmarkProvider.toggleBookmark(jobId);
                  },
                ),
          ),
        );
      },
      child: Container(
        width: 335,
        height: 203,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF99ABC6).withValues(alpha: 0.18),
              blurRadius: 62,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Company logo at exact Figma position (20, 20)
            Positioned(
              left: 20,
              top: 20,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: job.companyLogo.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ImageUtils.buildSafeNetworkImage(
                          imageUrl: job.companyLogo,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorWidget: const Icon(Icons.business, size: 24),
                        ),
                      )
                    : const Icon(Icons.business, size: 24),
              ),
            ),
            
            // Bookmark button at exact Figma position (291, 20.5)
            Positioned(
              left: 291,
              top: 20.5,
              child: IconButton(
                onPressed: () {
                  bookmarkProvider.toggleBookmark(job.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isBookmarked ? 'Bookmark removed' : 'Job bookmarked',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFF524B6B),
                  size: 24,
                ),
              ),
            ),
            
            // Job title at exact Figma position (20, 70)
            Positioned(
              left: 20,
              top: 70,
              child: SizedBox(
                width: 271, // Card width (335) - left margin (20) - right margin (44 for bookmark)
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF150A33),
                    fontFamily: 'DM Sans',
                    height: 1.302,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Company name and location on one line at (20, 92)
            Positioned(
              left: 20,
              top: 92,
              child: SizedBox(
                width: 295, // Card width (335) - left margin (20) - right margin (20)
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        job.companyName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF524B6B),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF524B6B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        job.location,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF524B6B),
                          fontFamily: 'DM Sans',
                          height: 1.302,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Tags with uniform spacing at y: 128
            Positioned(
              left: 20,
              top: 128,
              child: SizedBox(
                width: 295, // Constrain within card (335 - 20 left - 20 right)
                child: Row(
                  children: [
                    _buildTag(job.experienceLevel.isNotEmpty ? job.experienceLevel : 'Design'),
                    const SizedBox(width: 10), // Uniform spacing
                    _buildTag(job.employmentType),
                    const SizedBox(width: 10), // Uniform spacing
                    if (job.workFrom != null && job.workFrom!.isNotEmpty)
                      Flexible(child: _buildTag(job.workFrom!)), // Flexible to prevent overflow
                  ],
                ),
              ),
            ),
            
            // Time at exact Figma position (20, 172)
            Positioned(
              left: 20,
              top: 172,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 150), // Prevent overlap with salary
                child: Text(
                  _formatTimeAgo(job.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFAAA6B9),
                    fontFamily: 'DM Sans',
                    height: 1.302,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            
            // Salary positioned from right edge to prevent overflow
            Positioned(
              right: 20,
              top: 169,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 100),
                child: _buildFormattedSalary(job.salaryRange, job.employmentType),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      height: 26,
      decoration: BoxDecoration(
        color: const Color(0xFFCBC9D4).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w400,
            color: Color(0xFF524B6B),
            fontFamily: 'DM Sans',
            height: 1.302,
          ),
        ),
      ),
    );
  }

  String _formatSalary(String salaryRange, String employmentType) {
    String period = '';
    switch (employmentType.toLowerCase()) {
      case 'full-time':
      case 'full time':
        period = '/Mo';
        break;
      case 'part-time':
      case 'part time':
        period = '/Hr';
        break;
      default:
        period = '';
    }
    return '\$${salaryRange}K$period';
  }

  Widget _buildFormattedSalary(String salaryRange, String employmentType) {
    if (salaryRange.isEmpty) {
      return RichText(
        textAlign: TextAlign.right,
        text: const TextSpan(
          children: [
            TextSpan(
              text: '\$0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232D3A),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
            TextSpan(
              text: '/Mo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
          ],
        ),
      );
    }

    try {
      final hasPeriod = salaryRange.contains('/');
      String period = '';
      String numberPart = salaryRange;
      
      if (hasPeriod) {
        final parts = salaryRange.split('/');
        numberPart = parts[0];
        if (parts.length > 1) {
          final periodText = parts[1].toLowerCase().trim();
          if (periodText.contains('hour') || periodText == 'hr') {
            period = '/Hr';
          } else if (periodText.contains('month') || periodText == 'mo') {
            period = '/Mo';
          } else if (periodText.contains('year') || periodText == 'yr') {
            period = '/Yr';
          } else if (periodText.contains('project')) {
            period = '/Project';
          } else {
            period = '/$periodText';
          }
        }
      }
      
      String cleaned = numberPart.replaceAll(RegExp(r'[$,\s]'), '');
      final numbers = RegExp(r'\d+').allMatches(cleaned);
      if (numbers.isEmpty) {
        return Text(
          salaryRange,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF232D3A),
            fontFamily: 'Open Sans',
            height: 1.362,
          ),
        );
      }
      
      int minSalary = int.parse(numbers.first.group(0)!);
      String formattedAmount = minSalary.toString();
      
      if (period.isEmpty) {
        switch (employmentType.toLowerCase()) {
          case 'full-time':
          case 'full time':
            period = '/Mo';
            break;
          case 'part-time':
          case 'part time':
            period = '/Hr';
            break;
          case 'freelance':
          case 'contract':
            period = '/Project';
            break;
          default:
            period = '/Mo';
        }
      }
      
      String currency = '\$';
      
      return RichText(
        textAlign: TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: '$currency$formattedAmount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232D3A),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
            TextSpan(
              text: period,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Error formatting salary: $e');
      return RichText(
        textAlign: TextAlign.right,
        text: const TextSpan(
          children: [
            TextSpan(
              text: '\$0',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF232D3A),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
            TextSpan(
              text: '/Mo',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF999999),
                fontFamily: 'Open Sans',
                height: 1.362,
              ),
            ),
          ],
        ),
      );
    }
  }
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}
