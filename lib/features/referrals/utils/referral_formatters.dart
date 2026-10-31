
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';

const List<String> _months = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

// ٢١ أكتوبر
String formatShortDate(DateTime date) {
  return '${toArabicDigits(date.day)} ${_months[date.month - 1]}';
}

// ٢١ أكتوبر ٢٠٢٦
String formatDate(DateTime date) {
  return '${formatShortDate(date)} ${toArabicDigits(date.year)}';
}

// ٨:٤٠ ص
String formatTime(DateTime date) {
  final int hour = date.hour % 12 == 0
      ? 12
      : date.hour % 12;

  final String minute =
  date.minute.toString().padLeft(2, '0');

  final String period = date.hour < 12 ? 'ص' : 'م';

  return '${toArabicDigits(hour)}:${toArabicDigits(minute)} $period';
}

// ٢١ أكتوبر ٢٠٢٦، ٨:٤٠ ص
String formatDateTime(DateTime date) {
  return '${formatDate(date)}، ${formatTime(date)}';
}

// Phone number
String formatPhone(String phone) {
  if (phone.length != 10) {
    return toArabicDigits(phone);
  }

  return toArabicDigits(
    '${phone.substring(0, 4)} '
        '${phone.substring(4, 7)} '
        '${phone.substring(7)}',
  );
}

// Referral progress description
String referralProgressNote(ReferralModel referral) {
  switch (referral.status) {
    case ReferralStatus.pendingSourceApproval:
      return 'تم إنشاء الطلب ${formatDate(referral.createdAt)} · بانتظار موافقة المشرف';

    case ReferralStatus.rejectedBySource:
      return 'رفضت المؤسسة المرسلة طلب الإحالة';

    case ReferralStatus.pendingTargetApproval:
      return 'أُرسلت ${formatDate(referral.sourceApprovedAt ?? referral.createdAt)} · بانتظار قرار الجهة المستقبلة';

    case ReferralStatus.rejectedByTarget:
      return 'رفضت الجهة المستقبلة الإحالة';

    case ReferralStatus.accepted:
      return 'تم قبول الإحالة ${formatDate(referral.targetReviewedAt ?? referral.createdAt)}';

    case ReferralStatus.inProgress:
      return 'جاري تقديم الخدمة للأسرة';

    case ReferralStatus.completed:
      return 'اكتملت الخدمة ${formatDate(referral.completedAt ?? referral.createdAt)}';
  }
}

String _referralsCount(int count) {
  if (count == 1) return 'إحالة واحدة';
  if (count == 2) return 'إحالتان';
  if (count <= 10) {
    return '${toArabicDigits(count)} إحالات';
  }
  return '${toArabicDigits(count)} إحالة';
}

// Description of the filtered incoming referrals
String incomingListNote({
  required String filter,
  required int shown,
  required int total,
}) {
  final String state =
  filter == ReferralOptions.filterWaitingDecision
      ? filter
      : 'ضمن «$filter»';

  final String note =
      '${_referralsCount(total)} $state · '
      'المعروض ${toArabicDigits(shown)} '
      'من ${toArabicDigits(total)}، '
      'بترتيب الأحدث أولاً.';

  if (shown < total) {
    return '$note يمكنك عرض بقية الإحالات من القائمة.';
  }

  return note;
}

// Display remaining referrals label
String showRestLabel(int count) {
  const List<String> words = [
    '',
    'الواحدة',
    'الاثنتين',
    'الثلاث',
    'الأربع',
    'الخمس',
    'الست',
    'السبع',
    'الثماني',
    'التسع',
    'العشر',
  ];

  if (count == 1) {
    return 'عرض الإحالة المتبقية';
  }

  if (count < words.length) {
    return 'عرض بقية الإحالات ${words[count]}';
  }

  return 'عرض بقية الإحالات (${toArabicDigits(count)})';
}
