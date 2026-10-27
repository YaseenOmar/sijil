import 'package:sijil/features/family_creation/utils/text_utils.dart';
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
  final int hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final String minute = date.minute.toString().padLeft(2, '0');
  final String period = date.hour < 12 ? 'ص' : 'م';

  return '${toArabicDigits(hour)}:${toArabicDigits(minute)} $period';
}

// ٢١ أكتوبر ٢٠٢٦، ٨:٤٠ ص
String formatDateTime(DateTime date) {
  return '${formatDate(date)}، ${formatTime(date)}';
}

// 0955123467 -> ٠٩٥٥ ١٢٣ ٤٦٧
String formatPhone(String phone) {
  if (phone.length != 10) return toArabicDigits(phone);

  return toArabicDigits(
    '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}',
  );
}

// Short line under the family name on the referral card
String referralProgressNote(ReferralModel referral) {
  switch (referral.status) {
    case ReferralStatus.pendingSend:
      return '${formatDate(referral.createdAt)} · لم تصل إلى الجهة بعد';
    case ReferralStatus.sent:
      return 'أُرسلت ${formatDate(referral.sentAt ?? referral.createdAt)}';
    case ReferralStatus.completed:
      return 'أُرسلت ${formatShortDate(referral.sentAt ?? referral.createdAt)} · اكتملت ${formatDate(referral.completedAt ?? referral.createdAt)}';
    case ReferralStatus.received:
    case ReferralStatus.underReview:
    case ReferralStatus.rejected:
      return 'أُرسلت ${formatShortDate(referral.sentAt ?? referral.createdAt)} · استلمت ${formatDate(referral.receivedAt ?? referral.createdAt)}';
  }
}
