// // services/contact_service.dart
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:digislips/app/modules/contect/contect_model.dart';

// class ContactService {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Get all student contacts (similar to getAllLeaveApplications in LeaveService)
//   Stream<List<QueryDocumentSnapshot>> getAllStudentContacts() {
//     return _firestore
//         .collection('users')
//         .where('role', isEqualTo: 'student')
//         .where('profileComplete', isEqualTo: true)
//         .orderBy('department')
//         .orderBy('fullName')
//         .snapshots()
//         .map((snapshot) => snapshot.docs);
//   }

//   /// Get contacts for a specific department
//   Stream<List<ContactModel>> getContactsByDepartment(String department) {
//     return _firestore
//         .collection('users')
//         .where('role', isEqualTo: 'student')
//         .where('department', isEqualTo: department)
//         .where('profileComplete', isEqualTo: true)
//         .orderBy('fullName')
//         .snapshots()
//         .map((snapshot) => snapshot.docs
//             .map((doc) => ContactModel.fromFirestore(doc))
//             .toList());
//   }

//   /// Search contacts by name, email, or roll number
//   Future<List<ContactModel>> searchContacts(String query) async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'student')
//           .where('profileComplete', isEqualTo: true)
//           .get();

//       return querySnapshot.docs
//           .map((doc) => ContactModel.fromFirestore(doc))
//           .where((contact) {
//             final searchQuery = query.toLowerCase();
//             return contact.fullName.toLowerCase().contains(searchQuery) ||
//                    contact.email.toLowerCase().contains(searchQuery) ||
//                    (contact.rollNumber?.toLowerCase().contains(searchQuery) ?? false);
//           })
//           .toList();
//     } catch (e) {
//       throw Exception('Failed to search contacts: $e');
//     }
//   }

//   /// Get contact by user ID
//   Future<ContactModel?> getContactById(String userId) async {
//     try {
//       final doc = await _firestore.collection('users').doc(userId).get();
//       if (doc.exists) {
//         return ContactModel.fromFirestore(doc);
//       }
//       return null;
//     } catch (e) {
//       throw Exception('Failed to get contact: $e');
//     }
//   }

//   /// Get all departments
//   Future<List<String>> getDepartments() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'student')
//           .where('profileComplete', isEqualTo: true)
//           .get();

//       final departments = querySnapshot.docs
//           .map((doc) => doc.data()['department'] as String? ?? '')
//           .where((dept) => dept.isNotEmpty)
//           .toSet()
//           .toList();

//       departments.sort();
//       return departments;
//     } catch (e) {
//       throw Exception('Failed to get departments: $e');
//     }
//   }

//   /// Get contact statistics
//   Future<Map<String, int>> getContactStatistics() async {
//     try {
//       final querySnapshot = await _firestore
//           .collection('users')
//           .where('role', isEqualTo: 'student')
//           .get();

//       final allContacts = querySnapshot.docs;
//       final departmentCount = <String, int>{};
//       int verifiedCount = 0;
//       int completeProfiles = 0;

//       for (final doc in allContacts) {
//         final data = doc.data();
//         final department = data['department'] as String? ?? 'Unknown';
//         departmentCount[department] = (departmentCount[department] ?? 0) + 1;

//         if (data['isEmailVerified'] == true) verifiedCount++;
//         if (data['profileComplete'] == true) completeProfiles++;
//       }

//       return {
//         'total': allContacts.length,
//         'verified': verifiedCount,
//         'complete_profiles': completeProfiles,
//         'departments': departmentCount.length,
//         ...departmentCount,
//       };
//     } catch (e) {
//       throw Exception('Failed to get contact statistics: $e');
//     }
//   }

//   /// Admin functions - Add/Update/Delete contacts (if needed)
//   Future<void> updateContactInfo(String userId, Map<String, dynamic> data) async {
//     try {
//       await _firestore.collection('users').doc(userId).update(data);
//     } catch (e) {
//       throw Exception('Failed to update contact: $e');
//     }
//   }

//   Future<void> deleteContact(String userId) async {
//     try {
//       await _firestore.collection('users').doc(userId).delete();
//     } catch (e) {
//       throw Exception('Failed to delete contact: $e');
//     }
//   }

//   /// Batch operations
//   Future<void> updateMultipleContacts(List<String> userIds, Map<String, dynamic> updates) async {
//     try {
//       final batch = _firestore.batch();
      
//       for (final userId in userIds) {
//         final docRef = _firestore.collection('users').doc(userId);
//         batch.update(docRef, updates);
//       }
      
//       await batch.commit();
//     } catch (e) {
//       throw Exception('Failed to update multiple contacts: $e');
//     }
//   }
// }
