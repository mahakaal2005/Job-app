import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ApplicantProvider with ChangeNotifier {
  final Map<String, int> _applicantCounts = {};
  final Map<String, List<Map<String, dynamic>>> _applicants = {};
  bool _isLoading = false;
  final Map<String, StreamSubscription<QuerySnapshot>> _listeners = {};
  StreamSubscription<QuerySnapshot>? _companyListener; // Track company-level listener

  Map<String, int> get applicantCounts => _applicantCounts;
  Map<String, List<Map<String, dynamic>>> get applicants => _applicants;
  bool get isLoading => _isLoading;

  // Initialize real-time listeners for all jobs of a company
  void initializeCompanyListeners(String companyName) {
    // Cancel existing listeners for this company
    _cancelCompanyListeners(companyName);

    // Listen to all jobs in the company and TRACK this listener
    _companyListener = FirebaseFirestore.instance
        .collection('jobs')
        .doc(companyName)
        .collection('jobPostings')
        .snapshots()
        .listen(
          (snapshot) {
            for (var doc in snapshot.docs) {
              _setupJobListener(companyName, doc.id);
            }
          },
          onError: (error) {
            print('⚠️ Company listener error: $error');
            // Don't crash on permission errors during logout
          },
        );
  }

  void _setupJobListener(String companyName, String jobId) {
    // Cancel existing listener for this job if any
    _cancelJobListener(jobId);

    // Set up new listener with error handling
    final listener = FirebaseFirestore.instance
        .collection('jobs')
        .doc(companyName)
        .collection('jobPostings')
        .doc(jobId)
        .collection('applicants')
        .snapshots()
        .listen(
          (snapshot) {
            _applicantCounts[jobId] = snapshot.docs.length;
            notifyListeners();
          },
          onError: (error) {
            print('⚠️ Job listener error for $jobId: $error');
            // Don't crash on permission errors during logout
          },
        );

    _listeners[jobId] = listener;
  }

  void _cancelJobListener(String jobId) {
    _listeners[jobId]?.cancel();
    _listeners.remove(jobId);
  }

  void _cancelCompanyListeners(String companyName) {
    // Cancel the company-level listener first
    _companyListener?.cancel();
    _companyListener = null;
    
    // Then cancel all job-level listeners
    _listeners.forEach((jobId, listener) {
      listener.cancel();
    });
    _listeners.clear();
  }

  // Load applicants for a specific job
  Future<void> loadApplicants(
    String companyName,
    String jobId, {
    int limit = 3,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Ensure we have a listener for this job
      _setupJobListener(companyName, jobId);

      final snapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc(jobId)
              .collection('applicants')
              .orderBy('appliedAt', descending: true)
              .limit(limit)
              .get();

      final List<Map<String, dynamic>> applicantList = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        applicantList.add(data);
      }

      _applicants[jobId] = applicantList;
      _applicantCounts[jobId] = snapshot.docs.length;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      print('Error loading applicants: $e');
    }
  }

  // Update applicant status
  Future<void> updateApplicantStatus(
    String companyName,
    String jobId,
    String applicantId,
    String status,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .collection('applicants')
          .doc(applicantId)
          .update({'status': status});

      // Refresh applicants list
      await loadApplicants(companyName, jobId);
    } catch (e) {
      print('Error updating applicant status: $e');
      rethrow;
    }
  }

  // Clear data when needed
  void clearData() {
    print('🧹 ApplicantProvider: Cancelling all listeners...');
    _cancelCompanyListeners('');
    _applicantCounts.clear();
    _applicants.clear();
    print('✅ ApplicantProvider: All listeners cancelled');
    // Don't call notifyListeners() here - this is a cleanup operation
    // often called from dispose() or during navigation when the widget tree may be locked
  }

  @override
  void dispose() {
    print('🧹 ApplicantProvider: Disposing...');
    _cancelCompanyListeners('');
    super.dispose();
  }
}
