class AppUser {
  final String id;
  final String email;
  final String displayName;
  final String studentId;
  final String role; // 'student' | 'moderator' | 'admin'
  final String? phoneNumber;
  final bool isVerified;

  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.studentId,
    this.role = 'student',
    this.phoneNumber,
    this.isVerified = true,
  });

  bool get isModerator => role == 'moderator' || role == 'admin';
  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'studentId': studentId,
      'role': role,
      'phoneNumber': phoneNumber,
      'isVerified': isVerified,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      studentId: map['studentId'] ?? '',
      role: map['role'] ?? 'student',
      phoneNumber: map['phoneNumber'],
      isVerified: map['isVerified'] ?? true,
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? studentId,
    String? role,
    String? phoneNumber,
    bool? isVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      studentId: studentId ?? this.studentId,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
