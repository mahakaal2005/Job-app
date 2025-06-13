import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllApplicantsProvider with ChangeNotifier {
  List<Map<String, dynamic>> _allApplicants = [];
  List<Map<String, dynamic>> _filteredApplicants = [];
  String _searchQuery = '';
  String _selectedStatus = 'all';
  String _selectedJob = 'all';
  String _sortBy = 'date';
  bool _sortAscending = false;
  List<String> _jobTitles = ['all'];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<Map<String, dynamic>> get applicants => _filteredApplicants;
  bool get isLoading => _isLoading;
  String get error => _error;
  List<String> get jobTitles => _jobTitles;
  bool get isSortAscending => _sortAscending;
  String get sortBy => _sortBy;

  // Load all applicants
  Future<void> loadApplicants(
    String companyName, {
    String? jobId,
    String? jobTitle,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      final List<Map<String, dynamic>> allApplicants = [];

      if (jobId == null || jobId.isEmpty) {
        // Get all jobs for the company
        final jobsSnapshot =
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(companyName)
                .collection('jobPostings')
                .get();

        _jobTitles = [
          'all',
          ...jobsSnapshot.docs.map((job) => job['title'] as String),
        ];

        // Get applicants from each job
        for (var job in jobsSnapshot.docs) {
          final applicantsSnapshot =
              await FirebaseFirestore.instance
                  .collection('jobs')
                  .doc(companyName)
                  .collection('jobPostings')
                  .doc(job.id)
                  .collection('applicants')
                  .orderBy('appliedAt', descending: true)
                  .get();

          for (var doc in applicantsSnapshot.docs) {
            allApplicants.add({
              ...doc.data(),
              'id': doc.id,
              'jobId': job.id,
              'jobTitle': job['title'],
            });
          }
        }
      } else {
        // Get applicants for specific job
        final applicantsSnapshot =
            await FirebaseFirestore.instance
                .collection('jobs')
                .doc(companyName)
                .collection('jobPostings')
                .doc(jobId)
                .collection('applicants')
                .orderBy('appliedAt', descending: true)
                .get();

        for (var doc in applicantsSnapshot.docs) {
          allApplicants.add({
            ...doc.data(),
            'id': doc.id,
            'jobId': jobId,
            'jobTitle': jobTitle ?? '',
          });
        }
      }

      _allApplicants = allApplicants;
      _applyFilters();
    } catch (e) {
      _error = 'Failed to load applicants: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update filters
  void updateSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void updateStatusFilter(String status) {
    _selectedStatus = status;
    _applyFilters();
  }

  void updateJobFilter(String job) {
    _selectedJob = job;
    _applyFilters();
  }

  void updateSorting(String sortBy, {bool? ascending}) {
    if (sortBy == _sortBy) {
      // If same sort field, toggle direction
      _sortAscending = !_sortAscending;
    } else {
      // If new sort field, set it and default to descending
      _sortBy = sortBy;
      _sortAscending = ascending ?? false;
    }
    _applyFilters();
  }

  // Apply all filters
  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allApplicants);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered.where((applicant) {
            final name =
                applicant['applicantName']?.toString().toLowerCase() ?? '';
            final email =
                applicant['applicantEmail']?.toString().toLowerCase() ?? '';
            final query = _searchQuery.toLowerCase();
            return name.contains(query) || email.contains(query);
          }).toList();
    }

    // Apply status filter
    if (_selectedStatus != 'all') {
      filtered =
          filtered.where((applicant) {
            return (applicant['status'] ?? 'pending').toLowerCase() ==
                _selectedStatus;
          }).toList();
    }

    // Apply job filter
    if (_selectedJob != 'all') {
      filtered =
          filtered.where((applicant) {
            return applicant['jobTitle'] == _selectedJob;
          }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      if (_sortBy == 'date') {
        final aDate = DateTime.parse(a['appliedAt']);
        final bDate = DateTime.parse(b['appliedAt']);
        return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      } else if (_sortBy == 'name') {
        final aName = a['applicantName']?.toString() ?? '';
        final bName = b['applicantName']?.toString() ?? '';
        return _sortAscending ? aName.compareTo(bName) : bName.compareTo(aName);
      } else if (_sortBy == 'status') {
        final aStatus = a['status']?.toString() ?? 'pending';
        final bStatus = b['status']?.toString() ?? 'pending';
        return _sortAscending
            ? aStatus.compareTo(bStatus)
            : bStatus.compareTo(aStatus);
      }
      return 0;
    });

    _filteredApplicants = filtered;
    notifyListeners();
  }

  // Update applicant status
  Future<void> updateApplicantStatus({
    required String companyName,
    required String jobId,
    required String applicantId,
    required String status,
  }) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .collection('applicants')
          .doc(applicantId)
          .update({'status': status});

      // Update local state
      final index = _allApplicants.indexWhere((a) => a['id'] == applicantId);
      if (index != -1) {
        _allApplicants[index]['status'] = status;
        _applyFilters();
      }
    } catch (e) {
      _error = 'Failed to update status: $e';
      notifyListeners();
    }
  }
}
