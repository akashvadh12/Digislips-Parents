import 'dart:async';

import 'package:digislips/app/modules/leave/leave_model/leave_model.dart';
import 'package:digislips/app/modules/leave/leave_service/leave_service.dart';
import 'package:digislips/app/shared/widgets/Custom_Snackbar/Custom_Snackbar.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveHistoryController extends GetxController {
  final LeaveService _leaveService = LeaveService();
  final RxList<LeaveModel> leaveRequests = <LeaveModel>[].obs;
  final RxList<LeaveModel> allLeaveRequests = <LeaveModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentUserId = ''.obs;
  final RxString userRole = ''.obs;
  final RxString selectedMonth = 'All'.obs;
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString searchQuery = ''.obs;

  StreamSubscription<List<LeaveModel>>? _leaveSubscription;

  List<String> get months => [
    'All',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
  }

  @override
  void onClose() {
    _leaveSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString('uid');
      final role = prefs.getString('userRole') ?? 'student';

      if (uid != null && uid.isNotEmpty) {
        currentUserId.value = uid;
        userRole.value = role;
        print('🔥 [LeaveHistory] Initialized user - ID: $uid, Role: $role');
        _listenToLeaveRequests();
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      print('❌ [LeaveHistory] Error initializing user: $e');
      isLoading.value = false;
      CustomSnackbar.showError('Error', 'Failed to initialize user: $e');
    }
  }

  void _listenToLeaveRequests() {
    if (currentUserId.value.isEmpty) return;

    print(
      '🔍 [LeaveHistory] Listening to leave requests for role: ${userRole.value}',
    );
    isLoading.value = true;

    _leaveSubscription?.cancel();

    Stream<List<LeaveModel>> leaveStream;

    if (userRole.value == 'Parent' ||
        userRole.value == 'teacher' ||
        userRole.value == 'admin') {
      // For parents, get only their child's data
      if (userRole.value == 'Parent') {
        print(
          '👨‍👩‍👧‍👦 [LeaveHistory] Fetching parent\'s child leave applications',
        );
        leaveStream = _leaveService.getAllLeaveApplicationsForRole();
      } else {
        print(
          '👨‍💼 [LeaveHistory] Fetching all leave applications for admin/teacher',
        );
        leaveStream = _leaveService.getAllLeaveApplicationsForRole();
      }
    } else {
      print(
        '👨‍🎓 [LeaveHistory] Fetching student leave applications for: ${currentUserId.value}',
      );
      leaveStream = _leaveService.getStudentLeaveApplications(
        currentUserId.value,
      );
    }

    _leaveSubscription = leaveStream.listen(
      (leaves) {
        // Filter only approved leaves from current year (based on submission date)
        final currentYear = DateTime.now().year;
        final approvedLeaves = leaves
            .where(
              (leave) =>
                  leave.status.toLowerCase() == 'approved' &&
                  leave.submittedAt.year == currentYear,
            )
            .toList();

        // Sort leaves by submission date (newest first)
        approvedLeaves.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
        allLeaveRequests.value = approvedLeaves;
        _applyFilters();
        print(
          '✅ [LeaveHistory] Successfully fetched ${approvedLeaves.length} approved leave requests submitted in $currentYear out of ${leaves.length} total',
        );
        isLoading.value = false;
      },
      onError: (error) {
        print('❌ [LeaveHistory] Error fetching leave requests: $error');
        isLoading.value = false;
        CustomSnackbar.showError(
          'Error',
          'Failed to fetch leave requests: $error',
        );
      },
    );
  }

  void _applyFilters() {
    var filtered = List<LeaveModel>.from(allLeaveRequests);

    // Filter by search query (name)
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (leave) =>
                leave.fullName != null &&
                leave.fullName!.toLowerCase().contains(
                  searchQuery.value.toLowerCase(),
                ),
          )
          .toList();
    }

    // Filter by month
    if (selectedMonth.value != 'All') {
      final monthIndex = months.indexOf(selectedMonth.value);
      filtered = filtered
          .where((leave) => leave.submittedAt.month == monthIndex)
          .toList();
    }

    // Filter by date range
    if (startDate.value != null && endDate.value != null) {
      filtered = filtered
          .where(
            (leave) =>
                leave.submittedAt.isAfter(startDate.value!) &&
                leave.submittedAt.isBefore(
                  endDate.value!.add(Duration(days: 1)),
                ),
          )
          .toList();
    }

    leaveRequests.value = filtered;
    leaveRequests.refresh();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
    _applyFilters();
  }

  void setMonth(String month) {
    selectedMonth.value = month;
    searchQuery.value = '';
    startDate.value = null;
    endDate.value = null;
    _applyFilters();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    selectedMonth.value = 'All';
    _applyFilters();
  }

  void clearFilters() {
    selectedMonth.value = 'All';
    startDate.value = null;
    endDate.value = null;
    _applyFilters();
  }

  Future<void> refreshLeaveRequests() async {
    _listenToLeaveRequests();
  }
}
