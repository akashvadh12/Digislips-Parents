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
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedLeaveId;
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
      backgroundColor: backgroundColor,
      icon: icon,
    );
  }

  // Factory method for profile updates
  factory NotificationModel.profileUpdate(String message) {
    return NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Profile Updated',
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaveService _leaveService = LeaveService();

  // Stream subscriptions
  StreamSubscription? _leaveSubscription;
  StreamSubscription? _profileSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    _profileSubscription?.cancel();
    super.onClose();
  }

  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;

      // Get UID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');

      if (uid == null) {
        Get.snackbar(
          'Error',
          'User not found. Please login again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      // Fetch student data first
      await _fetchStudentData(uid);

      // Fetch leave-related notifications
      // _fetchLeaveNotifications(uid);

      // Fetch profile-related notifications
      _fetchProfileNotifications(uid);
    } catch (e) {
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

  Future<void> _fetchStudentData(String uid) async {
    try {
      final docSnapshot = await _firestore
          .collection('students')
          .doc(uid)
          .get();

      if (docSnapshot.exists) {
        student.value = Student.fromMap(docSnapshot.data()!);
      }
    } catch (e) {
      print('Error fetching student data: $e');
    }
  }

  // void _fetchLeaveNotifications(String uid) {
  //   try {
  //     // Cancel previous subscription if exists
  //     _leaveSubscription?.cancel();

  //     // Listen to user's leave applications for notifications
  //     _leaveSubscription = _leaveService
  //         .getUserLeaveApplications(uid)
  //         .listen(
  //           (leaveModels) {
  //             // Convert LeaveModel to NotificationModel
  //             final leaveNotifications = leaveModels
  //                 .map((leave) => NotificationModel.fromLeaveModel(leave))
  //                 .toList();

  //             // Update notifications list (replace leave notifications)
  //             notifications.removeWhere((notif) =>
  //               notif.type == NotificationType.leaveApproved ||
  //               notif.type == NotificationType.leaveRejected ||
  //               notif.type == NotificationType.leavePending ||
  //               notif.type == NotificationType.leaveSubmitted
  //             );

  //             notifications.addAll(leaveNotifications);

  //             // Sort by timestamp (newest first)
  //             notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  //             // Update unread count
  //             _updateUnreadCount();
  //           },
  //           onError: (error) {
  //             print('Error fetching leave notifications: $error');
  //             Get.snackbar(
  //               'Error',
  //               'Failed to load leave notifications: $error',
  //               snackPosition: SnackPosition.BOTTOM,
  //               backgroundColor: Colors.red,
  //               colorText: Colors.white,
  //             );
  //           },
  //         );
  //   } catch (e) {
  //     print('Error setting up leave notifications stream: $e');
  //   }
  // }

  void _fetchProfileNotifications(String uid) {
    try {
      // Cancel previous subscription if exists
      _profileSubscription?.cancel();

      // Listen to student profile changes
      _profileSubscription = _firestore
          .collection('students')
          .doc(uid)
          .snapshots()
          .listen(
            (docSnapshot) {
              if (docSnapshot.exists) {
                final newStudent = Student.fromMap(docSnapshot.data()!);

                // Check if this is an update (not initial load)
                if (student.value != null) {
                  // Add profile update notification
                  final profileNotification = NotificationModel.profileUpdate(
                    'Your profile information has been updated successfully',
                  );

                  // Add to notifications if not already present
                  if (!notifications.any(
                    (notif) =>
                        notif.type == NotificationType.profileUpdate &&
                        notif.timestamp.isAfter(
                          DateTime.now().subtract(const Duration(minutes: 1)),
                        ),
                  )) {
                    notifications.insert(0, profileNotification);
                    _updateUnreadCount();
                  }
                }

                student.value = newStudent;
              }
            },
            onError: (error) {
              print('Error fetching profile notifications: $error');
            },
          );
    } catch (e) {
      print('Error setting up profile notifications stream: $e');
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((notif) => !notif.isRead).length;
  }

  Future<void> refreshNotifications() async {
    isRefreshing.value = true;
    await fetchNotifications();
    isRefreshing.value = false;
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere(
      (notif) => notif.id == notificationId,
    );
    if (index != -1 && !notifications[index].isRead) {
      // Create a new notification with isRead = true
      final updatedNotification = NotificationModel(
        id: notifications[index].id,
        title: notifications[index].title,
        message: notifications[index].message,
        type: notifications[index].type,
        timestamp: notifications[index].timestamp,
        isRead: true,
        relatedLeaveId: notifications[index].relatedLeaveId,
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

  // Add manual notification (for testing or other purposes)
  void addNotification(String title, String message, {NotificationType? type}) {
    final notification = NotificationModel.general(title, message);
    notifications.insert(0, notification);
    _updateUnreadCount();
  }

  // Filter notifications by type
  List<NotificationModel> getNotificationsByType(NotificationType type) {
    return notifications.where((notif) => notif.type == type).toList();
  }

  // Get recent notifications (last 7 days)
  List<NotificationModel> getRecentNotifications() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return notifications
        .where((notif) => notif.timestamp.isAfter(weekAgo))
        .toList();
  }

  // Helper getters
  String get studentName => student.value?.fullName ?? 'Student';
  bool get hasNotifications => notifications.isNotEmpty;
  bool get hasUnreadNotifications => unreadCount.value > 0;
}
