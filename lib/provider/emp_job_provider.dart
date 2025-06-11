import 'package:flutter/material.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job%20new%20model.dart';
import 'package:get_work_app/screens/main/employye/new%20post/job_services.dart';

class JobProvider with ChangeNotifier {
  List<Job> _jobs = [];
  bool _isLoading = true;
  List<Job> get jobs => _jobs;
  bool get isLoading => _isLoading;

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
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
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
      await loadJobs(); // Refresh the list
    } catch (e) {
      rethrow;
    }
  }
}
