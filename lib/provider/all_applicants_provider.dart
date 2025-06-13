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
  String get selectedStatus => _selectedStatus;

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

    // Apply status filter
    if (_selectedStatus != 'all') {
      filtered =
          filtered.where((applicant) {
            final status = applicant['status']?.toLowerCase() ?? 'pending';
            return status == _selectedStatus.toLowerCase();
          }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((applicant) {
            return applicant['applicantName']?.toLowerCase().contains(query) ==
                    true ||
                applicant['jobTitle']?.toLowerCase().contains(query) == true ||
                applicant['applicantEmail']?.toLowerCase().contains(query) ==
                    true;
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
      int comparison = 0;
      switch (_sortBy) {
        case 'date':
          final dateA = DateTime.parse(a['appliedAt']);
          final dateB = DateTime.parse(b['appliedAt']);
          comparison = dateA.compareTo(dateB);
          break;
        case 'name':
          comparison = (a['applicantName'] ?? '').compareTo(
            b['applicantName'] ?? '',
          );
          break;
        case 'status':
          comparison = (a['status'] ?? '').compareTo(b['status'] ?? '');
          break;
      }
      return _sortAscending ? comparison : -comparison;
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
      // Get the applicant data first
      final applicantDoc =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc(jobId)
              .collection('applicants')
              .doc(applicantId)
              .get();

      if (!applicantDoc.exists) {
        throw Exception('Applicant not found');
      }

      final applicantData = applicantDoc.data()!;

      // Update job application status
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .collection('applicants')
          .doc(applicantId)
          .update({'status': status});

      // Update user's application status in their profile
      await FirebaseFirestore.instance
          .collection('users_specific')
          .doc(applicantData['applicantId'])
          .collection('applications')
          .doc(jobId)
          .update({'status': status});

      // Update local state
      final index = _allApplicants.indexWhere((a) => a['id'] == applicantId);
      if (index != -1) {
        _allApplicants[index]['status'] = status;
        _applyFilters(); // This will update the filtered list
      }

      notifyListeners();
    } catch (e) {
      print('Error updating applicant status: $e');
      rethrow;
    }
  }
}
