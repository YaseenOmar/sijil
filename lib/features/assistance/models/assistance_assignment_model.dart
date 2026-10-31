
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceAssignmentModel {
  static const String statusAssigned = 'assigned';
  static const String statusDelivered = 'delivered';
  static const String statusCancelled = 'cancelled';

  final String id;
  final String assistanceId;
  final String familyId;
  final String areaId;
  final String assignedBy;
  final DateTime assignedAt;
  final DateTime nextEligibleAt;
  final String status;
  final String notes;

  const AssistanceAssignmentModel({
    required this.id,
    required this.assistanceId,
    required this.familyId,
    required this.areaId,
    required this.assignedBy,
    required this.assignedAt,
    required this.nextEligibleAt,
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

    return AssistanceAssignmentModel(
      id: doc.id,
      assistanceId: data['assistanceId'] as String,
      familyId: data['familyId'] as String,
      areaId: data['areaId'] as String,
      assignedBy: data['assignedBy'] as String,
      assignedAt:
      (data['assignedAt'] as Timestamp).toDate(),
      nextEligibleAt:
      (data['nextEligibleAt'] as Timestamp).toDate(),
      status: data['status'] as String? ?? statusAssigned,
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'assistanceId': assistanceId,
      'familyId': familyId,
      'areaId': areaId,
      'assignedBy': assignedBy,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'nextEligibleAt': Timestamp.fromDate(nextEligibleAt),
      'status': status,
      'notes': notes,
    };
  }

  bool get isAssigned => status == statusAssigned;

  bool get isDelivered => status == statusDelivered;

  bool get isCancelled => status == statusCancelled;

  AssistanceAssignmentModel copyWith({
    String? id,
    String? assistanceId,
    String? familyId,
    String? areaId,
    String? assignedBy,
    DateTime? assignedAt,
    DateTime? nextEligibleAt,
    String? status,
    String? notes,
  }) {
    return AssistanceAssignmentModel(
      id: id ?? this.id,
      assistanceId: assistanceId ?? this.assistanceId,
      familyId: familyId ?? this.familyId,
      areaId: areaId ?? this.areaId,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedAt: assignedAt ?? this.assignedAt,
      nextEligibleAt: nextEligibleAt ?? this.nextEligibleAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}
