// import 'package:cloud_firestore/cloud_firestore.dart';

// class ContactModel {
//   // Contact/User details
//   final String? id;
//   final String fullName;
//   final String email;
//   final String phone;
//   final String? parentEmail;
//   final String? parentPhone;
//   final String? rollNumber;
//   final String department;
//   final String? semester;
//   final String role; // 'student', 'teacher', 'admin', 'parent'
//   final String? profileImageUrl;
//   final bool? isEmailVerified;
//   final bool? profileComplete;
//   final bool isOnline;
//   final List<String> visibleToRoles;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;

//   ContactModel({
//     this.id,
//     required this.fullName,
//     required this.email,
//     this.phone = '',
//     this.parentEmail,
//     this.parentPhone,
//     this.rollNumber,
//     required this.department,
//     this.semester,
//     this.role = 'student',
//     this.profileImageUrl,
//     this.isEmailVerified,
//     this.profileComplete,
//     this.isOnline = false,
//     this.visibleToRoles = const ['admin', 'teacher', 'student'],
//     this.createdAt,
//     this.updatedAt,
//   });

//   /// Deserialize from Firestore (following LeaveModel pattern)
//   factory ContactModel.fromFirestore(DocumentSnapshot doc) {
//     final data = doc.data() as Map<String, dynamic>?;

//     if (data == null) {
//       throw Exception(
//         'ContactModel.fromFirestore: Missing document data for ID ${doc.id}',
//       );
//     }

//     Timestamp? safeTs(String field) =>
//         data[field] is Timestamp ? data[field] as Timestamp : null;

//     return ContactModel(
//       id: doc.id,
//       fullName: data['fullName'] ?? data['name'] ?? '',
//       email: data['email'] ?? '',
//       phone: data['phone'] ?? '',
//       parentEmail: data['parentEmail'],
//       parentPhone: data['parentPhone'],
//       rollNumber: data['rollNumber'],
//       department: data['department'] ?? '',
//       semester: data['semester'],
//       role: data['role'] ?? 'student',
//       profileImageUrl: data['profileImageUrl'] ?? data['imageUrl'],
//       isEmailVerified: data['isEmailVerified'] is bool
//           ? data['isEmailVerified'] as bool
//           : null,
//       profileComplete: data['profileComplete'] is bool
//           ? data['profileComplete'] as bool
//           : null,
//       isOnline: data['isOnline'] is bool ? data['isOnline'] as bool : false,
//       visibleToRoles: data['visibleToRoles'] is List
//           ? List<String>.from(data['visibleToRoles'])
//           : ['admin', 'teacher', 'student'],
//       createdAt: safeTs('createdAt')?.toDate(),
//       updatedAt: safeTs('updatedAt')?.toDate(),
//     );
//   }

//   /// Legacy support for fromJson (backward compatibility)
//   factory ContactModel.fromJson(Map<String, dynamic> json) {
//     DateTime? parseDateTime(dynamic value) {
//       if (value == null) return null;
//       if (value is Timestamp) return value.toDate();
//       if (value is String) {
//         try {
//           return DateTime.parse(value);
//         } catch (e) {
//           return null;
//         }
//       }
//       return null;
//     }

//     return ContactModel(
//       id: json['id'],
//       fullName: json['fullName'] ?? json['name'] ?? '',
//       email: json['email'] ?? '',
//       phone: json['phone'] ?? '',
//       parentEmail: json['parentEmail'],
//       parentPhone: json['parentPhone'],
//       rollNumber: json['rollNumber'],
//       department: json['department'] ?? '',
//       semester: json['semester'],
//       role: json['role'] ?? 'student',
//       profileImageUrl: json['profileImageUrl'] ?? json['imageUrl'],
//       isEmailVerified: json['isEmailVerified'] is bool
//           ? json['isEmailVerified'] as bool
//           : null,
//       profileComplete: json['profileComplete'] is bool
//           ? json['profileComplete'] as bool
//           : null,
//       isOnline: json['isOnline'] is bool ? json['isOnline'] as bool : false,
//       visibleToRoles: json['visibleToRoles'] is List
//           ? List<String>.from(json['visibleToRoles'])
//           : ['admin', 'teacher', 'student'],
//       createdAt: parseDateTime(json['createdAt']),
//       updatedAt: parseDateTime(json['updatedAt']),
//     );
//   }

//   /// Serialize for Firestore
//   Map<String, dynamic> toFirestore() {
//     return {
//       'fullName': fullName,
//       'email': email,
//       'phone': phone,
//       if (parentEmail != null) 'parentEmail': parentEmail,
//       if (parentPhone != null) 'parentPhone': parentPhone,
//       if (rollNumber != null) 'rollNumber': rollNumber,
//       'department': department,
//       if (semester != null) 'semester': semester,
//       'role': role,
//       if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
//       if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
//       if (profileComplete != null) 'profileComplete': profileComplete,
//       'isOnline': isOnline,
//       'visibleToRoles': visibleToRoles,
//       if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
//       if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
//     };
//   }

