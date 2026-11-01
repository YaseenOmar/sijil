
import 'package:cloud_firestore/cloud_firestore.dart';

class AssistanceEligibilityModel {
  final String id;
  final String familyId;
  final String serviceId;
  final String lastAssignmentId;
  final DateTime lastAssignedAt;
  final DateTime nextEligibleAt;

  const AssistanceEligibilityModel({
    required this.id,
    required this.familyId,
    required this.serviceId,
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

    final lastAssignedAtValue =
    data['lastAssignedAt'];

    final nextEligibleAtValue =
    data['nextEligibleAt'];

    if (lastAssignedAtValue is! Timestamp ||
        nextEligibleAtValue is! Timestamp) {
      throw StateError(
        'Invalid eligibility dates: ${doc.id}',
      );
    }

    return AssistanceEligibilityModel(
      id: doc.id,
      familyId: data['familyId'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      lastAssignmentId:
      data['lastAssignmentId'] as String? ?? '',
      lastAssignedAt:
      lastAssignedAtValue.toDate(),
      nextEligibleAt:
      nextEligibleAtValue.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'serviceId': serviceId,
      'lastAssignmentId': lastAssignmentId,
      'lastAssignedAt':
      Timestamp.fromDate(lastAssignedAt),
      'nextEligibleAt':
      Timestamp.fromDate(nextEligibleAt),
    };
  }

  bool isEligibleAt(DateTime date) {
    return !date.toUtc().isBefore(
      nextEligibleAt.toUtc(),
    );
  }

  bool isWithinCooldownAt(DateTime date) {
    return !isEligibleAt(date);
  }

  Duration remainingCooldownAt(DateTime date) {
    final remaining =
    nextEligibleAt.toUtc().difference(
      date.toUtc(),
    );

    return remaining.isNegative
        ? Duration.zero
        : remaining;
  }

  int remainingDaysAt(DateTime date) {
    final remaining = remainingCooldownAt(date);

    if (remaining == Duration.zero) {
      return 0;
    }

    return (remaining.inSeconds / 86400).ceil();
  }

  AssistanceEligibilityModel copyWith({
    String? id,
    String? familyId,
    String? serviceId,
    String? lastAssignmentId,
    DateTime? lastAssignedAt,
    DateTime? nextEligibleAt,
  }) {
    return AssistanceEligibilityModel(
      id: id ?? this.id,
      familyId: familyId ?? this.familyId,
      serviceId: serviceId ?? this.serviceId,
      lastAssignmentId:
      lastAssignmentId ?? this.lastAssignmentId,
      lastAssignedAt:
      lastAssignedAt ?? this.lastAssignedAt,
      nextEligibleAt:
      nextEligibleAt ?? this.nextEligibleAt,
    );
  }
}
