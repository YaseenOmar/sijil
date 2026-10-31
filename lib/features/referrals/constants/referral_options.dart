
class ReferralOptions {
  ReferralOptions._();

  // Outgoing referral filters
  static const String filterAll = 'الكل';

  static const String filterPending =
      'بانتظار موافقة المشرف';

  static const String filterInProgress =
      'قيد المتابعة';

  static const String filterCompleted =
      'مكتملة';

  static const String filterOutgoingRejected =
      'مرفوضة';

  static const List<String> filters = [
    filterAll,
    filterPending,
    filterInProgress,
    filterCompleted,
    filterOutgoingRejected,
  ];

  // Incoming referral filters
  static const String filterWaitingDecision =
      'بانتظار القرار';

  static const String filterUnderReview =
      'قيد تقديم الخدمة';

  static const String filterServiceDone =
      'تم تقديم الخدمة';

  static const String filterRejected =
      'مرفوضة';

  static const List<String> incomingFilters = [
    filterWaitingDecision,
    filterUnderReview,
    filterServiceDone,
    filterRejected,
  ];
}
