import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class ApplicantStatusProvider with ChangeNotifier {
  final Map<String, String> _statusCache = {};
  final Map<String, StreamSubscription> _statusListeners = {};
  bool _isLoading = false;
  String _error = '';

  bool get isLoading => _isLoading;
  String get error => _error;

  // Get status for a specific application
  String getStatus(String companyName, String jobId, String applicantId) {
    final key = '$companyName-$jobId-$applicantId';
    return _statusCache[key] ?? 'pending';
  }

  // Update status for an application
  Future<void> updateStatus({
    required String companyName,
    required String jobId,
    required String applicantId,
    required String status,
  }) async {
    try {
      _isLoading = true;
      _error = '';
      notifyListeners();

      // Update local cache immediately for instant UI update
      final key = '$companyName-$jobId-$applicantId';
      _statusCache[key] = status;
      notifyListeners();

      // Update job application status
      await FirebaseFirestore.instance
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .collection('applicants')
          .doc(applicantId)
          .update({'status': status});

      // Get the applicant data after updating the status
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

      // Update user's application status in their profile
      await FirebaseFirestore.instance
          .collection('users_specific')
          .doc(applicantData['applicantId'])
          .collection('applications')
          .doc(jobId)
          .update({'status': status});

      // Update analytics
      await _updateAnalytics(companyName, jobId, status);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Load initial statuses for a job and set up real-time listener
  Future<void> loadJobStatuses(String companyName, String jobId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Cancel existing listener for this job if any
      _cancelJobListener(jobId);

      // Load initial data first
      final snapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc(jobId)
              .collection('applicants')
              .get();

      // Update cache with initial data
      for (var doc in snapshot.docs) {
        final key = '$companyName-$jobId-${doc.id}';
        _statusCache[key] = doc.data()['status'] ?? 'pending';
      }
      notifyListeners();

      // Set up real-time listener for this job's applicants with error handling
      final listener = FirebaseFirestore.instance
          .collection('jobs')
          .doc(companyName)
          .collection('jobPostings')
          .doc(jobId)
          .collection('applicants')
          .snapshots()
          .listen(
            (snapshot) {
              try {
                bool hasChanges = false;
                for (var doc in snapshot.docs) {
                  final key = '$companyName-$jobId-${doc.id}';
                  final newStatus = doc.data()['status'] ?? 'pending';
                  if (_statusCache[key] != newStatus) {
                    _statusCache[key] = newStatus;
                    hasChanges = true;
                  }
                }
                if (hasChanges) {
                  notifyListeners();
                }
              } catch (e) {
                // Catch any errors from notifyListeners() during navigation
                print('⚠️ Error in status listener callback: $e');
              }
            },
            onError: (error) {
              print('⚠️ Status listener error for job $jobId: $error');
              // Don't crash on permission errors during logout
            },
          );

      _statusListeners[jobId] = listener;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Cancel listener for a specific job
  void _cancelJobListener(String jobId) {
    _statusListeners[jobId]?.cancel();
    _statusListeners.remove(jobId);
  }

  // Clear cache for a specific job
  void clearJobCache(String companyName, String jobId) {
    print('🧹 ApplicantStatusProvider: Clearing cache for job $jobId');
    _cancelJobListener(jobId);
    _statusCache.removeWhere(
      (key, _) => key.startsWith('$companyName-$jobId-'),
    );
    // Don't call notifyListeners() here - this is a cleanup operation
    // often called from dispose() when the widget tree may be locked
  }

  // Clear all cache and listeners
  void clearAllCache() {
    print('🧹 ApplicantStatusProvider: Cancelling all ${_statusListeners.length} listeners...');
    _statusListeners.forEach((_, listener) => listener.cancel());
    _statusListeners.clear();
    _statusCache.clear();
    print('✅ ApplicantStatusProvider: All listeners cancelled');
    // Don't call notifyListeners() here - this is a cleanup operation
    // often called from dispose() when the widget tree may be locked
  }

  @override
  void dispose() {
    clearAllCache();
    super.dispose();
  }

  // Update analytics
  Future<void> _updateAnalytics(
    String companyName,
    String jobId,
    String status,
  ) async {
    try {
      final analyticsRef = FirebaseFirestore.instance
          .collection('analytics')
          .doc(companyName)
          .collection('jobs')
          .doc(jobId);

      // Get current analytics
      final analyticsDoc = await analyticsRef.get();
      final analytics = analyticsDoc.data() ?? {};

      // Update counts
      final Map<String, int> statusCounts = Map<String, int>.from(
        analytics['statusCounts'] ?? {},
      );
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;

      // Update analytics document
      await analyticsRef.set({
        'statusCounts': statusCounts,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating analytics: $e');
      // Don't throw here as analytics update is not critical
    }
  }
}
