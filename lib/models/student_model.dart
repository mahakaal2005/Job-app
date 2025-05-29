class StudentModel {
  final String uid;
  final String userType;
  final String name;
  final int age;
  final String college;
  final List<String> skills;
  final StudentAvailability availability;
  final double totalEarned;
  final bool upiLinked;
  final String? resumeUrl;
  final String? resumeCloudinaryId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentModel({
    required this.uid,
    required this.userType,
    required this.name,
    required this.age,
    required this.college,
    required this.skills,
    required this.availability,
    this.totalEarned = 0.0,
    this.upiLinked = false,
    this.resumeUrl,
    this.resumeCloudinaryId,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'userType': userType,
      'name': name,
      'age': age,
      'college': college,
      'skills': skills,
      'availability': availability.toMap(),
      'totalEarned': totalEarned,
      'upiLinked': upiLinked,
      'resumeUrl': resumeUrl,
      'resumeCloudinaryId': resumeCloudinaryId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory StudentModel.fromFirestore(Map<String, dynamic> data) {
    return StudentModel(
      uid: data['uid'] ?? '',
      userType: data['userType'] ?? 'student',
      name: data['name'] ?? '',
      age: data['age'] ?? 0,
      college: data['college'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      availability: StudentAvailability.fromMap(data['availability'] ?? {}),
      totalEarned: (data['totalEarned'] ?? 0).toDouble(),
      upiLinked: data['upiLinked'] ?? false,
      resumeUrl: data['resumeUrl'],
      resumeCloudinaryId: data['resumeCloudinaryId'],
      createdAt: data['createdAt']?.toDate(),
      updatedAt: data['updatedAt']?.toDate(),
    );
  }

  StudentModel copyWith({
    String? uid,
    String? userType,
    String? name,
    int? age,
    String? college,
    List<String>? skills,
    StudentAvailability? availability,
    double? totalEarned,
    bool? upiLinked,
    String? resumeUrl,
    String? resumeCloudinaryId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      uid: uid ?? this.uid,
      userType: userType ?? this.userType,
      name: name ?? this.name,
      age: age ?? this.age,
      college: college ?? this.college,
      skills: skills ?? this.skills,
      availability: availability ?? this.availability,
      totalEarned: totalEarned ?? this.totalEarned,
      upiLinked: upiLinked ?? this.upiLinked,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      resumeCloudinaryId: resumeCloudinaryId ?? this.resumeCloudinaryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class StudentAvailability {
  final int weeklyHours;
  final List<String> preferredSlots;

  const StudentAvailability({
    required this.weeklyHours,
    required this.preferredSlots,
  });

  Map<String, dynamic> toMap() {
    return {'weeklyHours': weeklyHours, 'preferredSlots': preferredSlots};
  }

  factory StudentAvailability.fromMap(Map<String, dynamic> map) {
    return StudentAvailability(
      weeklyHours: map['weeklyHours'] ?? 0,
      preferredSlots: List<String>.from(map['preferredSlots'] ?? []),
    );
  }

  StudentAvailability copyWith({
    int? weeklyHours,
    List<String>? preferredSlots,
  }) {
    return StudentAvailability(
      weeklyHours: weeklyHours ?? this.weeklyHours,
      preferredSlots: preferredSlots ?? this.preferredSlots,
    );
  }
}
