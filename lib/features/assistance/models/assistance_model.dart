
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int cooldownDays;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AssistanceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.cooldownDays,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(cooldownDays >= 0);

  factory AssistanceModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    if (data == null) {
      throw StateError('Assistance document is empty: ${doc.id}');
    }

    return AssistanceModel(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String? ?? '',
      category: data['category'] as String,
      cooldownDays: (data['cooldownDays'] as num).toInt(),
      isActive: data['isActive'] as bool? ?? true,
      createdBy: data['createdBy'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'cooldownDays': cooldownDays,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  AssistanceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    int? cooldownDays,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AssistanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      cooldownDays: cooldownDays ?? this.cooldownDays,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
