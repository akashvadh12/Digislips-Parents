// app/modules/notification/notification_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:digislips/app/modules/auth/models/user_model.dart';
import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

enum NotificationType {
  leaveApproved,
  leaveRejected,
  leavePending,
  leaveSubmitted,
  profileUpdate,
  general,
  newLeaveRequest, // For teachers/admin
  leaveStatusChanged, // For parents/students
  systemAlert,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedLeaveId;
  final String? relatedStudentId;
  final String? relatedStudentName;
  final Color backgroundColor;
  final IconData icon;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.relatedLeaveId,
    this.relatedStudentId,
    this.relatedStudentName,
    required this.backgroundColor,
    required this.icon,
  });

  // Factory method to create from LeaveModel
  factory NotificationModel.fromLeaveModel(LeaveModel leave) {
    String title;
    String message;
    NotificationType type;
    Color backgroundColor;
    IconData icon;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        title = 'Leave Approved';
        message = 'Your ${leave.leaveType} leave request has been approved';
        type = NotificationType.leaveApproved;
        backgroundColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        title = 'Leave Rejected';
        message = 'Your ${leave.leaveType} leave request has been rejected';
        type = NotificationType.leaveRejected;
        backgroundColor = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        break;
      case 'pending':
        title = 'Leave Pending';
        message = 'Your ${leave.leaveType} leave request is pending approval';
        type = NotificationType.leavePending;
        backgroundColor = Colors.orange;
        icon = Icons.pending;
        break;
      default:
        title = 'Leave Submitted';
        message = 'Your ${leave.leaveType} leave request has been submitted';
        type = NotificationType.leaveSubmitted;
        backgroundColor = Colors.blue;
        icon = Icons.send;
    }

    return NotificationModel(
      id: leave.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  // Factory method for teacher/admin notifications about new leave requests
  factory NotificationModel.newLeaveRequest(LeaveModel leave) {
    return NotificationModel(
      id: 'new_leave_${leave.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New Leave Request',
      message: '${leave.fullName} submitted a ${leave.leaveType} leave request',
      type: NotificationType.newLeaveRequest,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: Colors.blue,
      icon: Icons.new_releases,
    );
  }

  // Factory method for parent notifications about their child's leave status
  factory NotificationModel.parentLeaveUpdate(LeaveModel leave) {
    String title;
    String message;
    Color backgroundColor;
    IconData icon;

    switch (leave.status.toLowerCase()) {
      case 'approved':
        title = 'Child\'s Leave Approved';
        message = '${leave.fullName}\'s ${leave.leaveType} leave has been approved';
        backgroundColor = const Color(0xFF4CAF50);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        title = 'Child\'s Leave Rejected';
        message = '${leave.fullName}\'s ${leave.leaveType} leave has been rejected';
        backgroundColor = const Color(0xFFD32F2F);
        icon = Icons.cancel;
        break;
      default:
        title = 'Child\'s Leave Update';
        message = '${leave.fullName}\'s ${leave.leaveType} leave status updated to ${leave.status}';
        backgroundColor = Colors.orange;
        icon = Icons.update;
    }

    return NotificationModel(
      id: 'parent_${leave.id}_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      type: NotificationType.leaveStatusChanged,
      timestamp: leave.submittedAt,
      relatedLeaveId: leave.id,
      relatedStudentId: leave.uid,
      relatedStudentName: leave.fullName,
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  // Factory method for profile updates
  factory NotificationModel.profileUpdate(String message, {String? studentName}) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: studentName != null ? '${studentName}\'s Profile Updated' : 'Profile Updated',
      message: message,
      type: NotificationType.profileUpdate,
      timestamp: DateTime.now(),
      backgroundColor: Colors.indigo,
      icon: Icons.person,
    );
  }

  // Factory method for general notifications
  factory NotificationModel.general(String title, String message) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: NotificationType.general,
      timestamp: DateTime.now(),
      backgroundColor: Colors.grey,
      icon: Icons.info,
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class NotificationController extends GetxController {
  var isLoading = true.obs;
  var isRefreshing = false.obs;
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var student = Rxn<Student>();
  var parentStudentData = Rxn<Map<String, dynamic>>();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // User role variables
  var userRole = ''.obs;
  var isParent = false.obs;
  var isTeacher = false.obs;
  var userEmail = ''.obs;
  var uid = ''.obs;

  // Stream subscriptions
  StreamSubscription? _leaveSubscription;
  StreamSubscription? _profileSubscription;
  StreamSubscription? _allStudentsLeaveSubscription;

  @override
  void onInit() {
    super.onInit();
    initializeNotifications();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    _profileSubscription?.cancel();
    _allStudentsLeaveSubscription?.cancel();
    super.onClose();
  }

  // Initialize notifications based on user role
  Future<void> initializeNotifications() async {
    try {
      isLoading.value = true;
      await _getUserDetailsFromPrefs();
      
      if (uid.value.isEmpty) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Initialize based on role
      if (userRole.value == 'parent' || isParent.value) {
        await _initializeParentNotifications();
      } else if (userRole.value == 'teacher' || isTeacher.value) {
        await _initializeTeacherNotifications();
      } else {
        await _initializeStudentNotifications();
      }
    } catch (e) {
      print('❌ Error initializing notifications: $e');
      Get.snackbar(
        'Error',
        'Failed to load notifications: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Get user details from SharedPreferences
  Future<void> _getUserDetailsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      uid.value = prefs.getString('uid') ?? '';
      userRole.value = prefs.getString('userRole') ?? '';
      isParent.value = prefs.getBool('isParent') ?? false;
      isTeacher.value = prefs.getBool('isTeacher') ?? false;
      userEmail.value = prefs.getString('Email') ?? '';

      print('👤 Notification Controller - User Role: ${userRole.value}');
      print('👤 Notification Controller - Is Parent: ${isParent.value}');
      print('👤 Notification Controller - Is Teacher: ${isTeacher.value}');
    } catch (e) {
      print('❌ Error getting user details from prefs: $e');
    }
  }

  // Initialize parent-specific notifications
  Future<void> _initializeParentNotifications() async {
    print('👨‍👩‍👧‍👦 Initializing parent notifications...');

    // Find student data using parent email
    final studentData = await _verifyParentEmailInStudents(userEmail.value);
    
    if (studentData != null) {
      parentStudentData.value = studentData;
      student.value = Student.fromMap(studentData);

      // Setup leave notifications for parent's child
      _setupParentLeaveNotifications(studentData['studentId']);
      
      // Setup profile notifications for parent's child
      _setupParentProfileNotifications(studentData['studentId']);
    } else {
      Get.snackbar(
        'Error',
        'No student found with your parent email.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Initialize teacher-specific notifications
  Future<void> _initializeTeacherNotifications() async {
    print('👨‍💼 Initializing teacher notifications...');
    
    await _fetchCurrentUserData();
    
    // Setup notifications for all students' leave requests
    _setupTeacherLeaveNotifications();
    
    // Setup profile notifications for teacher
    _setupProfileNotifications(uid.value);
  }

  // Initialize student-specific notifications
  Future<void> _initializeStudentNotifications() async {
    print('👨‍🎓 Initializing student notifications...');
    
    await _fetchCurrentUserData();
    
    // Setup leave notifications for student's own leaves
    _setupStudentLeaveNotifications(uid.value);
    
    // Setup profile notifications for student
    _setupProfileNotifications(uid.value);
  }

  // Verify parent email in students collection
  Future<Map<String, dynamic>?> _verifyParentEmailInStudents(String parentEmail) async {
    try {
      final querySnapshot = await _firestore
          .collection('students')
          .where('parentEmail', isEqualTo: parentEmail.trim().toLowerCase())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final studentData = querySnapshot.docs.first.data();
        studentData['studentId'] = querySnapshot.docs.first.id;
        return studentData;
      }
      return null;
    } catch (e) {
      print('❌ Error verifying parent email: $e');
      return null;
    }
  }

  // Fetch current user data
  Future<void> _fetchCurrentUserData() async {
    try {
      DocumentSnapshot? userDoc;

      // Try teachers first
      userDoc = await _firestore.collection('teachers').doc(uid.value).get();

      if (!userDoc.exists) {
        // Try students
        userDoc = await _firestore.collection('students').doc(uid.value).get();
      }

      if (userDoc.exists) {
        student.value = Student.fromMap(userDoc.data() as Map<String, dynamic>);
      }
    } catch (e) {
      print('❌ Error fetching user data: $e');
    }
  }

  // Setup leave notifications for parent's child
  void _setupParentLeaveNotifications(String studentId) {
    try {
      _leaveSubscription?.cancel();

      _leaveSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final List<NotificationModel> leaveNotifications = [];

              for (var leaveDoc in snapshot.docs) {
                final leave = LeaveModel.fromFirestore(leaveDoc).copyWith(
                  id: leaveDoc.id,
                  uid: studentId,
                  fullName: parentStudentData.value?['fullName'],
                );

                // Create parent-specific notification
                leaveNotifications.add(NotificationModel.parentLeaveUpdate(leave));
              }

              _updateLeaveNotifications(leaveNotifications);
            },
            onError: (error) {
              print('❌ Error in parent leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up parent leave notifications: $e');
    }
  }

  // Setup leave notifications for student's own leaves
  void _setupStudentLeaveNotifications(String studentId) {
    try {
      _leaveSubscription?.cancel();

      _leaveSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .collection('leave')
          .orderBy('submittedAt', descending: true)
          .snapshots()
          .listen(
            (snapshot) {
              final List<NotificationModel> leaveNotifications = [];

              for (var leaveDoc in snapshot.docs) {
                final leave = LeaveModel.fromFirestore(leaveDoc).copyWith(
                  id: leaveDoc.id,
                  uid: studentId,
                );

                // Create student notification
                leaveNotifications.add(NotificationModel.fromLeaveModel(leave));
              }

              _updateLeaveNotifications(leaveNotifications);
            },
            onError: (error) {
              print('❌ Error in student leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up student leave notifications: $e');
    }
  }

  // Setup leave notifications for teacher (all students)
  void _setupTeacherLeaveNotifications() {
    try {
      _allStudentsLeaveSubscription?.cancel();

      _allStudentsLeaveSubscription = _firestore
          .collection('students')
          .where("department", isEqualTo: "CS")
          .snapshots()
          .asyncMap((studentSnapshot) async {
            List<NotificationModel> allNotifications = [];

            for (var studentDoc in studentSnapshot.docs) {
              try {
                var leaveSnapshot = await studentDoc.reference
                    .collection('leave')
                    .orderBy('submittedAt', descending: true)
                    .limit(10)
                    .get();

                for (var leaveDoc in leaveSnapshot.docs) {
                  final leave = LeaveModel.fromFirestore(leaveDoc).copyWith(
                    id: leaveDoc.id,
                    uid: studentDoc.id,
                    fullName: studentDoc['fullName'],
                    rollNumber: studentDoc['rollNumber'],
                    department: studentDoc['department'],
                  );

                  // Create teacher notification for new leave requests
                  allNotifications.add(NotificationModel.newLeaveRequest(leave));
                }
              } catch (e) {
                print('❌ Error processing student ${studentDoc.id}: $e');
              }
            }

            return allNotifications;
          })
          .listen(
            (allNotifications) {
              _updateLeaveNotifications(allNotifications);
            },
            onError: (error) {
              print('❌ Error in teacher leave notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up teacher leave notifications: $e');
    }
  }

  // Setup profile notifications for parent's child
  void _setupParentProfileNotifications(String studentId) {
    try {
      _profileSubscription?.cancel();

      _profileSubscription = _firestore
          .collection('students')
          .doc(studentId)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (docSnapshot.exists) {
                final newStudentData = docSnapshot.data()!;

                // Check if this is an update (not initial load)
                if (parentStudentData.value != null) {
                  final profileNotification = NotificationModel.profileUpdate(
                    'Your child\'s profile information has been updated',
                    studentName: newStudentData['fullName'],
                  );

                  _addUniqueNotification(profileNotification);
                }

                parentStudentData.value = newStudentData;
                student.value = Student.fromMap(newStudentData);
              }
            },
            onError: (error) {
              print('❌ Error in parent profile notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up parent profile notifications: $e');
    }
  }

  // Setup profile notifications
  void _setupProfileNotifications(String userId) {
    try {
      _profileSubscription?.cancel();

      String collection = isTeacher.value ? 'teachers' : 'students';

      _profileSubscription = _firestore
          .collection(collection)
          .doc(userId)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (docSnapshot.exists) {
                final newStudent = Student.fromMap(docSnapshot.data()!);

                // Check if this is an update (not initial load)
                if (student.value != null) {
                  final profileNotification = NotificationModel.profileUpdate(
                    'Your profile information has been updated successfully',
                  );

                  _addUniqueNotification(profileNotification);
                }

                student.value = newStudent;
              }
            },
            onError: (error) {
              print('❌ Error in profile notifications: $error');
            },
          );
    } catch (e) {
      print('❌ Error setting up profile notifications: $e');
    }
  }

  // Update leave notifications in the main list
  void _updateLeaveNotifications(List<NotificationModel> leaveNotifications) {
    // Remove existing leave notifications
    notifications.removeWhere((notif) => 
      notif.type == NotificationType.leaveApproved ||
      notif.type == NotificationType.leaveRejected ||
      notif.type == NotificationType.leavePending ||
      notif.type == NotificationType.leaveSubmitted ||
      notif.type == NotificationType.newLeaveRequest ||
      notif.type == NotificationType.leaveStatusChanged
    );

    // Add new leave notifications
    notifications.addAll(leaveNotifications);

    // Sort by timestamp (newest first)
    notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _updateUnreadCount();
  }

  // Add unique notification (avoid duplicates)
  void _addUniqueNotification(NotificationModel notification) {
    // Check if similar notification exists in last minute
    final recentSimilar = notifications.any(
      (notif) =>
          notif.type == notification.type &&
          notif.timestamp.isAfter(
            DateTime.now().subtract(const Duration(minutes: 1)),
          ),
    );

    if (!recentSimilar) {
      notifications.insert(0, notification);
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((notif) => !notif.isRead).length;
  }

  // Public methods for managing notifications
  Future<void> refreshNotifications() async {
    isRefreshing.value = true;
    await initializeNotifications();
    isRefreshing.value = false;
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((notif) => notif.id == notificationId);
    if (index != -1 && !notifications[index].isRead) {
      final updatedNotification = NotificationModel(
        id: notifications[index].id,
        title: notifications[index].title,
        message: notifications[index].message,
        type: notifications[index].type,
        timestamp: notifications[index].timestamp,
        isRead: true,
        relatedLeaveId: notifications[index].relatedLeaveId,
        relatedStudentId: notifications[index].relatedStudentId,
        relatedStudentName: notifications[index].relatedStudentName,
        backgroundColor: notifications[index].backgroundColor,
        icon: notifications[index].icon,
      );

      notifications[index] = updatedNotification;
      _updateUnreadCount();
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        final updatedNotification = NotificationModel(
          id: notifications[i].id,
          title: notifications[i].title,
          message: notifications[i].message,
          type: notifications[i].type,
          timestamp: notifications[i].timestamp,
          isRead: true,
          relatedLeaveId: notifications[i].relatedLeaveId,
          relatedStudentId: notifications[i].relatedStudentId,
          relatedStudentName: notifications[i].relatedStudentName,
          backgroundColor: notifications[i].backgroundColor,
          icon: notifications[i].icon,
        );
        notifications[i] = updatedNotification;
      }
    }
    _updateUnreadCount();
  }

  void deleteNotification(String notificationId) {
    notifications.removeWhere((notif) => notif.id == notificationId);
    _updateUnreadCount();
  }

  void clearAllNotifications() {
    notifications.clear();
    unreadCount.value = 0;
  }

  // Add manual notification
  void addNotification(String title, String message, {NotificationType? type}) {
    final notification = NotificationModel.general(title, message);
    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  // Filter methods
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return notifications.where((notif) => notif.type == type).toList();
  }

  List<NotificationModel> getRecentNotifications() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return notifications
        .where((notif) => notif.timestamp.isAfter(weekAgo))
        .toList();
  }

  List<NotificationModel> getLeaveNotifications() {
    return notifications.where((notif) => 
      notif.type == NotificationType.leaveApproved ||
      notif.type == NotificationType.leaveRejected ||
      notif.type == NotificationType.leavePending ||
      notif.type == NotificationType.leaveSubmitted ||
      notif.type == NotificationType.newLeaveRequest ||
      notif.type == NotificationType.leaveStatusChanged
    ).toList();
  }

  // Helper getters
  String get studentName {
    if (isParent.value && parentStudentData.value != null) {
      return parentStudentData.value!['fullName'] ?? 'Student';
    }
    return student.value?.fullName ?? 'User';
  }

  String get currentUserName {
    if (isParent.value) {
      return userEmail.value.split('@')[0];
    }
    return student.value?.fullName ?? userEmail.value.split('@')[0];
  }

  bool get hasNotifications => notifications.isNotEmpty;
  bool get hasUnreadNotifications => unreadCount.value > 0;
  bool get isCurrentUserParent => userRole.value == 'parent' || isParent.value;
  bool get isCurrentUserTeacher => userRole.value == 'teacher' || isTeacher.value;
  
  String get currentUserRole => userRole.value;
  String get currentUserEmail => userEmail.value;
  String get currentUserId => uid.value;

  // Get role-specific welcome message for notifications
  String get notificationWelcomeMessage {
    if (isParent.value) {
      return 'Stay updated with your child\'s activities';
    } else if (isTeacher.value) {
      return 'Manage student notifications and updates';
    } else {
      return 'Stay updated with your activities';
    }
  }

  // Get notification statistics
  Map<String, int> get notificationStats {
    final stats = {
      'total': notifications.length,
      'unread': unreadCount.value,
      'leave': 0,
      'profile': 0,
      'general': 0,
    };

    for (final notif in notifications) {
      switch (notif.type) {
        case NotificationType.leaveApproved:
        case NotificationType.leaveRejected:
        case NotificationType.leavePending:
        case NotificationType.leaveSubmitted:
        case NotificationType.newLeaveRequest:
        case NotificationType.leaveStatusChanged:
          stats['leave'] = stats['leave']! + 1;
          break;
        case NotificationType.profileUpdate:
          stats['profile'] = stats['profile']! + 1;
          break;
        case NotificationType.general:
        case NotificationType.systemAlert:
          stats['general'] = stats['general']! + 1;
          break;
      }
    }

    return stats;
  }
}