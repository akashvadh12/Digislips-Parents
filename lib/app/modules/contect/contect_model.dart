class ContactModel {
  final String id;
  final String name;
  final String role;
  final String department;
  final String phone;
  final String email;
  final String imageUrl;
  final bool isOnline;
  final List<String> visibleToRoles;
  final DateTime createdAt;

  ContactModel({
    required this.id,
    required this.name,
    required this.role,
    required this.department,
    required this.phone,
    required this.email,
    required this.imageUrl,
    required this.isOnline,
    required this.visibleToRoles,
    required this.createdAt,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      department: json['department'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isOnline: json['isOnline'] ?? false,
      visibleToRoles: List<String>.from(json['visibleToRoles'] ?? []),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'department': department,
      'phone': phone,
      'email': email,
      'imageUrl': imageUrl,
      'isOnline': isOnline,
      'visibleToRoles': visibleToRoles,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
class ContectModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'teacher' or 'parent'
  final String imageUrl;

  ContectModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
  });

  factory ContectModel.fromJson(Map<String, dynamic> json) {
    return ContectModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
// models/user_model.dart

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'teacher' or 'parent'
  final String imageUrl;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.imageUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
    );
  }
}
