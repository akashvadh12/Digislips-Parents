// import 'package:cloud_firestore/cloud_firestore.dart';

// class LeaveModel {
//   final String destination;
//   final String leaveType;
//   final String reason;
//   final String status;
//   final DateTime submittedAt;
//   final DateTime fromDate;
//   final DateTime toDate;
//   final int totalDays;
//   final String travelMode;

//   LeaveModel({
//     required this.destination,
//     required this.leaveType,
//     required this.reason,
//     required this.status,
//     required this.submittedAt,
//     required this.fromDate,
//     required this.toDate,
//     required this.totalDays,
//     required this.travelMode,
//   });

//   factory LeaveModel.fromFirestore(Map<String, dynamic> data) {
//     return LeaveModel(
//       destination: data['destination'] ?? '',
//       leaveType: data['leaveType'] ?? '',
//       reason: data['reason'] ?? '',
//       status: data['status'] ?? '',
//       submittedAt: (data['submittedAt'] as Timestamp).toDate(),
//       fromDate: (data['fromDate'] as Timestamp).toDate(),
//       toDate: (data['toDate'] as Timestamp).toDate(),
//       totalDays: data['totalDays'] ?? 0,
//       travelMode: data['travelMode'] ?? '',
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'destination': destination,
//       'leaveType': leaveType,
//       'reason': reason,
//       'status': status,
//       'submittedAt': submittedAt,
//       'fromDate': fromDate,
//       'toDate': toDate,
//       'totalDays': totalDays,
//       'travelMode': travelMode,
//     };
//   }
// }
