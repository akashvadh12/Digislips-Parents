// // leave_request_controller.dart
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class LeaveRequestController extends ChangeNotifier {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
//   List<LeaveRequestWithStudent> _leaveRequests = [];
//   bool _isLoading = false;
//   String _errorMessage = '';

//   List<LeaveRequestWithStudent> get leaveRequests => _leaveRequests;
//   bool get isLoading => _isLoading;
//   String get errorMessage => _errorMessage;

//   Future<void> fetchAllLeaveRequests() async {
//     _isLoading = true;
//     _errorMessage = '';
//     notifyListeners();

//     try {
//       List<LeaveRequestWithStudent> allLeaveRequests = [];
      
//       // Get all students
//       QuerySnapshot studentsSnapshot = await _firestore.collection('students').get();
      
//       for (QueryDocumentSnapshot studentDoc in studentsSnapshot.docs) {
//         Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;
        
//         // Get leave requests for each student
//         QuerySnapshot leaveSnapshot = await _firestore
//             .collection('students')
//             .doc(studentDoc.id)
//             .collection('leave')
//             .orderBy('createdAt', descending: true)
//             .get();
        
//         for (QueryDocumentSnapshot leaveDoc in leaveSnapshot.docs) {
//           Map<String, dynamic> leaveData = leaveDoc.data() as Map<String, dynamic>;
          
//           allLeaveRequests.add(LeaveRequestWithStudent(
//             studentId: studentDoc.id,
//             studentName: studentData['fullName'] ?? 'Unknown',
//             studentEmail: studentData['email'] ?? '',
//             department: studentData['department'] ?? '',
//             leaveId: leaveDoc.id,
//             leaveData: leaveData,
//           ));
//         }
//       }
      
//       _leaveRequests = allLeaveRequests;
//     } catch (e) {
//       _errorMessage = 'Error fetching leave requests: $e';
//     }
    
//     _isLoading = false;
//     notifyListeners();
//   }

//   Future<void> updateLeaveStatus(String studentId, String leaveId, String status) async {
//     try {
//       await _firestore
//           .collection('students')
//           .doc(studentId)
//           .collection('leave')
//           .doc(leaveId)
//           .update({
//         'status': status,
//         'updatedAt': FieldValue.serverTimestamp(),
//       });
      
//       // Update local data
//       int index = _leaveRequests.indexWhere((req) => 
//           req.studentId == studentId && req.leaveId == leaveId);
//       if (index != -1) {
//         _leaveRequests[index].leaveData['status'] = status;
//         notifyListeners();
//       }
//     } catch (e) {
//       _errorMessage = 'Error updating leave status: $e';
//       notifyListeners();
//     }
//   }

//   String getLeaveStatus(Map<String, dynamic> leaveData) {
//     return leaveData['status'] ?? 'pending';
//   }

//   String formatDate(dynamic timestamp) {
//     if (timestamp == null) return 'N/A';
    
//     if (timestamp is Timestamp) {
//       DateTime date = timestamp.toDate();
//       return '${date.day}/${date.month}/${date.year}';
//     }
//     return timestamp.toString();
//   }

//   Color getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'approved':
//         return Colors.green;
//       case 'rejected':
//         return Colors.red;
//       default:
//         return Colors.orange;
//     }
//   }
// }

// class LeaveRequestWithStudent {
//   final String studentId;
//   final String studentName;
//   final String studentEmail;
//   final String department;
//   final String leaveId;
//   final Map<String, dynamic> leaveData;

//   LeaveRequestWithStudent({
//     required this.studentId,
//     required this.studentName,
//     required this.studentEmail,
//     required this.department,
//     required this.leaveId,
//     required this.leaveData,
//   });
// }