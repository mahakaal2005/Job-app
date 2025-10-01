import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class JobProvider with ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = true;
  final Map<String, int> _applicantCounts = {};

  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;
  Map<String, int> get applicantCounts => _applicantCounts;

  JobProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadJobs();
  }

  Future<List<Job>> getEmployerJobs() async {
    try {
      return await JobService.getCompanyJobs();
    } catch (e) {
      print('Error getting employer jobs: $e');
      return [];
    }
  }

  Future<void> loadJobs() async {
    try {
      _isLoading = true;
      notifyListeners();

      _jobs = await JobService.getCompanyJobs();
      await _loadApplicantCounts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadApplicantCounts() async {
    try {
      for (var job in _jobs) {
        final count = await _getApplicantCount(job.id, job.companyName);
        _applicantCounts[job.id] = count;
      }
      notifyListeners();
    } catch (e) {
      print('Error loading applicant counts: $e');
    }
  }

  Future<int> _getApplicantCount(String jobId, String companyName) async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('jobs')
              .doc(companyName)
              .collection('jobPostings')
              .doc(jobId)
              .collection('applicants')
              .count()
              .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting applicant count: $e');
      return 0;
    }
  }

  Future<void> updateApplicantCount(String jobId, String companyName) async {
    try {
      final count = await _getApplicantCount(jobId, companyName);
      _applicantCounts[jobId] = count;

      // Update the job in the list
      _jobs =
          _jobs.map((job) {
            if (job.id == jobId) {
              return job.copyWith(applicantsCount: count);
            }
            return job;
          }).toList();

      notifyListeners();
    } catch (e) {
      print('Error updating applicant count: $e');
    }
  }

  Future<void> addJob(Job job) async {
    try {
      _isLoading = true;
      notifyListeners();

      await JobService.createJob(job);
      await loadJobs(); // Refresh the list
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateJobStatus(String jobId, bool isActive) async {
    try {
      await JobService.toggleJobStatus(jobId, isActive);

      // Update local state
      _jobs =
          _jobs.map((job) {
            if (job.id == jobId) {
              return job.copyWith(isActive: isActive);
            }
            return job;
          }).toList();

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteJob(String jobId) async {
    try {
      await JobService.deleteJob(jobId);
      _applicantCounts.remove(jobId);
      await loadJobs(); // Refresh the list
    } catch (e) {
      rethrow;
    }
  }
}
