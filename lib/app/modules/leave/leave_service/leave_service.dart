// app/services/leave_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get leave application by ID for specific student
  Future<LeaveModel?> getLeaveApplicationById(
    String studentId,
    String leaveId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId)
          .get();

      if (doc.exists) {
        return LeaveModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get leave application: $e');
    }
  }

  // Get all leave applications for a student
  Stream<List<LeaveModel>> getStudentLeaveApplications(String studentId) {
    return _firestore
        .collection('students')
        .where("department", isEqualTo: "CS")
        .snapshots()
        .asyncMap((studentSnapshot) async {
          List<LeaveModel> allLeaves = [];

          for (var studentDoc in studentSnapshot.docs) {
            try {
              var leaveSnapshot = await studentDoc.reference
                  .collection('leave')
                  .get();

              // Only process if student has leaves
              if (leaveSnapshot.docs.isNotEmpty) {
                allLeaves.addAll(
                  leaveSnapshot.docs.map((leaveDoc) {
                    return LeaveModel.fromFirestore(leaveDoc).copyWith(
                      uid: studentDoc.id,
                      fullName: studentDoc['fullName'],
                      rollNumber: studentDoc['rollNumber'],
                      department: studentDoc['department'],
                    );
                  }).toList(),
                );
              }
            } catch (e) {
              print('Error fetching leaves for student ${studentDoc.id}: $e');
            }
          }

          return allLeaves;
        });
  }

  // Get all pending leave applications with student details
  Stream<List<Map<String, dynamic>>> getPendingLeaveApplications() {
    return _firestore
        .collectionGroup('leave')
        .where('status', isEqualTo: 'Pending')
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final studentId = doc.reference.parent.parent!.id;
            final studentDoc = await _firestore
                .collection('students')
                .doc(studentId)
                .get();

            if (studentDoc.exists) {
              final leave = LeaveModel.fromFirestore(doc);
              results.add({
                'leave': leave,
                'studentId': studentId,
                'leaveId': doc.id,
                'studentName': studentDoc['name'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
              });
            }
          }
          return results;
        });
  }

  // Get all leave applications with student details
  Stream<List<Map<String, dynamic>>> getAllLeaveApplications() {
    return _firestore
        .collectionGroup('leave')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final studentId = doc.reference.parent.parent!.id;
            final studentDoc = await _firestore
                .collection('students')
                .doc(studentId)
                .get();

            if (studentDoc.exists) {
              final leave = LeaveModel.fromFirestore(doc);
              results.add({
                'leave': leave,
                'studentId': studentId,
                'leaveId': doc.id,
                'studentName': studentDoc['name'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
              });
            }
          }
          return results;
        });
  }

  // Update leave application status
  Future<void> updateLeaveStatus({
    required String studentId,
    required String leaveId,
    required String status,
    required String reviewedBy,
    String? reviewComments,
    required String userId,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
      };

      if (reviewComments != null && reviewComments.isNotEmpty) {
        updateData['reviewComments'] = reviewComments;
      }

      await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update leave status: $e');
    }
  }

  // Get leave applications by date range for specific student
  Stream<List<LeaveModel>> getLeaveApplicationsByDateRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('leave')
        .where(
          'fromDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        )
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('fromDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get leave applications by status for specific student
  Stream<List<LeaveModel>> getLeaveApplicationsByStatus({
    required String studentId,
    required String status,
  }) {
    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('leave')
        .where('status', isEqualTo: status)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get leave statistics for a student
  Future<Map<String, int>> getLeaveStatistics(String studentId) async {
    try {
      final currentYear = DateTime.now().year;
      final startOfYear = DateTime(currentYear, 1, 1);
      final endOfYear = DateTime(currentYear, 12, 31);

      final querySnapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .where(
            'fromDate',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfYear),
          )
          .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfYear))
          .get();

      Map<String, int> stats = {
        'total': 0,
        'approved': 0,
        'pending': 0,
        'rejected': 0,
        'totalDays': 0,
        'approvedDays': 0,
      };

      for (var doc in querySnapshot.docs) {
        final leave = LeaveModel.fromFirestore(doc);
        stats['total'] = stats['total']! + 1;
        stats['totalDays'] = stats['totalDays']! + leave.totalDays;

        switch (leave.status.toLowerCase()) {
          case 'approved':
            stats['approved'] = stats['approved']! + 1;
            stats['approvedDays'] = stats['approvedDays']! + leave.totalDays;
            break;
          case 'pending':
            stats['pending'] = stats['pending']! + 1;
            break;
          case 'rejected':
            stats['rejected'] = stats['rejected']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to get leave statistics: $e');
    }
  }

  // Check for overlapping leave applications
  Future<bool> hasOverlappingLeave({
    required String studentId,
    required DateTime fromDate,
    required DateTime toDate,
    String? excludeLeaveId,
    required String userId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .where('status', whereIn: ['Pending', 'Approved'])
          .get();

      for (var doc in querySnapshot.docs) {
        // Skip the current leave application if updating
        if (excludeLeaveId != null && doc.id == excludeLeaveId) {
          continue;
        }

        final leave = LeaveModel.fromFirestore(doc);

        // Check for overlap
        if (fromDate.isBefore(leave.toDate.add(const Duration(days: 1))) &&
            toDate.isAfter(leave.fromDate.subtract(const Duration(days: 1)))) {
          return true;
        }
      }

      return false;
    } catch (e) {
      throw Exception('Failed to check overlapping leave: $e');
    }
  }

  // Get leave applications for a specific month
  Stream<List<LeaveModel>> getMonthlyLeaveApplications({
    required String studentId,
    required int year,
    required int month,
  }) {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0);

    return _firestore
        .collection('students')
        .doc(studentId)
        .collection('leave')
        .where(
          'fromDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
        )
        .where('fromDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
        .orderBy('fromDate', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LeaveModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Get leave applications for multiple students with student details
  Stream<List<Map<String, dynamic>>> getLeaveApplicationsForStudents(
    List<String> studentIds,
  ) {
    if (studentIds.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collectionGroup('leave')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final studentId = doc.reference.parent.parent!.id;
            if (studentIds.contains(studentId)) {
              final studentDoc = await _firestore
                  .collection('students')
                  .doc(studentId)
                  .get();
              if (studentDoc.exists) {
                final leave = LeaveModel.fromFirestore(doc);
                results.add({
                  'leave': leave,
                  'studentId': studentId,
                  'leaveId': doc.id,
                  'studentName': studentDoc['name'],
                  'studentPhone': studentDoc['phone'],
                  'parentPhone': studentDoc['parentPhone'],
                  'profileUrl': studentDoc['profileUrl'],
                });
              }
            }
          }
          return results;
        });
  }

  // Get leave applications by class with student details
  Stream<List<Map<String, dynamic>>> getLeaveApplicationsByClass({
    required String className,
  }) {
    return _firestore
        .collectionGroup('leave')
        .where('className', isEqualTo: className)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            final studentId = doc.reference.parent.parent!.id;
            final studentDoc = await _firestore
                .collection('students')
                .doc(studentId)
                .get();

            if (studentDoc.exists) {
              final leave = LeaveModel.fromFirestore(doc);
              results.add({
                'leave': leave,
                'studentId': studentId,
                'leaveId': doc.id,
                'studentName': studentDoc['name'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
              });
            }
          }
          return results;
        });
  }
}
