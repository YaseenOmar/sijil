import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String areaId;
  final String organizationId;
  final String createdBy;
  final String status;
  final DateTime createdAt;

  EmployeeModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.areaId,
    required this.organizationId,
    required this.createdBy,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'areaId': areaId,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map) {
    return EmployeeModel(
      id: map['id'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      areaId: map['areaId'] ?? '',
      organizationId: map['organizationId'] ?? '',
      createdBy: map['createdBy'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate()
          ?? DateTime.now(),
    );
  }
}
