import 'package:sijil/core/constants/demo_context.dart';

// Static choices used by the family creation flow
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
  static const Map<String, String> _areaNames = {'area_001': 'حي النور'};

  static String areaName(String areaId) => _areaNames[areaId] ?? areaId;

  // Area used for the new family (first assigned area to the employee)
  static String get defaultAreaId => DemoContext.assignedAreaIds.first;
}
