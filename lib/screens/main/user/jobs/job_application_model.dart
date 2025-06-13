class JobApplication {
  final String id;
  final String jobId;
  final String jobTitle;
  final String companyName;
  final String applicantId;
  final String applicantName;
  final String applicantEmail;
  final String applicantPhone;
  final String applicantAddress;
  final List<String> applicantSkills;
  final String applicantProfileImg;
  final String applicantGender;
  final String resumeUrl;
  final String? resumePreviewUrl;
  final String whyJoin;
  final String yearsOfExperience;
  final DateTime appliedAt;
  final String status;

  JobApplication({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.companyName,
    required this.applicantId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantPhone,
    required this.applicantAddress,
    required this.applicantSkills,
    required this.applicantProfileImg,
    required this.applicantGender,
    required this.resumeUrl,
    this.resumePreviewUrl,
    required this.whyJoin,
    required this.yearsOfExperience,
    required this.appliedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'jobId': jobId,
      'jobTitle': jobTitle,
      'companyName': companyName,
      'applicantId': applicantId,
      'applicantName': applicantName,
      'applicantEmail': applicantEmail,
      'applicantPhone': applicantPhone,
      'applicantAddress': applicantAddress,
      'applicantSkills': applicantSkills,
      'applicantProfileImg': applicantProfileImg,
      'applicantGender': applicantGender,
      'resumeUrl': resumeUrl,
      'resumePreviewUrl': resumePreviewUrl,
      'whyJoin': whyJoin,
      'yearsOfExperience': yearsOfExperience,
      'appliedAt': appliedAt.toIso8601String(),
      'status': status,
    };
  }

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    return JobApplication(
      id: json['id'] ?? '',
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      applicantId: json['applicantId'] ?? '',
      applicantName: json['applicantName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      applicantPhone: json['applicantPhone'] ?? '',
      applicantAddress: json['applicantAddress'] ?? '',
      applicantSkills: List<String>.from(json['applicantSkills'] ?? []),
      applicantProfileImg: json['applicantProfileImg'] ?? '',
      applicantGender: json['applicantGender'] ?? '',
      resumeUrl: json['resumeUrl'] ?? '',
      resumePreviewUrl: json['resumePreviewUrl'],
      whyJoin: json['whyJoin'] ?? '',
      yearsOfExperience: json['yearsOfExperience'] ?? '',
      appliedAt: DateTime.parse(json['appliedAt']),
      status: json['status'] ?? 'pending',
    );
  }
}
