
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;

  // Basic information
  final String name;
  final String description;
  final String category;
  final String unit;

  // Availability settings
  final bool isActive;

  // Referral settings
  final bool acceptsReferrals;

  // Cooldown settings
  final bool hasCooldown;
  final int cooldownDays;
  final String? cooldownReason;

  // Organization relationships
  final String organizationId;
  final String createdBy;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.unit,
    this.isActive = true,
    required this.acceptsReferrals,
    required this.hasCooldown,
    this.cooldownDays = 0,
    this.cooldownReason,
    required this.organizationId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert model to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'unit': unit,
      'isActive': isActive,
      'acceptsReferrals': acceptsReferrals,
      'hasCooldown': hasCooldown,
      'cooldownDays': hasCooldown ? cooldownDays : 0,
      'cooldownReason':
      hasCooldown ? cooldownReason : null,
      'organizationId': organizationId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Create model from Firestore map
  factory ServiceModel.fromMap(
      Map<String, dynamic> map, {
        required String id,
      }) {
    return ServiceModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      acceptsReferrals:
      map['acceptsReferrals'] as bool? ?? false,
      hasCooldown:
      map['hasCooldown'] as bool? ?? false,
      cooldownDays:
      (map['cooldownDays'] as num?)?.toInt() ?? 0,
      cooldownReason: map['cooldownReason'] as String?,
      organizationId:
      map['organizationId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      updatedAt:
      (map['updatedAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
    );
  }

  // Create a copy with updated values
  ServiceModel copyWith({
    String? name,
    String? description,
    String? category,
    String? unit,
    bool? isActive,
    bool? acceptsReferrals,
    bool? hasCooldown,
    int? cooldownDays,
    String? cooldownReason,
    bool clearCooldownReason = false,
    DateTime? updatedAt,
  }) {
    final newHasCooldown = hasCooldown ?? this.hasCooldown;

    return ServiceModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      isActive: isActive ?? this.isActive,
      acceptsReferrals:
      acceptsReferrals ?? this.acceptsReferrals,
      hasCooldown: newHasCooldown,
      cooldownDays: newHasCooldown
          ? (cooldownDays ?? this.cooldownDays)
          : 0,
      cooldownReason: !newHasCooldown || clearCooldownReason
          ? null
          : (cooldownReason ?? this.cooldownReason),
      organizationId: organizationId,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
