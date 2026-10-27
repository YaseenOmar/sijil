// Validators follow the slides contract:
// return null when valid, return an error message when invalid
class ReferralValidators {
  ReferralValidators._();

  static String? family(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار الأسرة';
    return null;
  }

  static String? receivingOrg(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار الجهة المستقبلة';
    return null;
  }

  static String? serviceType(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار نوع الخدمة';
    return null;
  }

  static String? reason(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى كتابة سبب الإحالة';
    if (text.length < 10) return 'السبب قصير جداً، يرجى كتابة تفاصيل أكثر';

    return null;
  }

  static String? rejectReason(String? value) {
    final text = value?.trim() ?? '';

    if (text.length < 5) return 'اكتب سبباً واضحاً قبل تأكيد الرفض.';

    return null;
  }
}
