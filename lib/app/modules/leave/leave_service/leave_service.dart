// app/services/leave_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/dashboard/dashboard_controller.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LeaveService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get leave application by ID for specific student
  Future<LeaveModel?> getLeaveApplicationById(
    String studentId,
    String leaveId,
  ) async {
    try {
      print(
        '🔍 Fetching leave application - Student: $studentId, Leave: $leaveId',
      );
      DocumentSnapshot doc = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId)
          .get();

      if (doc.exists) {
        print('✅ Leave application found');
        return LeaveModel.fromFirestore(doc);
      }
      print('❌ Leave application not found');
      return null;
    } catch (e) {
      print('❌ Error fetching leave application: $e');
      throw Exception('Failed to get leave application: $e');
    }
  }

  // Get all leave applications for a student (works for both single student and all students)
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

              for (var leaveDoc in leaveSnapshot.docs) {
                final leaveModel = LeaveModel.fromFirestore(leaveDoc).copyWith(
                  id: leaveDoc.id, // 🔥 Leave document ID
                  uid: studentDoc.id, // 🔥 Student ID
                  fullName: studentDoc['fullName'],
                  rollNumber: studentDoc['rollNumber'],
                  department: studentDoc['department'],
                );
                allLeaves.add(leaveModel);
              }
            } catch (e) {
              print('❌ Error fetching leaves for student ${studentDoc.id}: $e');
            }
          }

          return allLeaves;
        });
  }

  // New method specifically for admin/teacher role to get all leave applications
  Stream<List<LeaveModel>> getAllLeaveApplicationsForRole() async* {
    print(
      '👨‍💼 Fetching all leave applications for admin/teacher/parent role',
    );
    final HomeController homeController = Get.find<HomeController>();
    print(" this is parent value 😁😁😁${homeController.isParent.value}");
    if (homeController.isParent.value) {
      final studentData = homeController.parentStudentData.value;
      final studentId = studentData?['studentId'];

      if (studentId == null) {
        print('❌ No student ID found for parent');
        yield [];
        return;
      }

      yield* _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .map((snapshot) {
            try {
              final leaves = snapshot.docs.map((doc) {
                return LeaveModel.fromFirestore(doc).copyWith(
                  id: doc.id,
                  uid: studentId,
                  fullName: studentData?['fullName'],
                  rollNumber: studentData?['rollNumber'],
                  department: studentData?['department'],
                  email: studentData?['email'],
                  phone: studentData?['phone'],
                  parentPhone: studentData?['parentPhone'],
                );
              }).toList();

              print('✅ Loaded ${leaves.length} leaves for parent');
              return leaves;
            } catch (e) {
              print('❌ Error mapping leaves: $e');
              Get.snackbar(
                'Error',
                'Failed to process leave data',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
              return <LeaveModel>[];
            }
          });
    } else {
      yield* _firestore
          .collection('students')
          .where("department", isEqualTo: "CS")
          .snapshots()
          .asyncMap((studentSnapshot) async {
            List<LeaveModel> allLeaves = [];

            for (var studentDoc in studentSnapshot.docs) {
              try {
                final leaveSnapshot = await studentDoc.reference
                    .collection('leave')
                    .orderBy('submittedAt', descending: true)
                    .get();

                final studentInfo = studentDoc.data();
                allLeaves.addAll(
                  leaveSnapshot.docs.map((doc) {
                    return LeaveModel.fromFirestore(doc).copyWith(
                      uid: studentDoc.id,
                      fullName: studentInfo['fullName'],
                      rollNumber: studentInfo['rollNumber'],
                      department: studentInfo['department'],
                      email: studentInfo['email'],
                      phone: studentInfo['phone'],
                      parentPhone: studentInfo['parentPhone'],
                    );
                  }),
                );
              } catch (e) {
                print('❌ Error processing student ${studentDoc.id}: $e');
              }
            }

            print('✅ Total applications for admin view: ${allLeaves.length}');
            return allLeaves;
          });
    }
  }

  // Get all pending leave applications with student details
  Stream<List<Map<String, dynamic>>> getPendingLeaveApplications() {
    print('⏳ Fetching pending leave applications');

    return _firestore
        .collectionGroup('leave')
        .where('status', isEqualTo: 'Pending')
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          print('📋 Found ${snapshot.docs.length} pending applications');

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
                'studentName': studentDoc['fullName'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
              });
            }
          }

          print('✅ Processed ${results.length} pending applications');
          return results;
        });
  }

  // Get all leave applications with student details (original method - keeping for backward compatibility)
  Stream<List<Map<String, dynamic>>> getAllLeaveApplications() {
    print('📋 Fetching all leave applications with student details');

    return _firestore
        .collectionGroup('leave')
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          print('📄 Processing ${snapshot.docs.length} leave documents');

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
                'studentName': studentDoc['fullName'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
              });
            }
          }

          print(
            '✅ Processed ${results.length} applications with student details',
          );
          return results;
        });
  }

  // Updated leave status update method with better error handling and logging
  Future<void> updateLeaveStatus({
    required String studentId,
    required String leaveId,
    required String status,
    required String reviewedBy,
    
    String? reviewComments,
    required String userId,
  }) async {
    try {
      print('🔄 Starting leave status update...');
      print('👤 Student ID: $studentId');
      print('📋 Leave ID: $leaveId');
      print('📊 Status: $status');
      print('👨‍💼 Reviewed by: $reviewedBy');
      print('🆔 User ID (reviewer): $userId');

      // Validate required parameters
      if (studentId.isEmpty) {
        throw Exception('Student ID is required');
      }
      if (leaveId.isEmpty) {
        throw Exception('Leave ID is required');
      }

      final updateData = {
        'status': status,
        'reviewedBy': reviewedBy,
        'reviewedAt': Timestamp.now(),
        if (reviewComments != null && reviewComments.isNotEmpty)
          'reviewComments': reviewComments,
      };

      print('📝 Update data: $updateData');

      // Check if the leave document exists first
      final leaveDocRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId);

      print('🔍 Checking if leave document exists...');
      final docSnapshot = await leaveDocRef.get();

      if (!docSnapshot.exists) {
        print(
          '❌ Leave document not found at path: students/$studentId/leave/$leaveId',
        );
        throw Exception('Leave application not found');
      }

      print('✅ Leave document found, updating...');
      await leaveDocRef.update(updateData);

      print('✅ Leave status updated successfully');
      Get.snackbar(
        'Success',
        'Leave status updated to $status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error updating leave status: $e');
      Get.snackbar(
        'Error',
        'Failed to update leave status: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Delete leave application
  Future<void> deleteLeaveApplication(String studentId, String leaveId) async {
    try {
      print(
        '🗑️ Deleting leave application - Student: $studentId, Leave: $leaveId',
      );

      // Check if the leave document exists first
      final leaveDocRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId);

      final docSnapshot = await leaveDocRef.get();

      if (!docSnapshot.exists) {
        print('❌ Leave document not found for deletion');
        throw Exception('Leave application not found');
      }

      await leaveDocRef.delete();
      print('✅ Leave application deleted successfully');

      Get.snackbar(
        'Success',
        'Leave application deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error deleting leave application: $e');
      Get.snackbar(
        'Error',
        'Failed to delete leave application: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Create new leave application
  Future<String> createLeaveApplication({
    required String studentId,
    required LeaveModel leaveApplication,
  }) async {
    try {
      print('📝 Creating new leave application for student: $studentId');

      final leaveRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc();

      final leaveData = leaveApplication
          .copyWith(
            id: leaveRef.id,
            submittedAt: DateTime.now(),
            status: 'Pending',
          )
          .toFirestore();

      await leaveRef.set(leaveData);
      print('✅ Leave application created with ID: ${leaveRef.id}');

      Get.snackbar(
        'Success',
        'Leave application submitted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );

      return leaveRef.id;
    } catch (e) {
      print('❌ Error creating leave application: $e');
      Get.snackbar(
        'Error',
        'Failed to submit leave application: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Update existing leave application
  Future<void> updateLeaveApplication({
    required String studentId,
    required String leaveId,
    required LeaveModel updatedLeave,
  }) async {
    try {
      print(
        '📝 Updating leave application - Student: $studentId, Leave: $leaveId',
      );

      final leaveDocRef = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .doc(leaveId);

      final docSnapshot = await leaveDocRef.get();

      if (!docSnapshot.exists) {
        print('❌ Leave document not found for update');
        throw Exception('Leave application not found');
      }

      final updateData = updatedLeave.toFirestore();
      updateData['updatedAt'] = Timestamp.now();

      await leaveDocRef.update(updateData);
      print('✅ Leave application updated successfully');

      Get.snackbar(
        'Success',
        'Leave application updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error updating leave application: $e');
      Get.snackbar(
        'Error',
        'Failed to update leave application: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      rethrow;
    }
  }

  // Get leave applications by date range for specific student
  Stream<List<LeaveModel>> getLeaveApplicationsByDateRange({
    required String studentId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    print('📅 Fetching leaves by date range for student: $studentId');

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
    print('📊 Fetching leaves by status ($status) for student: $studentId');

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
      print('📊 Calculating leave statistics for student: $studentId');

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

      print('📄 Processing ${querySnapshot.docs.length} leave records');

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

      print('✅ Statistics calculated: $stats');
      return stats;
    } catch (e) {
      print('❌ Error calculating statistics: $e');
      throw Exception('Failed to get leave statistics: $e');
    }
  }

  // Check for overlapping leave applications
  Future<bool> hasOverlappingLeave({
    required String userId,
    required DateTime fromDate,
    required DateTime toDate,
    String? excludeLeaveId,
    required String studentId,
  }) async {
    try {
      print('🔍 Checking for overlapping leave - Student: $studentId');
      print('📅 Date range: $fromDate to $toDate');

      final querySnapshot = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .where('status', whereIn: ['Pending', 'Approved'])
          .get();

      print('📄 Checking ${querySnapshot.docs.length} existing applications');

      for (var doc in querySnapshot.docs) {
        // Skip the current leave application if updating
        if (excludeLeaveId != null && doc.id == excludeLeaveId) {
          continue;
        }

        final leave = LeaveModel.fromFirestore(doc);

        // Check for overlap
        if (fromDate.isBefore(leave.toDate.add(const Duration(days: 1))) &&
            toDate.isAfter(leave.fromDate.subtract(const Duration(days: 1)))) {
          print('⚠️ Overlapping leave found: ${doc.id}');
          return true;
        }
      }

      print('✅ No overlapping leave found');
      return false;
    } catch (e) {
      print('❌ Error checking overlapping leave: $e');
      throw Exception('Failed to check overlapping leave: $e');
    }
  }

  // Get leave applications for a specific month
  Stream<List<LeaveModel>> getMonthlyLeaveApplications({
    required String studentId,
    required int year,
    required int month,
  }) {
    print(
      '📅 Fetching monthly applications - Student: $studentId, Month: $month/$year',
    );

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
      print('⚠️ No student IDs provided');
      return Stream.value([]);
    }

    print('👥 Fetching applications for ${studentIds.length} students');

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
                  'studentName': studentDoc['fullName'],
                  'studentPhone': studentDoc['phone'],
                  'parentPhone': studentDoc['parentPhone'],
                  'profileUrl': studentDoc['profileUrl'],
                });
              }
            }
          }
          print(
            '✅ Processed ${results.length} applications for specified students',
          );
          return results;
        });
  }

  // Get leave applications by class with student details
  Stream<List<Map<String, dynamic>>> getLeaveApplicationsByClass({
    required String className,
    String? status,
  }) {
    print('🏫 Fetching leave applications for class: $className');

    return _firestore
        .collection('students')
        .where('class', isEqualTo: className)
        .snapshots()
        .asyncMap((studentSnapshot) async {
          List<Map<String, dynamic>> results = [];

          for (var studentDoc in studentSnapshot.docs) {
            try {
              Query leaveQuery = studentDoc.reference.collection('leave');

              if (status != null && status.isNotEmpty) {
                leaveQuery = leaveQuery.where('status', isEqualTo: status);
              }

              final leaveSnapshot = await leaveQuery
                  .orderBy('submittedAt', descending: true)
                  .get();

              for (var leaveDoc in leaveSnapshot.docs) {
                final leave = LeaveModel.fromFirestore(leaveDoc);
                results.add({
                  'leave': leave,
                  'studentId': studentDoc.id,
                  'leaveId': leaveDoc.id,
                  'studentName': studentDoc['fullName'],
                  'studentPhone': studentDoc['phone'],
                  'parentPhone': studentDoc['parentPhone'],
                  'profileUrl': studentDoc['profileUrl'],
                  'rollNumber': studentDoc['rollNumber'],
                  'class': studentDoc['class'],
                });
              }
            } catch (e) {
              print('❌ Error processing student ${studentDoc.id}: $e');
            }
          }

          print(
            '✅ Processed ${results.length} applications for class: $className',
          );
          return results;
        });
  }

  // Get leave applications by department with student details
  Stream<List<Map<String, dynamic>>> getLeaveApplicationsByDepartment({
    required String department,
    String? status,
  }) {
    print('🏢 Fetching leave applications for department: $department');

    return _firestore
        .collection('students')
        .where('department', isEqualTo: department)
        .snapshots()
        .asyncMap((studentSnapshot) async {
          List<Map<String, dynamic>> results = [];

          for (var studentDoc in studentSnapshot.docs) {
            try {
              Query leaveQuery = studentDoc.reference.collection('leave');

              if (status != null && status.isNotEmpty) {
                leaveQuery = leaveQuery.where('status', isEqualTo: status);
              }

              final leaveSnapshot = await leaveQuery
                  .orderBy('submittedAt', descending: true)
                  .get();

              for (var leaveDoc in leaveSnapshot.docs) {
                final leave = LeaveModel.fromFirestore(leaveDoc);
                results.add({
                  'leave': leave,
                  'studentId': studentDoc.id,
                  'leaveId': leaveDoc.id,
                  'studentName': studentDoc['fullName'],
                  'studentPhone': studentDoc['phone'],
                  'parentPhone': studentDoc['parentPhone'],
                  'profileUrl': studentDoc['profileUrl'],
                  'rollNumber': studentDoc['rollNumber'],
                  'department': studentDoc['department'],
                });
              }
            } catch (e) {
              print('❌ Error processing student ${studentDoc.id}: $e');
            }
          }

          print(
            '✅ Processed ${results.length} applications for department: $department',
          );
          return results;
        });
  }

  // Get leave applications count by status for dashboard
  Future<Map<String, int>> getLeaveCountByStatus({
    String? studentId,
    String? className,
    String? department,
  }) async {
    try {
      print('📊 Getting leave count by status');

      Map<String, int> counts = {
        'total': 0,
        'pending': 0,
        'approved': 0,
        'rejected': 0,
      };

      if (studentId != null) {
        // Get counts for specific student
        final snapshot = await _firestore
            .collection('students')
            .doc(studentId)
            .collection('leave')
            .get();

        _updateCounts(counts, snapshot.docs);
      } else {
        // Get counts for all students or filtered by class/department
        Query studentsQuery = _firestore.collection('students');

        if (className != null) {
          studentsQuery = studentsQuery.where('class', isEqualTo: className);
        }
        if (department != null) {
          studentsQuery = studentsQuery.where(
            'department',
            isEqualTo: department,
          );
        }

        final studentsSnapshot = await studentsQuery.get();

        for (var studentDoc in studentsSnapshot.docs) {
          final leaveSnapshot = await studentDoc.reference
              .collection('leave')
              .get();
          _updateCounts(counts, leaveSnapshot.docs);
        }
      }

      print('✅ Leave counts calculated: $counts');
      return counts;
    } catch (e) {
      print('❌ Error getting leave counts: $e');
      throw Exception('Failed to get leave counts: $e');
    }
  }

  void _updateCounts(
    Map<String, int> counts,
    List<QueryDocumentSnapshot> docs,
  ) {
    for (var doc in docs) {
      final leave = LeaveModel.fromFirestore(doc);
      counts['total'] = counts['total']! + 1;

      switch (leave.status.toLowerCase()) {
        case 'pending':
          counts['pending'] = counts['pending']! + 1;
          break;
        case 'approved':
          counts['approved'] = counts['approved']! + 1;
          break;
        case 'rejected':
          counts['rejected'] = counts['rejected']! + 1;
          break;
      }
    }
  }

  // Get recent leave applications (last 30 days)
  Stream<List<Map<String, dynamic>>> getRecentLeaveApplications({
    int days = 30,
    String? department,
  }) {
    print('📅 Fetching recent leave applications (last $days days)');

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    return _firestore
        .collectionGroup('leave')
        .where(
          'submittedAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
        )
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
              // Filter by department if specified
              if (department != null &&
                  studentDoc['department'] != department) {
                continue;
              }

              final leave = LeaveModel.fromFirestore(doc);
              results.add({
                'leave': leave,
                'studentId': studentId,
                'leaveId': doc.id,
                'studentName': studentDoc['fullName'],
                'studentPhone': studentDoc['phone'],
                'parentPhone': studentDoc['parentPhone'],
                'profileUrl': studentDoc['profileUrl'],
                'rollNumber': studentDoc['rollNumber'],
                'department': studentDoc['department'],
              });
            }
          }

          print('✅ Processed ${results.length} recent applications');
          return results;
        });
  }

  // Bulk update leave status (for admin operations)
  Future<void> bulkUpdateLeaveStatus({
    required List<String> leaveIds,
    required List<String> studentIds,
    required String status,
    required String reviewedBy,
    String? reviewComments,
  }) async {
    try {
      print(
        '🔄 Starting bulk status update for ${leaveIds.length} applications',
      );

      final batch = _firestore.batch();

      for (int i = 0; i < leaveIds.length; i++) {
        final leaveRef = _firestore
            .collection('students')
            .doc(studentIds[i])
            .collection('leave')
            .doc(leaveIds[i]);

        batch.update(leaveRef, {
          'status': status,
          'reviewedBy': reviewedBy,
          'reviewedAt': Timestamp.now(),
          if (reviewComments != null && reviewComments.isNotEmpty)
            'reviewComments': reviewComments,
        });
      }

      await batch.commit();
      print('✅ Bulk update completed successfully');

      Get.snackbar(
        'Success',
        '${leaveIds.length} applications updated to $status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print('❌ Error in bulk update: $e');
      Get.snackbar(
        'Error',
        'Failed to update applications: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: Duration(seconds: 3),
      );
      rethrow;
    }
  }
}
