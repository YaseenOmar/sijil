import 'package:sijil/features/family_creation/utils/text_utils.dart';

// Validators follow the slides contract:
// return null when valid, return an error message when invalid
class FamilyValidators {
  FamilyValidators._();

  static String? headName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال اسم رب الأسرة';
    if (text.length < 3) return 'الاسم يجب ألا يقل عن 3 أحرف';
    if (RegExp(r'\d').hasMatch(toLatinDigits(text))) {
      return 'الاسم يجب ألا يحتوي على أرقام';
    }

    return null;
  }

  static String? nationalId(String? value) {
    final text = toLatinDigits(value?.trim() ?? '');

    if (text.isEmpty) return 'يرجى إدخال رقم الهوية';
    if (!RegExp(r'^\d+$').hasMatch(text)) {
      return 'رقم الهوية يجب أن يتكون من أرقام فقط';
    }
    if (text.length != 9) return 'رقم الهوية يجب أن يتكون من 9 أرقام';

    return null;
  }

  static String? phone(String? value) {
    final text = toLatinDigits(value ?? '').replaceAll(RegExp(r'[\s-]'), '');

    if (text.isEmpty) return 'يرجى إدخال رقم الجوال';
    if (!RegExp(r'^05\d{8}$').hasMatch(text)) {
      return 'رقم الجوال غير صحيح (مثال: 0599123456)';
    }

    return null;
  }

  static String? membersCount(String? value) {
    final text = toLatinDigits(value?.trim() ?? '');

    if (text.isEmpty) return 'يرجى إدخال عدد أفراد الأسرة';

    final count = int.tryParse(text);
    if (count == null) return 'يرجى إدخال رقم صحيح';
    if (count < 1 || count > 30) {
      return 'عدد الأفراد يجب أن يكون بين 1 و 30';
    }

    return null;
  }

  static String? address(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال العنوان التفصيلي';
    if (text.length < 5) return 'العنوان قصير جداً، يرجى كتابة تفاصيل أكثر';

    return null;
  }
}
