
class FamilyOptions {
  FamilyOptions._();

  // Housing status choices (single select)
  static const List<String> housingStatuses = [
    'ملك',
    'إيجار',
    'استضافة',
    'سكن مؤقت',
  ];

  // Family needs (multi select)
  static const List<String> needs = [
    'غذاء',
    'رعاية صحية',
    'سكن',
    'تعليم',
    'تأهيل تربوي',
  ];

  // Temporary area names until areas come from Firestore
  static const Map<String, String> _areaNames = {
    'area_001': 'حي النور',
  };

  static String areaName(String areaId) {
    return _areaNames[areaId] ?? areaId;
  }
}
