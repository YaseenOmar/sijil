// Validators follow the slides contract:
// return null when valid, return an error message when invalid
class StaffValidators {
  StaffValidators._();

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال اسم الموظف';
    if (text.length < 3) return 'الاسم يجب ألا يقل عن 3 أحرف';
    if (RegExp(r'\d').hasMatch(text)) return 'الاسم يجب ألا يحتوي على أرقام';

    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) return 'يرجى إدخال البريد الإلكتروني';
    if (!RegExp(r'^[\w.+\-]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(text)) {
      return 'البريد الإلكتروني غير صحيح (مثال: name@org.com)';
    }

    return null;
  }

  static String? role(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار الدور الوظيفي';
    return null;
  }

  static String? area(String? value) {
    if (value == null || value.isEmpty) return 'يرجى اختيار المنطقة';
    return null;
  }
}
