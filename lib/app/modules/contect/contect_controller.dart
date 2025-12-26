// controllers/contact_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> allContacts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredContacts =
      <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedDepartment = 'All'.obs;
  final RxString selectedSemester = 'All'.obs;
  final RxString currentUserId = ''.obs;
  final RxString userRole = ''.obs;

  final TextEditingController searchController = TextEditingController();
  final RxList<String> departments = <String>['All'].obs;
  final RxList<String> semesters = <String>['All'].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeUser();
    fetchAllContacts();

    // Listen to search changes
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _filterContacts();
    });
  }

  @override
  void onClose() {
    searchController.dispose();
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
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize user: $e');
    }
  }

  Future<void> fetchAllContacts() async {
    try {
      isLoading.value = true;

      // Step 1: Get teacher's department from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? department = prefs.getString('department');

      if (department == null || department.isEmpty) {
        Get.snackbar('Warning', 'Department not found for current user.');
        return;
      }

      // Step 2: Fetch students filtered by department
      final studentsSnapshot = await _firestore
          .collection('students')
          .where('department', isEqualTo: department)
          .get();

      List<Map<String, dynamic>> contacts = [];
      Set<String> departmentSet = {'All'};
      Set<String> semesterSet = {'All'};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();

        // Extract student contact info
        Map<String, dynamic> contact = {
          'id': doc.id,
          'type': 'student',
          'fullName': data['fullName'] ?? data['name'] ?? 'Unknown',
          'phone': data['phone'] ?? '',
          'parentPhone': data['parentPhone'] ?? '',
          'parentName': data['parentName'] ?? 'Parent',
          'rollNumber': data['rollNumber'] ?? '',
          'department': data['department'] ?? '',
          'semester': data['semester'] ?? '',
          'profileImageUrl':
              data['profileImageUrl'] ?? data['profileUrl'] ?? '',
          'isEmailVerified': data['isEmailVerified'] ?? false,
          'profileComplete': data['profileComplete'] ?? false,
          'createdAt': data['createdAt'],
          'updatedAt': data['updatedAt'],
        };

        contacts.add(contact);

        // Collect unique departments and semesters
        if (contact['department'] != null &&
            contact['department'].toString().isNotEmpty) {
          departmentSet.add(contact['department']);
        }
        if (contact['semester'] != null &&
            contact['semester'].toString().isNotEmpty) {
          semesterSet.add(contact['semester']);
        }

        // Add parent as separate contact if parent phone exists
        if (contact['parentPhone'] != null &&
            contact['parentPhone'].toString().isNotEmpty) {
          Map<String, dynamic> parentContact = {
            'id': '${doc.id}_parent',
            'type': 'parent',
            'fullName':
                '${contact['parentName']} (Parent of ${contact['fullName']})',
            'phone': contact['parentPhone'],
            'parentPhone': '',
            'parentName': '',
            'rollNumber': contact['rollNumber'],
            'department': contact['department'],
            'semester': contact['semester'],
            'profileImageUrl': '',
            'isEmailVerified': false,
            'profileComplete': true,
            'createdAt': contact['createdAt'],
            'updatedAt': contact['updatedAt'],
            'studentName': contact['fullName'],
            'studentPhone': contact['phone'],
          };
          contacts.add(parentContact);
        }
      }

      // Sort contacts alphabetically
      contacts.sort(
        (a, b) => a['fullName'].toString().compareTo(b['fullName'].toString()),
      );

      allContacts.value = contacts;
      filteredContacts.value = contacts;
      departments.value = departmentSet.toList()..sort();
      semesters.value = semesterSet.toList()..sort();
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _filterContacts() {
    List<Map<String, dynamic>> filtered = allContacts.where((contact) {
      final matchesSearch =
          searchQuery.value.isEmpty ||
          contact['fullName'].toString().toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          contact['rollNumber'].toString().toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          ) ||
          contact['department'].toString().toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );

      final matchesDepartment =
          selectedDepartment.value == 'All' ||
          contact['department'] == selectedDepartment.value;

      final matchesSemester =
          selectedSemester.value == 'All' ||
          contact['semester'] == selectedSemester.value;

      return matchesSearch && matchesDepartment && matchesSemester;
    }).toList();

    filteredContacts.value = filtered;
  }

  void setDepartmentFilter(String department) {
    selectedDepartment.value = department;
    _filterContacts();
  }

  void setSemesterFilter(String semester) {
    selectedSemester.value = semester;
    _filterContacts();
  }

  void clearFilters() {
    selectedDepartment.value = 'All';
    selectedSemester.value = 'All';
    searchController.clear();
    searchQuery.value = '';
    _filterContacts();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      Get.snackbar('Error', 'Phone number not available');
      return;
    }

    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        Get.snackbar('Error', 'Cannot make phone call');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to make phone call: $e');
    }
  }

  // Future<void> sendSMS(String phoneNumber) async {
  //   if (phoneNumber.isEmpty) {
  //     Get.snackbar('Error', 'Phone number not available');
  //     return;
  //   }

  //   final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);

  //   try {
  //     if (await canLaunchUrl(smsUri)) {
  //       await launchUrl(smsUri);
  //     } else {
  //       Get.snackbar('Error', 'Cannot send SMS');
  //     }
  //   } catch (e) {
  //     Get.snackbar('Error', 'Failed to send SMS: $e');
  //   }
  // }

  Future<void> refreshContacts() async {
    await fetchAllContacts();
  }

  // Get contacts by type
  List<Map<String, dynamic>> get studentContacts => filteredContacts
      .where((contact) => contact['type'] == 'student')
      .toList();

  List<Map<String, dynamic>> get parentContacts =>
      filteredContacts.where((contact) => contact['type'] == 'parent').toList();

  // Get statistics
  Map<String, int> get contactStats => {
    'totalStudents': allContacts.where((c) => c['type'] == 'student').length,
    'totalParents': allContacts.where((c) => c['type'] == 'parent').length,
    'totalContacts': allContacts.length,
    'filteredContacts': filteredContacts.length,
  };
}
