
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceEligibilityModel {
  final String id;
  final String familyId;
  final String assistanceId;
  final String lastAssignmentId;
  final DateTime lastAssignedAt;
  final DateTime nextEligibleAt;

  const AssistanceEligibilityModel({
    required this.id,
    required this.familyId,
    required this.assistanceId,
    required this.lastAssignmentId,
    required this.lastAssignedAt,
    required this.nextEligibleAt,
  });

  factory AssistanceEligibilityModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) {
    final data = doc.data();

    if (data == null) {
      throw StateError(
        'Eligibility document is empty: ${doc.id}',
      );
    }

    return AssistanceEligibilityModel(
      id: doc.id,
      familyId: data['familyId'] as String,
      assistanceId: data['assistanceId'] as String,
      lastAssignmentId:
      data['lastAssignmentId'] as String,
      lastAssignedAt:
      (data['lastAssignedAt'] as Timestamp).toDate(),
      nextEligibleAt:
      (data['nextEligibleAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'assistanceId': assistanceId,
      'lastAssignmentId': lastAssignmentId,
      'lastAssignedAt': Timestamp.fromDate(lastAssignedAt),
      'nextEligibleAt': Timestamp.fromDate(nextEligibleAt),
    };
  }

  bool isEligibleAt(DateTime date) {
    return !date.toUtc().isBefore(
      nextEligibleAt.toUtc(),
    );
  }

  Duration remainingCooldownAt(DateTime date) {
    final remaining = nextEligibleAt.toUtc().difference(
      date.toUtc(),
    );

    return remaining.isNegative ? Duration.zero : remaining;
  }

  AssistanceEligibilityModel copyWith({
    String? id,
    String? familyId,
    String? assistanceId,
    String? lastAssignmentId,
    DateTime? lastAssignedAt,
    DateTime? nextEligibleAt,
  }) {
    return AssistanceEligibilityModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      assistanceId: assistanceId ?? this.assistanceId,
      lastAssignmentId:
      lastAssignmentId ?? this.lastAssignmentId,
      lastAssignedAt:
      lastAssignedAt ?? this.lastAssignedAt,
      nextEligibleAt:
      nextEligibleAt ?? this.nextEligibleAt,
    );
  }
}
