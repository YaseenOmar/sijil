
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceAssignmentModel {
  static const String statusAssigned = 'assigned';
  static const String statusDelivered = 'delivered';
  static const String statusCanceled = 'canceled';

  final String id;
  final String organizationId;
  final String serviceId;
  final String familyId;
  final String areaId;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime? nextEligibleAt;
  final String status;
  final String notes;

  const AssistanceAssignmentModel({
    required this.id,
    required this.organizationId,
    required this.serviceId,
    required this.familyId,
    required this.areaId,
    required this.assignedBy,
    required this.assignedAt,
    this.nextEligibleAt,
    this.status = statusAssigned,
    this.notes = '',
  });

  factory AssistanceAssignmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    if (data == null) {
      throw StateError(
        'Assignment document is empty: ${doc.id}',
      );
    }

    final assignedAtValue = data['assignedAt'];

    if (assignedAtValue is! Timestamp) {
      throw StateError(
        'Invalid assignedAt for assignment: ${doc.id}',
      );
    }

    final nextEligibleAtValue = data['nextEligibleAt'];

    return AssistanceAssignmentModel(
      id: doc.id,
      organizationId:
      data['organizationId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      familyId: data['familyId'] as String? ?? '',
      areaId: data['areaId'] as String? ?? '',
      assignedBy: data['assignedBy'] as String? ?? '',
      assignedAt: assignedAtValue.toDate(),
      nextEligibleAt: nextEligibleAtValue is Timestamp
          ? nextEligibleAtValue.toDate()
          : null,
      status: data['status'] as String? ??
          statusAssigned,
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'organizationId': organizationId,
      'serviceId': serviceId,
      'familyId': familyId,
      'areaId': areaId,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'nextEligibleAt': nextEligibleAt == null
          ? null
          : Timestamp.fromDate(nextEligibleAt!),
      'status': status,
      'notes': notes,
    };
  }

  bool get isAssigned => status == statusAssigned;

  bool get isDelivered => status == statusDelivered;

  bool get isCanceled => status == statusCanceled;

  bool get hasCooldown => nextEligibleAt != null;

  bool isWithinCooldownAt(DateTime date) {
    final nextDate = nextEligibleAt;

    if (nextDate == null || isCanceled) {
      return false;
    }

    return date.toUtc().isBefore(
      nextDate.toUtc(),
    );
  }

  Duration remainingCooldownAt(DateTime date) {
    if (!isWithinCooldownAt(date)) {
      return Duration.zero;
    }

    return nextEligibleAt!.toUtc().difference(
      date.toUtc(),
    );
  }

  AssistanceAssignmentModel copyWith({
    String? id,
    String? organizationId,
    String? serviceId,
    String? familyId,
    String? areaId,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? nextEligibleAt,
    bool clearNextEligibleAt = false,
    String? status,
    String? notes,
  }) {
    return AssistanceAssignmentModel(
      id: id ?? this.id,
      organizationId:
      organizationId ?? this.organizationId,
      serviceId: serviceId ?? this.serviceId,
      familyId: familyId ?? this.familyId,
      areaId: areaId ?? this.areaId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      nextEligibleAt: clearNextEligibleAt
          ? null
          : (nextEligibleAt ?? this.nextEligibleAt),
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
