// screens/contact_screen.dart
import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/core/theme/app_text_styles.dart';

import 'package:digislips/app/modules/contect/contect_controller.dart'
    show ContactController;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ContactController controller = Get.put(ContactController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: controller.refreshContacts,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_filters') {
                controller.clearFilters();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_filters',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Filters'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(controller),
          _buildStatistics(controller),
          Expanded(child: _buildContactList(controller)),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(ContactController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller.searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts, roll number, department...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.greyColor,
                ),
                suffixIcon: Obx(
                  () => controller.searchQuery.value.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            controller.searchController.clear();
                          },
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.greyColor,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips
          Row(children: [Expanded(child: _buildFilterChips(controller))]),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ContactController controller) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Department Filter
          // Obx(
          //   () => _buildFilterChip(
          //     'Department',
          //     controller.selectedDepartment.value,
          //     controller.departments,
          //     controller.setDepartmentFilter,
          //   ),
          // ),
          const SizedBox(width: 12),

          // Semester Filter
          Obx(
            () => _buildFilterChip(
              'Semester',
              controller.selectedSemester.value,
              controller.semesters,
              controller.setSemesterFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String selectedValue,
    RxList<String> options,
    Function(String) onSelected,
  ) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selectedValue == 'All'
              ? Colors.white.withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $selectedValue',
              style: TextStyle(
                color: selectedValue == 'All'
                    ? Colors.white
                    : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: selectedValue == 'All' ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => options
          .map((option) => PopupMenuItem(value: option, child: Text(option)))
          .toList(),
    );
  }

  Widget _buildStatistics(ContactController controller) {
    return Obx(() {
      final stats = controller.contactStats;
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildStatItem(
              'Students',
              stats['totalStudents']!,
              Icons.school,
              AppColors.primary,
            ),
            _buildStatDivider(),
            _buildStatItem(
              'Parents',
              stats['totalParents']!,
              Icons.family_restroom,
              AppColors.success,
            ),
            _buildStatDivider(),
            _buildStatItem(
              'Showing',
              stats['filteredContacts']!,
              Icons.filter_list,
              AppColors.warning,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.borderColor,
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildContactList(ContactController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.filteredContacts.isEmpty) {
        return _buildEmptyState(controller);
      }

      return RefreshIndicator(
        onRefresh: controller.refreshContacts,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.filteredContacts.length,
          itemBuilder: (context, index) {
            final contact = controller.filteredContacts[index];
            return _buildContactCard(contact, controller);
          },
        ),
      );
    });
  }

  Widget _buildEmptyState(ContactController controller) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.greyColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              Icons.contacts,
              size: 64,
              color: AppColors.greyColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No contacts found',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              color: AppColors.greyColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.searchQuery.value.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'No contacts available at the moment',
            style: AppTextStyles.body.copyWith(color: AppColors.greyColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (controller.searchQuery.value.isNotEmpty ||
              controller.selectedDepartment.value != 'All' ||
              controller.selectedSemester.value != 'All')
            ElevatedButton.icon(
              onPressed: controller.clearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    Map<String, dynamic> contact,
    ContactController controller,
  ) {
    final isParent = contact['type'] == 'parent';
    final hasPhone =
        contact['phone'] != null && contact['phone'].toString().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isParent
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                image:
                    contact['profileImageUrl'] != null &&
                        contact['profileImageUrl'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(contact['profileImageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  contact['profileImageUrl'] == null ||
                      contact['profileImageUrl'].toString().isEmpty
                  ? Icon(
                      isParent ? Icons.family_restroom : Icons.person,
                      color: isParent ? AppColors.success : AppColors.primary,
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // Contact Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    contact['fullName'] ?? 'Unknown',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Role Badge
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isParent
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isParent ? 'Parent' : 'Student',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isParent ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Additional Info
                  if (contact['rollNumber'] != null &&
                      contact['rollNumber'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.badge, size: 14, color: AppColors.greyColor),
                        const SizedBox(width: 4),
                        Text(
                          'Roll: ${contact['rollNumber']}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],

                  if (contact['department'] != null &&
                      contact['department'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.school,
                          size: 14,
                          color: AppColors.greyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${contact['department']}${contact['semester'] != null && contact['semester'].toString().isNotEmpty ? ' - Sem ${contact['semester']}' : ''}',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ],

                  if (isParent && contact['studentName'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 14,
                          color: AppColors.greyColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Student: ${contact['studentName']}',
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            if (hasPhone) ...[
              const SizedBox(width: 12),
              Column(
                children: [
                  // Call Button
                  Material(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () => controller.makePhoneCall(contact['phone']),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          Icons.phone,
                          color: AppColors.success,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                  // const SizedBox(height: 8),

                  // SMS Button
                  // Material(
                  //   color: AppColors.primary.withOpacity(0.1),
                  //   borderRadius: BorderRadius.circular(12),
                  //   child: InkWell(
                  //     onTap: () => controller.sendSMS(contact['phone']),
                  //     borderRadius: BorderRadius.circular(12),
                  //     child: Container(
                  //       padding: const EdgeInsets.all(12),
                  //       child: Icon(
                  //         Icons.sms,
                  //         color: AppColors.primary,
                  //         size: 20,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
