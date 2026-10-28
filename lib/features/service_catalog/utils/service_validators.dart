import 'package:sijil/features/family_creation/utils/text_utils.dart';

// Validators follow the slides contract:
// return null when valid, return an error message when invalid
class ServiceValidators {
  ServiceValidators._();

  static String? name(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال اسم الخدمة';
    if (text.length < 3) return 'الاسم يجب ألا يقل عن 3 أحرف';

    return null;
  }

  static String? description(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال وصف الخدمة';
    if (text.length < 10) return 'الوصف قصير جداً، يرجى كتابة تفاصيل أكثر';

    return null;
  }

  static String? availability(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار حالة التوافر';
    return null;
  }

  static String? cooldownDays(String? value) {
    final text = toLatinDigits(value?.trim() ?? '');

    if (text.isEmpty) return 'يرجى إدخال فترة منع التكرار';

    final days = int.tryParse(text);
    if (days == null) return 'يرجى إدخال رقم صحيح';
    if (days < 1 || days > 365) return 'الفترة يجب أن تكون بين 1 و 365 يوماً';

    return null;
  }

  static String? cooldownReason(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال سبب الفترة';
    if (text.length < 5) return 'السبب قصير جداً، يرجى كتابة تفاصيل أكثر';

    return null;
  }
}
