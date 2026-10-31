// Static choices used by the referral screens
class ReferralOptions {
  ReferralOptions._();

  // Status filters on the referrals list (single select)
  static const String filterAll = 'الكل';
  static const String filterInProgress = 'قيد المتابعة';
  static const String filterPending = 'بانتظار الإرسال';
  static const String filterCompleted = 'مكتملة';

  static const List<String> filters = [
    filterAll,
    filterInProgress,
    filterPending,
    filterCompleted,
  ];

  // Status filters on the incoming tab (supervisor view, single select)
  static const String filterWaitingDecision = 'بانتظار القرار';
  static const String filterUnderReview = 'قيد المراجعة';
  static const String filterServiceDone = 'تم تقديم الخدمة';
  static const String filterRejected = 'مرفوضة';

  static const List<String> incomingFilters = [
    filterWaitingDecision,
    filterUnderReview,
    filterServiceDone,
    filterRejected,
  ];

  // Temporary: organizations and services until they come from Firestore
  static const List<String> receivingOrgs = [
    'مركز الشفاء',
    'مؤسسة السند',
    'جمعية العون',
  ];

  static const List<String> serviceTypes = [
    'تأهيل حركي',
    'رعاية صحية',
    'دعم سكني',
    'مساعدات غذائية',
  ];

  static const String orgHelper =
      'خدمات التأهيل متاحة بحسب آخر تحديث: ٢٠ أكتوبر ٢٠٢٦.';
}
