import 'package:cloud_firestore/cloud_firestore.dart';

class JobApplication {
  final String userId;
  final String jobId;
  final String companyId;
  final DateTime applicationDate;
  final bool? canRelocate;
  final String hireReason;
  final bool availableImmediately;
  final String resumeUrl;
  final String status;

  JobApplication({
    required this.userId,
    required this.jobId,
    required this.companyId,
    required this.applicationDate,
    this.canRelocate,
    required this.hireReason,
    required this.availableImmediately,
    required this.resumeUrl,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'jobId': jobId,
      'companyId': companyId,
      'applicationDate': applicationDate,
      'canRelocate': canRelocate,
      'hireReason': hireReason,
      'availableImmediately': availableImmediately,
      'resumeUrl': resumeUrl,
      'status': status,
    };
  }

  factory JobApplication.fromMap(Map<String, dynamic> map) {
    return JobApplication(
      userId: map['userId'],
      jobId: map['jobId'],
      companyId: map['companyId'],
      applicationDate: (map['applicationDate'] as Timestamp).toDate(),
      canRelocate: map['canRelocate'],
      hireReason: map['hireReason'],
      availableImmediately: map['availableImmediately'],
      resumeUrl: map['resumeUrl'],
      status: map['status'],
    );
  }
}