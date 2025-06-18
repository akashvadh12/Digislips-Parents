// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';


// class LeaveService {
//   final _firestore = FirebaseFirestore.instance;

//   Stream<List<Map<String, dynamic>>> getAllLeaveApplications() {
//     return _firestore
//         .collectionGroup('leave')
//         .orderBy('submittedAt', descending: true)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.map((doc) {
//               final leave = LeaveModel.fromFirestore(doc);
//               return {
//                 'leave': leave,
//                 'userId': doc.reference.parent.parent!.id,
//                 'leaveId': doc.id,
//               };
//             }).toList());
//   }

//   Future<void> updateLeaveStatus(String userId, String leaveId, String status) {
//     return _firestore
//         .collection('users')
//         .doc(userId)
//         .collection('leave')
//         .doc(leaveId)
//         .update({'status': status});
//   }
// }
