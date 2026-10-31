import 'package:sijil/features/data_conflicts/models/data_conflict_model.dart';

// Temporary data until conflicts come from Firestore.
// Replace it with the real service before production use.
class DataConflictDemoData {
  DataConflictDemoData._();

  // Temporary: the signed in supervisor until it comes from authentication
  static const String supervisorLabel = 'نورا إبراهيم · المشرفة';

  static final DataConflictModel sample = DataConflictModel(
    id: 'conflict_001',
    familyName: 'محمود حسن العلي',
    organization: 'جمعية الأمان',
    fieldLabel: 'عدد أفراد الأسرة',
    detectedAt: DateTime(2026, 10, 21, 9, 38),
    previous: ConflictVersion(
      value: '٥ أفراد',
      editor: supervisorLabel,
      editedAt: DateTime(2026, 10, 21, 9, 5),
    ),
    current: ConflictVersion(
      value: '٦ أفراد',
      editor: 'أحمد سالم · العامل الميداني',
      editedAt: DateTime(2026, 10, 21, 9, 10),
    ),
  );
}
