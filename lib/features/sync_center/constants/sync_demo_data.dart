import 'package:sijil/features/sync_center/models/sync_operation.dart';

// Temporary data until the local queue (Hive) and the sync service exist.
// Replace it with the real services before production use.
class SyncDemoData {
  SyncDemoData._();

  static final DateTime lastSuccessfulSync = DateTime(2026, 10, 20, 16, 30);
  static final DateTime roundFinishedAt = DateTime(2026, 10, 21, 9, 40);

  // Queue shown while the device is offline
  static const List<SyncOperation> queue = [
    SyncOperation(
      id: 'op_001',
      number: 1,
      title: 'إنشاء سجل سامي يوسف الخطيب',
      detail: 'بيانات الأسرة · محفوظة على الجهاز',
      status: SyncOperationStatus.pending,
    ),
    SyncOperation(
      id: 'op_002',
      number: 2,
      title: 'تعديل أسرة محمود حسن العلي',
      detail: 'عدد الأفراد من ٥ إلى ٦',
      status: SyncOperationStatus.pending,
    ),
    SyncOperation(
      id: 'op_003',
      number: 3,
      title: 'بيانات مساعدة يوسف ناصر حمد',
      detail: 'طرد غذائي · ٢١ أكتوبر ٢٠٢٦',
      status: SyncOperationStatus.pending,
    ),
    SyncOperation(
      id: 'op_004',
      number: 4,
      title: 'إحالة سامي إلى مركز الشفاء',
      detail: 'تأهيل حركي · لم تُرسل بعد',
      status: SyncOperationStatus.pending,
    ),
    SyncOperation(
      id: 'op_005',
      number: 5,
      title: 'صورة هوية سامي يوسف الخطيب',
      detail: 'مرفق · ٨٤٠٠ كيلوبايت · لم يبدأ الرفع',
      status: SyncOperationStatus.pending,
      isAttachment: true,
    ),
    SyncOperation(
      id: 'op_006',
      number: 6,
      title: 'إثبات استلام يوسف ناصر حمد',
      detail: 'مرفق · ١,٢ ميغابايت · لم يبدأ الرفع',
      status: SyncOperationStatus.pending,
      isAttachment: true,
    ),
    SyncOperation(
      id: 'op_007',
      number: 7,
      title: 'تحديث جوال هناء علي منصور',
      detail: 'تعديل محلي ينتظر الإرسال',
      status: SyncOperationStatus.pending,
    ),
  ];

  // Result of one sync round: 5 done, 1 failed, 1 left in the queue
  static const List<SyncOperation> roundResult = [
    SyncOperation(
      id: 'op_001',
      number: 1,
      title: 'إنشاء سجل سامي يوسف الخطيب',
      status: SyncOperationStatus.synced,
    ),
    SyncOperation(
      id: 'op_002',
      number: 2,
      title: 'تعديل عدد أفراد أسرة محمود',
      status: SyncOperationStatus.synced,
    ),
    SyncOperation(
      id: 'op_003',
      number: 3,
      title: 'بيانات مساعدة يوسف · الإثبات لم يكتمل',
      status: SyncOperationStatus.synced,
    ),
    SyncOperation(
      id: 'op_004',
      number: 4,
      title: 'إرسال إحالة سامي · لا يوجد تأكيد استلام',
      status: SyncOperationStatus.synced,
    ),
    SyncOperation(
      id: 'op_005',
      number: 5,
      title: 'رفع صورة هوية سامي · ٨٤٠٠ كيلوبايت',
      status: SyncOperationStatus.synced,
      isAttachment: true,
    ),
    SyncOperation(
      id: 'op_006',
      number: 6,
      title: 'إثبات استلام يوسف ناصر حمد',
      note: 'انقطع رفع المرفق عند ٦٠٪. لم يكتمل إثبات المساعدة بعد؛ لن تُرفع نسخة مكررة.',
      status: SyncOperationStatus.failed,
      isAttachment: true,
    ),
    SyncOperation(
      id: 'op_007',
      number: 7,
      title: 'تحديث جوال هناء علي منصور',
      note: 'بقي في الطابور عند توقف الجولة.',
      status: SyncOperationStatus.pending,
    ),
  ];
}
