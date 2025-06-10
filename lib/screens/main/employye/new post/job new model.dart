class Job {
  final String id;
  final String title;
  final String description;
  final String location;
  final String employmentType;
  final String experienceLevel;
  final String salaryRange;
  final List<String> requiredSkills;
  final List<String> responsibilities;
  final List<String> requirements;
  final List<String> benefits;
  final String companyName;
  final String companyLogo;
  final String employerId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int applicantsCount;
  final int viewCount;
  final String? workFrom;

  Job({
    this.applicantsCount = 0,
    this.viewCount = 0,
    required this.id,
    required this.title,
    required this.benefits,
    required this.description,
    required this.location,
    required this.employmentType,
    required this.experienceLevel,
    required this.salaryRange,
    required this.requiredSkills,
    required this.responsibilities,
    required this.requirements,
    required this.companyName,
    required this.companyLogo,
    required this.employerId,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    required this.workFrom,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      employmentType: json['employmentType'] ?? '',
      experienceLevel: json['experienceLevel'] ?? '',
      salaryRange: json['salaryRange'] ?? '',
      requiredSkills: List<String>.from(json['requiredSkills'] ?? []),
      responsibilities: List<String>.from(json['responsibilities'] ?? []),
      requirements: List<String>.from(json['requirements'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      companyName: json['companyName'] ?? '',
      companyLogo: json['companyLogo'] ?? '',
      employerId: json['employerId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      applicantsCount: json['applicantsCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
      workFrom: json['workFrom'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'employmentType': employmentType,
      'experienceLevel': experienceLevel,
      'salaryRange': salaryRange,
      'requiredSkills': requiredSkills,
      'responsibilities': responsibilities,
      'requirements': requirements,
      'benefits': benefits,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'employerId': employerId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'applicantsCount': applicantsCount,
      'viewCount': viewCount,
      'workFrom': workFrom,
    };
  }

  Job copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    String? employmentType,
    String? experienceLevel,
    String? salaryRange,
    List<String>? requiredSkills,
    List<String>? responsibilities,
    List<String>? requirements,
    String? companyName,
    String? companyLogo,
    String? employerId,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    List<String>? benefits,
    int? applicantsCount,
    int? viewCount,
    String? workFrom,
  }) {
    return Job(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      employmentType: employmentType ?? this.employmentType,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      salaryRange: salaryRange ?? this.salaryRange,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      responsibilities: responsibilities ?? this.responsibilities,
      benefits: benefits ?? this.benefits,
      requirements: requirements ?? this.requirements,
      companyName: companyName ?? this.companyName,
      companyLogo: companyLogo ?? this.companyLogo,
      employerId: employerId ?? this.employerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      applicantsCount: applicantsCount ?? this.applicantsCount,
      viewCount: viewCount ?? this.viewCount,
      workFrom: workFrom ?? this.workFrom,
    );
  }
}
