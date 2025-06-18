import 'package:digislips/app/modules/contect/contect_model.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  var contacts = <ContactModel>[].obs;
  var filteredContacts = <ContactModel>[].obs;
  var isLoading = true.obs;
  var currentUser = Rxn<UserModel>();
  var searchQuery = ''.obs;
  var selectedDepartment = ''.obs;
  var departments = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentUser();
    loadContacts();
  }

  Future<void> loadCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          currentUser.value = UserModel.fromJson({
            'id': user.uid,
            ...userDoc.data()!,
          });
        }
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: $e');
    }
  }

  Future<void> loadContacts() async {
    try {
      isLoading.value = true;
      
      final querySnapshot = await _firestore
          .collection('contacts')
          .orderBy('department')
          .orderBy('name')
          .get();

      contacts.value = querySnapshot.docs
          .map((doc) => ContactModel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .where((contact) => 
              currentUser.value != null && 
              contact.visibleToRoles.contains(currentUser.value!.role))
          .toList();

      // Extract unique departments
      departments.value = contacts
          .map((contact) => contact.department)
          .toSet()
          .toList()
        ..sort();

      filterContacts();
    } catch (e) {
      Get.snackbar('Error', 'Failed to load contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void filterContacts() {
    filteredContacts.value = contacts.where((contact) {
      final matchesSearch = searchQuery.value.isEmpty ||
          contact.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          contact.role.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          contact.department.toLowerCase().contains(searchQuery.value.toLowerCase());

      final matchesDepartment = selectedDepartment.value.isEmpty ||
          contact.department == selectedDepartment.value;

      return matchesSearch && matchesDepartment;
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
    filterContacts();
  }

  void updateDepartmentFilter(String department) {
    selectedDepartment.value = department;
    filterContacts();
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Cannot make phone call');
    }
  }

  Future<void> sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('Error', 'Cannot send email');
    }
  }

  Future<void> refreshContacts() async {
    await loadContacts();
  }
}