//   /// Legacy support for toJson (backward compatibility)
//   Map<String, dynamic> toJson() {
//     return {
//       if (id != null) 'id': id,
//       'fullName': fullName,
//       'name': fullName, // Legacy field
//       'email': email,
//       'phone': phone,
//       if (parentEmail != null) 'parentEmail': parentEmail,
//       if (parentPhone != null) 'parentPhone': parentPhone,
//       if (rollNumber != null) 'rollNumber': rollNumber,
//       'department': department,
//       if (semester != null) 'semester': semester,
//       'role': role,
//       if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
//       if (profileImageUrl != null) 'imageUrl': profileImageUrl, // Legacy field
//       if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
//       if (profileComplete != null) 'profileComplete': profileComplete,
//       'isOnline': isOnline,
//       'visibleToRoles': visibleToRoles,
//       if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
//       if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
//     };
//   }

//   /// Copy with updated fields (following LeaveModel pattern)
//   ContactModel copyWith({
//     String? id,
//     String? fullName,
//     String? email,
//     String? phone,
//     String? parentEmail,
//     String? parentPhone,
//     String? rollNumber,
//     String? department,
//     String? semester,
//     String? role,
//     String? profileImageUrl,
//     bool? isEmailVerified,
//     bool? profileComplete,
//     bool? isOnline,
//     List<String>? visibleToRoles,
//     DateTime? createdAt,
//     DateTime? updatedAt,
//   }) {
//     return ContactModel(
//       id: id ?? this.id,
//       fullName: fullName ?? this.fullName,
//       email: email ?? this.email,
//       phone: phone ?? this.phone,
//       parentEmail: parentEmail ?? this.parentEmail,
//       parentPhone: parentPhone ?? this.parentPhone,
//       rollNumber: rollNumber ?? this.rollNumber,
//       department: department ?? this.department,
//       semester: semester ?? this.semester,
//       role: role ?? this.role,
//       profileImageUrl: profileImageUrl ?? this.profileImageUrl,
//       isEmailVerified: isEmailVerified ?? this.isEmailVerified,
//       profileComplete: profileComplete ?? this.profileComplete,
//       isOnline: isOnline ?? this.isOnline,
//       visibleToRoles: visibleToRoles ?? this.visibleToRoles,
//       createdAt: createdAt ?? this.createdAt,
//       updatedAt: updatedAt ?? this.updatedAt,
//     );
//   }

//   /// Get contact info as a map (following LeaveModel pattern)
//   Map<String, dynamic> get contactInfo => {
//     if (id != null) 'id': id,
//     'fullName': fullName,
//     'email': email,
//     'phone': phone,
//     if (parentEmail != null) 'parentEmail': parentEmail,
//     if (parentPhone != null) 'parentPhone': parentPhone,
//     if (rollNumber != null) 'rollNumber': rollNumber,
//     'department': department,
//     if (semester != null) 'semester': semester,
//     'role': role,
//     if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
//     if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
//     if (profileComplete != null) 'profileComplete': profileComplete,
//     'isOnline': isOnline,
//     'visibleToRoles': visibleToRoles,
//   };

//   /// Get display name (prioritizes fullName, falls back to email)
//   String get displayName {
//     if (fullName.isNotEmpty) return fullName;
//     return email.isNotEmpty ? email.split('@').first : 'Unknown User';
//   }

//   /// Get role display text
//   String get roleDisplayText {
//     switch (role.toLowerCase()) {
//       case 'student':
//         return 'Student';
//       case 'teacher':
//         return 'Teacher';
//       case 'admin':
//         return 'Administrator';
//       case 'parent':
//         return 'Parent/Guardian';
//       default:
//         return role.isNotEmpty ? role : 'Unknown';
//     }
//   }

//   /// Check if contact is visible to a specific role
//   bool isVisibleToRole(String userRole) {
//     return visibleToRoles.contains(userRole.toLowerCase());
//   }

//   /// Get formatted phone number
//   String get formattedPhone {
//     if (phone.isEmpty) return '';
//     // Add basic formatting for Indian numbers
//     if (phone.length == 10) {
//       return '+91 ${phone.substring(0, 5)} ${phone.substring(5)}';
//     }
//     return phone;
//   }

//   @override
//   String toString() {
//     return 'ContactModel('
//         'id: $id, '
//         'fullName: $fullName, '
//         'email: $email, '
//         'department: $department, '
//         'role: $role, '
//         'rollNumber: $rollNumber, '
//         'isOnline: $isOnline)';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;
//     return other is ContactModel && other.id == id;
//   }

//   @override
//   int get hashCode => id.hashCode;
// }

// // Legacy models for backward compatibility (can be removed later)
// @Deprecated('Use ContactModel instead')
// class ContectModel extends ContactModel {
//   ContectModel({
//     required String id,
//     required String name,
//     required String email,
//     required String role,
//     required String imageUrl,
//   }) : super(
//           id: id,
//           fullName: name,
//           email: email,
//           role: role,
//           profileImageUrl: imageUrl,
//           department: '',
//         );

//   factory ContectModel.fromJson(Map<String, dynamic> json) {
//     return ContectModel(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       role: json['role'] ?? '',
//       imageUrl: json['imageUrl'] ?? '',
//     );
//   }
// }

// @Deprecated('Use ContactModel instead')
// class UserModel extends ContactModel {
//   UserModel({
//     required String id,
//     required String name,
//     required String email,
//     required String role,
//     required String imageUrl,
//   }) : super(
//           id: id,
//           fullName: name,
//           email: email,
//           role: role,
//           profileImageUrl: imageUrl,
//           department: '',
//         );

//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] ?? '',
//       name: json['name'] ?? '',
//       email: json['email'] ?? '',
//       role: json['role'] ?? '',
//       imageUrl: json['imageUrl'] ?? '',
//     );
//   }
// }