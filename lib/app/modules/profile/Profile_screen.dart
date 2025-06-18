import 'package:digislips/app/core/theme/app_colors.dart';
import 'package:digislips/app/modules/profile/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileScreen extends StatelessWidget {
  final ProfileController controller = Get.put(ProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.all(8.0), child: _buildHeader()),

            Expanded(
              child: Container(
                height: double.infinity,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.student.value == null) {
                      return _buildLoadingState();
                    }

                    if (controller.hasError.value &&
                        controller.student.value == null) {
                      return _buildErrorState();
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(8),
                      child: controller.isEditingProfile.value
                          ? _buildEditForm()
                          : _buildProfileView(),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            strokeWidth: 3,
          ),
          SizedBox(height: 24),
          Text(
            'Loading profile...',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Failed to load profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              controller.errorMessage.value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: controller.refreshProfile,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Obx(
          () => Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (controller.isEditingProfile.value) {
                    controller.cancelEditing();
                  } else {
                    Get.back();
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    controller.isEditingProfile.value
                        ? Icons.close
                        : Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      controller.isEditingProfile.value
                          ? 'Edit Profile'
                          : 'My Profile',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (!controller.isEditingProfile.value &&
                        controller.student.value != null)
                      Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          controller.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (controller.isEditingProfile.value)
                GestureDetector(
                  onTap: controller.isLoading.value
                      ? null
                      : controller.saveProfileChanges,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        controller.isLoading.value ? 0.1 : 0.2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: controller.isLoading.value
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(Icons.check, color: Colors.white, size: 20),
                  ),
                )
              else
                GestureDetector(
                  onTap: controller.student.value != null
                      ? controller.startEditingProfile
                      : null,
                  child: Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(
                        controller.student.value != null ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: Colors.white.withOpacity(
                        controller.student.value != null ? 1.0 : 0.5,
                      ),
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileView() {
    return Column(
      children: [
        // Personal & Contact Information Card
        _buildInfoCard(
          title: 'Personal & Contact Information',
          
          icon: Icons.person_outline,
          children: [
            _buildInfoRow(
              Icons.person_outline,
              'Full Name',
              controller.fullName,
              AppColors.primary,
            ),
            _buildInfoRow(
              Icons.email_outlined,
              'Email',
              controller.email,
              AppColors.secondary,
            ),
            _buildInfoRow(
              Icons.phone_outlined,
              'Phone',
              controller.phone,
              AppColors.success,
            ),
            _buildDivider(),
            _buildSectionHeader('Parent Contact'),
            _buildInfoRow(
              Icons.phone_outlined,
              'Parent Phone',
              controller.parentPhone,
              AppColors.success,
            ),
            _buildInfoRow(
              Icons.email_outlined,
              'Parent Email',
              controller.parentEmail,
              AppColors.secondary,
            ),
          ],
        ),

        SizedBox(height: 20),

        // Academic Information Card
        _buildInfoCard(
          title: 'Academic Information',
          icon: Icons.school_outlined,
          children: [
            _buildInfoRow(
              Icons.school_outlined,
              'Department',
              controller.department,
              AppColors.primary,
            ),
            _buildInfoRow(
              Icons.badge_outlined,
              'Roll Number',
              controller.studentId,
              AppColors.warning,
            ),
            _buildInfoRow(
              Icons.calendar_today_outlined,
              'Semester',
              controller.semester,
              AppColors.pendingColor,
            ),
          ],
        ),

        SizedBox(height: 20),

        // Quick Actions Card
        _buildActionsCard(),
      ],
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // Personal & Contact Information Edit Card
        _buildEditCard(
          title: 'Personal & Contact Information',
          icon: Icons.person_outline,
          children: [
            _buildEditField(
              'Full Name',
              controller.fullNameController,
              Icons.person_outline,
              AppColors.primary,
            ),
            SizedBox(height: 16),
            _buildReadOnlyField(
              'Email',
              controller.email,
              Icons.email_outlined,
              AppColors.secondary,
            ),
            SizedBox(height: 16),
            _buildEditField(
              'Phone',
              controller.phoneController,
              Icons.phone_outlined,
              AppColors.success,
              TextInputType.phone,
            ),
            SizedBox(height: 20),
            _buildSectionHeader('Parent Contact'),
            SizedBox(height: 12),
            _buildEditField(
              'Parent Phone',
              controller.parentPhoneController,
              Icons.phone_outlined,
              AppColors.success,
              TextInputType.phone,
            ),
            SizedBox(height: 16),
            _buildEditField(
              'Parent Email',
              controller.parentEmailController,
              Icons.email_outlined,
              AppColors.secondary,
              TextInputType.emailAddress,
            ),
          ],
        ),

        SizedBox(height: 20),

        // Academic Information Edit Card
        _buildEditCard(
          title: 'Academic Information',
          icon: Icons.school_outlined,
          children: [
            _buildEditField(
              'Department',
              controller.departmentController,
              Icons.school_outlined,
              AppColors.primary,
            ),
            SizedBox(height: 16),
            _buildSemesterDropdown(),
            SizedBox(height: 16),
            _buildReadOnlyField(
              'Roll Number',
              controller.studentId,
              Icons.badge_outlined,
              AppColors.warning,
            ),
          ],
        ),

        SizedBox(height: 32),
        _buildEditActions(),
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 7),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildEditCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Divider(
        color: AppColors.borderColor.withOpacity(0.5),
        thickness: 1,
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.blackColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.settings_outlined,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blackColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.edit_outlined,
            label: 'Edit Profile',
            onTap: controller.student.value != null
                ? controller.startEditingProfile
                : () {},
            color: AppColors.primary,
          ),
          // SizedBox(height: 12),
          // _buildActionButton(
          //   icon: Icons.lock_outline,
          //   label: 'Change Password',
          //   onTap: controller.changePassword,
          //   color: AppColors.secondary,
          // ),
          SizedBox(height: 12),
          _buildActionButton(
            icon: Icons.logout_outlined,
            label: 'Logout',
            onTap: controller.logout,
            color: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController textController,
    IconData icon,
    Color iconColor, [
    TextInputType? keyboardType,
  ]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderColor, width: 1.5),
          ),
          child: TextField(
            controller: textController,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              prefixIcon: Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintText: 'Enter $label',
              hintStyle: TextStyle(
                color: AppColors.textGrey,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.lightGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.borderColor.withOpacity(0.5),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSemesterDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semester',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.blackColor,
          ),
        ),
        SizedBox(height: 8),
        Obx(
          () => Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor, width: 1.5),
            ),
            child: DropdownButtonFormField<String>(
              value: controller.selectedSemester.value,
              decoration: InputDecoration(
                prefixIcon: Container(
                  margin: EdgeInsets.all(12),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.pendingColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.pendingColor,
                    size: 18,
                  ),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.blackColor,
              ),
              items: controller.availableSemesters.map((semester) {
                return DropdownMenuItem<String>(
                  value: semester,
                  child: Text(semester),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedSemester.value = value;
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: controller.isLoading.value
                ? null
                : controller.saveProfileChanges,
            icon: controller.isLoading.value
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.save_outlined, size: 20),
            label: Text(
              controller.isLoading.value ? 'Saving...' : 'Save Changes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: controller.cancelEditing,
            icon: Icon(Icons.cancel_outlined, size: 20),
            label: Text(
              'Cancel',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textGrey,
              side: BorderSide(color: AppColors.borderColor, width: 1.5),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            Spacer(),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
