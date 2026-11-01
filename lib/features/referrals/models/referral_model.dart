
enum ReferralStatus {
  pendingSourceApproval,
  rejectedBySource,
  pendingTargetApproval,
  rejectedByTarget,
  accepted,
  inProgress,
  completed,
}

extension ReferralStatusExtension on ReferralStatus {
  String get value {
    switch (this) {
      case ReferralStatus.pendingSourceApproval:
        return 'pending_source_approval';
      case ReferralStatus.rejectedBySource:
        return 'rejected_by_source';
      case ReferralStatus.pendingTargetApproval:
        return 'pending_target_approval';
      case ReferralStatus.rejectedByTarget:
        return 'rejected_by_target';
      case ReferralStatus.accepted:
        return 'accepted';
      case ReferralStatus.inProgress:
        return 'in_progress';
      case ReferralStatus.completed:
        return 'completed';
    }
  }

  String get label {
    switch (this) {
      case ReferralStatus.pendingSourceApproval:
        return 'بانتظار موافقة المشرف';
      case ReferralStatus.rejectedBySource:
        return 'رفضتها المؤسسة المرسلة';
      case ReferralStatus.pendingTargetApproval:
        return 'بانتظار موافقة الجهة المستقبلة';
      case ReferralStatus.rejectedByTarget:
        return 'رفضتها الجهة المستقبلة';
      case ReferralStatus.accepted:
        return 'تم قبول الإحالة';
      case ReferralStatus.inProgress:
        return 'جاري تقديم الخدمة';
      case ReferralStatus.completed:
        return 'تم تقديم الخدمة';
    }
  }

  static ReferralStatus fromValue(String value) {
    for (final status in ReferralStatus.values) {
      if (status.value == value) return status;
    }
    throw ArgumentError('Unknown referral status: $value');
  }
}

class ReferralStep {
  final String title;
  final DateTime at;
  final String actor;

  const ReferralStep({
    required this.title,
    required this.at,
    required this.actor,
  });
}

class ReferralModel {
  // Identity
  final String id;
  final String number;
  final String? assignedTo;
  final DateTime? assignedAt;

  // Organizations
  final String sourceOrganizationId;
  final String targetOrganizationId;
  final String sourceOrganizationName;
  final String targetOrganizationName;

  // Family
  final String sourceFamilyId;
  final String familyName;
  final int membersCount;
  final String contactPhone;
  final String address;
  final String areaId;

  // Service
  final String targetServiceId;
  final String serviceName;
  final String reason;

  // Status
  final ReferralStatus status;

  // Creation
  final String createdBy;
  final DateTime createdAt;

  // Source organization approval
  final String? sourceApprovedBy;
  final DateTime? sourceApprovedAt;

  // Target organization decision
  final String? targetReviewedBy;
  final DateTime? targetReviewedAt;

  // Rejection
  final String? rejectionReason;

  // Received family relationship
  final String? receivedFamilyId;

  // Service delivery
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completedBy;
  final String? result;
  final String? resultNote;

  // Family sharing confirmation
  final bool sharingConfirmed;
  final DateTime? sharingConfirmedAt;

  // Last update
  final DateTime updatedAt;

  const ReferralModel({
    required this.id,
    required this.number,
    required this.sourceOrganizationId,
    required this.targetOrganizationId,
    required this.sourceOrganizationName,
    required this.targetOrganizationName,
    required this.sourceFamilyId,
    required this.familyName,
    required this.membersCount,
    required this.contactPhone,
    required this.address,
    required this.areaId,
    required this.targetServiceId,
    required this.serviceName,
    required this.reason,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.sourceApprovedBy,
    this.sourceApprovedAt,
    this.targetReviewedBy,
    this.targetReviewedAt,
    this.rejectionReason,
    this.receivedFamilyId,
    this.startedAt,
    this.completedAt,
    this.completedBy,
    this.result,
    this.resultNote,
    required this.sharingConfirmed,
    this.sharingConfirmedAt,
  });

  // Compatibility with existing UI widgets
  String get fromOrg => sourceOrganizationName;
  String get toOrg => targetOrganizationName;
  String get service => serviceName;
  String get area => areaId;

  bool get isWaitingSourceApproval =>
      status == ReferralStatus.pendingSourceApproval;

  bool get isWaitingTargetApproval =>
      status == ReferralStatus.pendingTargetApproval;

  bool get isRejected =>
      status == ReferralStatus.rejectedBySource ||
          status == ReferralStatus.rejectedByTarget;

  bool get isCompleted =>
      status == ReferralStatus.completed;

  List<ReferralStep> get steps {
    final items = <ReferralStep>[
      ReferralStep(
        title: 'تم إنشاء طلب الإحالة',
        at: createdAt,
        actor: createdBy,
      ),
    ];

    if (sourceApprovedAt != null) {
      items.add(ReferralStep(
        title: 'تم اعتماد الإرسال',
        at: sourceApprovedAt!,
        actor: sourceApprovedBy ?? '-',
      ));
    }

    if (targetReviewedAt != null) {
      items.add(ReferralStep(
        title: status == ReferralStatus.rejectedByTarget
            ? 'رُفضت الإحالة'
            : 'تم اتخاذ قرار بشأن الإحالة',
        at: targetReviewedAt!,
        actor: targetReviewedBy ?? '-',
      ));
    }

    if (startedAt != null) {
      items.add(ReferralStep(
        title: 'بدأ تقديم الخدمة',
        at: startedAt!,
        actor: targetOrganizationName,
      ));
    }

    if (completedAt != null) {
      items.add(ReferralStep(
        title: 'تم تقديم الخدمة',
        at: completedAt!,
        actor: completedBy ?? '-',
      ));
    }

    items.sort((a, b) => a.at.compareTo(b.at));
    return items;
  }

  ReferralModel copyWith({
    ReferralStatus? status,
    String? receivedFamilyId,
    String? sourceApprovedBy,
    DateTime? sourceApprovedAt,
    String? targetReviewedBy,
    DateTime? targetReviewedAt,
    String? rejectionReason,
    DateTime? startedAt,
    DateTime? completedAt,
    String? completedBy,
    String? result,
    String? resultNote,
    DateTime? updatedAt,
  }) {
    return ReferralModel(
      id: id,
      number: number,
      sourceOrganizationId: sourceOrganizationId,
      targetOrganizationId: targetOrganizationId,
      sourceOrganizationName: sourceOrganizationName,
      targetOrganizationName: targetOrganizationName,
      sourceFamilyId: sourceFamilyId,
      familyName: familyName,
      membersCount: membersCount,
      contactPhone: contactPhone,
      address: address,
      areaId: areaId,
      targetServiceId: targetServiceId,
      serviceName: serviceName,
      reason: reason,
      status: status ?? this.status,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sourceApprovedBy:
      sourceApprovedBy ?? this.sourceApprovedBy,
      sourceApprovedAt:
      sourceApprovedAt ?? this.sourceApprovedAt,
      targetReviewedBy:
      targetReviewedBy ?? this.targetReviewedBy,
      targetReviewedAt:
      targetReviewedAt ?? this.targetReviewedAt,
      rejectionReason:
      rejectionReason ?? this.rejectionReason,
      receivedFamilyId:
      receivedFamilyId ?? this.receivedFamilyId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      result: result ?? this.result,
      resultNote: resultNote ?? this.resultNote,
      sharingConfirmed: sharingConfirmed,
      sharingConfirmedAt: sharingConfirmedAt,
    );
  }
}
