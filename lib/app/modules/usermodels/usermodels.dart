import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
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
  });

  factory LeaveModel.fromMap(Map<String, dynamic> data) {
    return LeaveModel(
      id: data['id'],
      leaveType: data['leaveType'] ?? '',
      fromDate: (data['fromDate'] as Timestamp).toDate(),
      toDate: (data['toDate'] as Timestamp).toDate(),
      totalDays: data['totalDays'] ?? 0,
      reason: data['reason'] ?? '',
      destination: data['destination'] ?? '',
      travelMode: data['travelMode'] ?? '',
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      status: data['status'] ?? 'Pending',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      submittedBy: data['submittedBy'] ?? '',
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      reviewComments: data['reviewComments'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewComments': reviewComments,
    };
  }

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
    );
  }
}

class UserModel {
  // User Information Fields
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String department;
  final String rollNumber;
  final String semester;
  final bool isEmailVerified;
  final bool profileComplete;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Leave Information Fields (embedded in user document)
  final String? leaveType;
  final DateTime? fromDate;
  final DateTime? toDate;
  final int? totalDays;
  final String? reason;
  final String? destination;
  final String? travelMode;
  final List<String>? documentUrls;
  final String? status;
  final DateTime? submittedAt;
  final String? submittedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewComments;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.department,
    required this.rollNumber,
    required this.semester,
    required this.isEmailVerified,
    required this.profileComplete,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
    // Leave fields
    this.leaveType,
    this.fromDate,
    this.toDate,
    this.totalDays,
    this.reason,
    this.destination,
    this.travelMode,
    this.documentUrls,
    this.status,
    this.submittedAt,
    this.submittedBy,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewComments,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: data['uid'] ?? doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      department: data['department'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      semester: data['semester'] ?? '',
      isEmailVerified: data['isEmailVerified'] ?? false,
      profileComplete: data['profileComplete'] ?? false,
      profileImageUrl: data['profileImageUrl'],
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : DateTime.now(),
      
      // Leave fields
      leaveType: data['leaveType'],
      fromDate: data['fromDate'] != null 
          ? (data['fromDate'] as Timestamp).toDate() 
          : null,
      toDate: data['toDate'] != null 
          ? (data['toDate'] as Timestamp).toDate() 
          : null,
      totalDays: data['totalDays'],
      reason: data['reason'],
      destination: data['destination'],
      travelMode: data['travelMode'],
      documentUrls: data['documentUrls'] != null 
          ? List<String>.from(data['documentUrls']) 
          : null,
      status: data['status'],
      submittedAt: data['submittedAt'] != null 
          ? (data['submittedAt'] as Timestamp).toDate() 
          : null,
      submittedBy: data['submittedBy'],
      reviewedBy: data['reviewedBy'],
      reviewedAt: data['reviewedAt'] != null 
          ? (data['reviewedAt'] as Timestamp).toDate() 
          : null,
      reviewComments: data['reviewComments'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'rollNumber': rollNumber,
      'semester': semester,
      'isEmailVerified': isEmailVerified,
      'profileComplete': profileComplete,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      
      // Leave fields (only include if not null)
      if (leaveType != null) 'leaveType': leaveType,
      if (fromDate != null) 'fromDate': Timestamp.fromDate(fromDate!),
      if (toDate != null) 'toDate': Timestamp.fromDate(toDate!),
      if (totalDays != null) 'totalDays': totalDays,
      if (reason != null) 'reason': reason,
      if (destination != null) 'destination': destination,
      if (travelMode != null) 'travelMode': travelMode,
      if (documentUrls != null) 'documentUrls': documentUrls,
      if (status != null) 'status': status,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (submittedBy != null) 'submittedBy': submittedBy,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (reviewComments != null) 'reviewComments': reviewComments,
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'department': department,
      'rollNumber': rollNumber,
      'semester': semester,
      'isEmailVerified': isEmailVerified,
      'profileComplete': profileComplete,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      
      // Leave fields
      'leaveType': leaveType,
      'fromDate': fromDate != null ? Timestamp.fromDate(fromDate!) : null,
      'toDate': toDate != null ? Timestamp.fromDate(toDate!) : null,
      'totalDays': totalDays,
      'reason': reason,
      'destination': destination,
      'travelMode': travelMode,
      'documentUrls': documentUrls,
      'status': status,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'submittedBy': submittedBy,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
      'reviewComments': reviewComments,
    };
  }

  // Extract user info only (without leave data)
  Map<String, dynamic> get userInfoOnly => {
    'uid': uid,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'department': department,
    'rollNumber': rollNumber,
    'semester': semester,
    'isEmailVerified': isEmailVerified,
    'profileComplete': profileComplete,
    'profileImageUrl': profileImageUrl,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  // Extract leave info only (without user data)
  Map<String, dynamic> get leaveInfoOnly => {
    if (leaveType != null) 'leaveType': leaveType,
    if (fromDate != null) 'fromDate': Timestamp.fromDate(fromDate!),
    if (toDate != null) 'toDate': Timestamp.fromDate(toDate!),
    if (totalDays != null) 'totalDays': totalDays,
    if (reason != null) 'reason': reason,
    if (destination != null) 'destination': destination,
    if (travelMode != null) 'travelMode': travelMode,
    if (documentUrls != null) 'documentUrls': documentUrls,
    if (status != null) 'status': status,
    if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
    if (submittedBy != null) 'submittedBy': submittedBy,
    if (reviewedBy != null) 'reviewedBy': reviewedBy,
    if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    if (reviewComments != null) 'reviewComments': reviewComments,
  };

  // Convert to LeaveModel (if leave data exists)
  LeaveModel? toLeaveModel() {
    if (leaveType == null || fromDate == null || toDate == null || 
        totalDays == null || reason == null || submittedAt == null || 
        submittedBy == null) {
      return null;
    }

    return LeaveModel(
      leaveType: leaveType!,
      fromDate: fromDate!,
      toDate: toDate!,
      totalDays: totalDays!,
      reason: reason!,
      destination: destination ?? '',
      travelMode: travelMode ?? '',
      documentUrls: documentUrls ?? [],
      status: status ?? 'Pending',
      submittedAt: submittedAt!,
      submittedBy: submittedBy!,
      reviewedBy: reviewedBy,
      reviewedAt: reviewedAt,
      reviewComments: reviewComments,
    );
  }

  // Check if user has active leave
  bool get hasActiveLeave => status != null && status != 'Rejected';

  // Check if leave is pending
  bool get hasLeaveStatus => status == 'Pending';

  // Check if leave is approved
  bool get hasApprovedLeave => status == 'Approved';

  UserModel copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    String? department,
    String? rollNumber,
    String? semester,
    bool? isEmailVerified,
    bool? profileComplete,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    
    // Leave fields
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      rollNumber: rollNumber ?? this.rollNumber,
      semester: semester ?? this.semester,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      profileComplete: profileComplete ?? this.profileComplete,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      
      // Leave fields
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
    );
  }

  @override
  String toString() {
    return 'UserModel('
        'uid: $uid, '
        'fullName: $fullName, '
        'email: $email, '
        'department: $department, '
        'rollNumber: $rollNumber, '
        'semester: $semester, '
        'hasLeave: ${status != null}, '
        'leaveStatus: $status'
        ')';
  }
}