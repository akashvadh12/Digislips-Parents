import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String parentEmail;
  final String parentPhone;
  final String department;
  final String rollNumber;
  final String semester;
  final String? profileImageUrl;
  final bool isEmailVerified;
  final bool profileComplete;

  Student({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.parentEmail = '',
    this.parentPhone = '',
    required this.department,
    required this.rollNumber,
    this.semester = '1st Semester',
    this.profileImageUrl,
    this.isEmailVerified = false,
    this.profileComplete = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'department': department,
      'rollNumber': rollNumber,
      'semester': semester,
      'profileImageUrl': profileImageUrl,
      'isEmailVerified': isEmailVerified,
      'profileComplete': profileComplete,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      parentEmail: map['parentEmail'] ?? '',
      parentPhone: map['parentPhone'] ?? '',
      department: map['department'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      semester: map['semester'] ?? '1st Semester',
      profileImageUrl: map['profileImageUrl'],
      isEmailVerified: map['isEmailVerified'] ?? false,
      profileComplete: map['profileComplete'] ?? true,
    );
  }

  // Helper method to create a copy with updated fields
  Student copyWith({
    String? fullName,
    String? phone,
    String? parentEmail,
    String? parentPhone,
    String? department,
    String? semester,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? profileComplete,
  }) {
    return Student(
      uid: this.uid,
      fullName: fullName ?? this.fullName,
      email: this.email, // Email usually shouldn't be editable
      phone: phone ?? this.phone,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      department: department ?? this.department,
      rollNumber: this.rollNumber, // Roll number usually shouldn't be editable
      semester: semester ?? this.semester,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileComplete: profileComplete ?? this.profileComplete,
    );
  }

  // Helper method to get a map for updating profile (excludes non-editable fields)
  Map<String, dynamic> toUpdateMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'department': department,
      'semester': semester,
      'profileImageUrl': profileImageUrl,
      'profileComplete': profileComplete,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Validation methods
  bool get hasParentContact => parentEmail.isNotEmpty || parentPhone.isNotEmpty;
  
  bool get isParentEmailValid {
    if (parentEmail.isEmpty) return true; // Optional field
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(parentEmail);
  }
  
  bool get isParentPhoneValid {
    if (parentPhone.isEmpty) return true; // Optional field
    return parentPhone.length >= 10;
  }

  @override
  String toString() {
    return 'Student{uid: $uid, fullName: $fullName, email: $email, phone: $phone, parentEmail: $parentEmail, parentPhone: $parentPhone, department: $department, rollNumber: $rollNumber, semester: $semester}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Student &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          fullName == other.fullName &&
          email == other.email &&
          phone == other.phone &&
          parentEmail == other.parentEmail &&
          parentPhone == other.parentPhone &&
          department == other.department &&
          rollNumber == other.rollNumber &&
          semester == other.semester;

  @override
  int get hashCode =>
      uid.hashCode ^
      fullName.hashCode ^
      email.hashCode ^
      phone.hashCode ^
      parentEmail.hashCode ^
      parentPhone.hashCode ^
      department.hashCode ^
      rollNumber.hashCode ^
      semester.hashCode;
}