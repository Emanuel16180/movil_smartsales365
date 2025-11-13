// lib/models/user_model.dart

class UserModel {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String role;
  final String? phoneNumber;
  final String? address;
  final String fullName;

  UserModel({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    required this.role,
    this.phoneNumber,
    this.address,
    required this.fullName,
  });

  // Factory para crear un UserModel desde el JSON de tu API
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
      role: json['role'] ?? 'CUSTOMER',
      phoneNumber: json['phone_number'],
      address: json['address'],
      fullName: json['full_name'] ?? '',
    );
  }
}