// Referral lifecycle (a referral goes from our device to another organization)
enum ReferralStatus {
  pendingSend, // saved on the device, not sent yet
  sent, // sent, not confirmed by the receiving organization
  received, // receiving organization confirmed the receipt
  underReview, // accepted and being reviewed
  completed, // service delivered
  rejected, // receiving organization rejected it
}

extension ReferralStatusLabel on ReferralStatus {
  String get label {
    switch (this) {
      case ReferralStatus.pendingSend:
        return 'بانتظار الإرسال · على الجهاز';
      case ReferralStatus.sent:
        return 'أُرسلت';
      case ReferralStatus.received:
        return 'استُلمت';
      case ReferralStatus.underReview:
        return 'قيد المراجعة';
      case ReferralStatus.completed:
        return 'تم تقديم الخدمة';
      case ReferralStatus.rejected:
        return 'مرفوضة';
    }
  }
}

// One step in the referral timeline
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

// The model does not depend directly on Firebase
class ReferralModel {
  final String id;
  final String number;
  final String familyName;
  final int membersCount;
  final String fromOrg;
  final String toOrg;
  final String service;
  final String reason;
  final String area;
  final String contactPhone;
  final ReferralStatus status;

  // Dates and who did each step
  final DateTime createdAt;
  final DateTime? sentAt;
  final String? sentBy;
  final DateTime? receivedAt;
  final String? receivedBy;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime? notifiedAt;

  // Result of the service / reason of rejection
  final String? result;
  final String? resultNote;
  final String? rejectReason;

  const ReferralModel({
    required this.id,
    required this.number,
    required this.familyName,
    required this.membersCount,
    required this.fromOrg,
    required this.toOrg,
    required this.service,
    required this.reason,
    required this.area,
    required this.contactPhone,
    required this.status,
    required this.createdAt,
    this.sentAt,
    this.sentBy,
    this.receivedAt,
    this.receivedBy,
    this.reviewedAt,
    this.reviewedBy,
    this.completedAt,
    this.completedBy,
    this.notifiedAt,
    this.result,
    this.resultNote,
    this.rejectReason,
  });

  // Steps that already happened, in order
  List<ReferralStep> get steps {
    final List<ReferralStep> items = [];

    if (sentAt != null) {
      items.add(
        ReferralStep(title: 'أرسلت', at: sentAt!, actor: sentBy ?? '-'),
      );
    }
    if (receivedAt != null) {
      items.add(
        ReferralStep(
          title: 'استلمت',
          at: receivedAt!,
          actor: receivedBy ?? '-',
        ),
      );
    }
    if (reviewedAt != null) {
      items.add(
        ReferralStep(
          title: status == ReferralStatus.rejected ? 'رُفضت' : 'قيد المراجعة',
          at: reviewedAt!,
          actor: reviewedBy ?? '-',
        ),
      );
    }
    if (completedAt != null) {
      items.add(
        ReferralStep(
          title: 'تم تقديم الخدمة',
          at: completedAt!,
          actor: completedBy ?? '-',
        ),
      );
    }

    return items;
  }

  // Used when the receiving organization decides
  ReferralModel copyWith({
    ReferralStatus? status,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? rejectReason,
  }) {
    return ReferralModel(
      id: id,
      number: number,
      familyName: familyName,
      membersCount: membersCount,
      fromOrg: fromOrg,
      toOrg: toOrg,
      service: service,
      reason: reason,
      area: area,
      contactPhone: contactPhone,
      status: status ?? this.status,
      createdAt: createdAt,
      sentAt: sentAt,
      sentBy: sentBy,
      receivedAt: receivedAt,
      receivedBy: receivedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      completedAt: completedAt,
      completedBy: completedBy,
      notifiedAt: notifiedAt,
      result: result,
      resultNote: resultNote,
      rejectReason: rejectReason ?? this.rejectReason,
    );
  }
}
