// Static choices used by the add service screen
class ServiceOptions {
  ServiceOptions._();

  // Temporary: the signed in manager until it comes from authentication
  static const String managerName = 'خالد عمر';
  static const String managerLabel = '$managerName · مدير جمعية الأمان';

  // Service availability (single select)
  static const List<String> availabilities = [
    'متاحة',
    'غير متاحة مؤقتاً',
  ];
}
