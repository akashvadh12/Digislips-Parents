import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  // Leave details
  final String? id;
  final String leaveType;
  final DateTime fromDate;
  final DateTime toDate;
  final int totalDays;
  final String reason;
  final String destination;
  final String travelMode;
  final List<String> documentUrls;
  final String status;
  final DateTime submittedAt;
  final String submittedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewComments;

  // Student details
  final String? uid;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? parentEmail;
  final String? parentPhone;
  final String? rollNumber;
  final String? department;
  final String? semester;
  final String? profileImageUrl;
  final bool? isEmailVerified;
  final bool? profileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  LeaveModel({
    this.id,
    required this.leaveType,
    required this.fromDate,
    required this.toDate,
    required this.totalDays,
    required this.reason,
    this.destination = '',
    this.travelMode = '',
    this.documentUrls = const [],
    this.status = 'Pending',
    required this.submittedAt,
    required this.submittedBy,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComments,
    this.uid,
    this.fullName,
    this.email,
    this.phone,
    this.parentEmail,
    this.parentPhone,
    this.rollNumber,
    this.department,
    this.semester,
    this.profileImageUrl,
    this.isEmailVerified,
    this.profileComplete,
    this.createdAt,
    this.updatedAt,
  });

  /// Deserialize from Firestore
  factory LeaveModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception(
        'LeaveModel.fromFirestore: Missing document data for ID ${doc.id}',
      );
    }

    Timestamp? safeTs(String field) =>
        data[field] is Timestamp ? data[field] as Timestamp : null;

    return LeaveModel(
      id: doc.id,
      leaveType: data['leaveType'] ?? '',
      fromDate: safeTs('fromDate')?.toDate() ?? DateTime.now(),
      toDate: safeTs('toDate')?.toDate() ?? DateTime.now(),
      totalDays: data['totalDays'] is int ? data['totalDays'] as int : 0,
      reason: data['reason'] ?? '',
      destination: data['destination'] ?? '',
      travelMode: data['travelMode'] ?? '',
      documentUrls: data['documentUrls'] is List
          ? List<String>.from(data['documentUrls'])
          : [],
      status: data['status'] ?? 'Pending',
      submittedAt: safeTs('submittedAt')?.toDate() ?? DateTime.now(),
      submittedBy: data['submittedBy'] ?? '',
      reviewedBy: data['reviewedBy'],
      reviewedAt: safeTs('reviewedAt')?.toDate(),
      reviewComments: data['reviewComments'],
      uid: data['uid'],
      fullName: data['fullName'],
      email: data['email'],
      phone: data['phone'],
      parentEmail: data['parentEmail'],
      parentPhone: data['parentPhone'],
      rollNumber: data['rollNumber'],
      department: data['department'],
      semester: data['semester'],
      profileImageUrl: data['profileImageUrl'],
      isEmailVerified: data['isEmailVerified'] is bool
          ? data['isEmailVerified'] as bool
          : null,
      profileComplete: data['profileComplete'] is bool
          ? data['profileComplete'] as bool
          : null,
      createdAt: safeTs('createdAt')?.toDate(),
      updatedAt: safeTs('updatedAt')?.toDate(),
    );
  }

  /// Serialize for Firestore (leave data only)
  Map<String, dynamic> toFirestore() {
    return {
      'leaveType': leaveType,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'totalDays': totalDays,
      'reason': reason,
      'destination': destination,
      'travelMode': travelMode,
      'documentUrls': documentUrls,
      'status': status,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'submittedBy': submittedBy,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewComments != null) 'reviewComments': reviewComments,
    };
  }

  /// Copy with updated fields
  LeaveModel copyWith({
    String? id,
    String? leaveType,
    DateTime? fromDate,
    DateTime? toDate,
    int? totalDays,
    String? reason,
    String? destination,
    String? travelMode,
    List<String>? documentUrls,
    String? status,
    DateTime? submittedAt,
    String? submittedBy,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? reviewComments,
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? parentEmail,
    String? parentPhone,
    String? rollNumber,
    String? department,
    String? semester,
    String? profileImageUrl,
    bool? isEmailVerified,
    bool? profileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeaveModel(
      id: id ?? this.id,
      leaveType: leaveType ?? this.leaveType,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      totalDays: totalDays ?? this.totalDays,
      reason: reason ?? this.reason,
      destination: destination ?? this.destination,
      travelMode: travelMode ?? this.travelMode,
      documentUrls: documentUrls ?? this.documentUrls,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      submittedBy: submittedBy ?? this.submittedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewComments: reviewComments ?? this.reviewComments,
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      parentEmail: parentEmail ?? this.parentEmail,
      parentPhone: parentPhone ?? this.parentPhone,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      semester: semester ?? this.semester,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileComplete: profileComplete ?? this.profileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Convert student info only to map
  Map<String, dynamic> get studentInfo => {
    if (uid != null) 'uid': uid,
    if (fullName != null) 'fullName': fullName,
    if (email != null) 'email': email,
    if (phone != null) 'phone': phone,
    if (parentEmail != null) 'parentEmail': parentEmail,
    if (parentPhone != null) 'parentPhone': parentPhone,
    if (rollNumber != null) 'rollNumber': rollNumber,
    if (department != null) 'department': department,
    if (semester != null) 'semester': semester,
    if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
    if (isEmailVerified != null) 'isEmailVerified': isEmailVerified,
    if (profileComplete != null) 'profileComplete': profileComplete,
    if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
  };

  @override
  String toString() {
    return 'LeaveModel('
        'id: $id, '
        'leaveType: $leaveType, '
        'from: $fromDate, '
        'to: $toDate, '
        'totalDays: $totalDays, '
        'submittedBy: $submittedBy, '
        'status: $status, '
        'student: $fullName [$rollNumber])';
  }
}
