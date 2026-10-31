import 'package:get/get.dart';
import 'package:sijil/features/sync_center/constants/sync_demo_data.dart';
import 'package:sijil/features/sync_center/models/sync_operation.dart';

// Controller of the sync result (what finished and what needs follow up)
class SyncResultController extends GetxController {
  final operations = <SyncOperation>[].obs;

  final finishedAt = SyncDemoData.roundFinishedAt;
  final lastFullSync = SyncDemoData.lastSuccessfulSync;

  @override
  void onInit() {
    super.onInit();

    // Temporary: demo data until the result comes from the sync service
    operations.assignAll(SyncDemoData.roundResult);
  }

  // ---------- Clean values ----------
  List<SyncOperation> get completed => operations
      .where((operation) => operation.status == SyncOperationStatus.synced)
      .toList();

  List<SyncOperation> get needsFollowUp => operations
      .where((operation) => operation.status != SyncOperationStatus.synced)
      .toList();

  int get totalCount => operations.length;

  int get syncedCount => completed.length;

  int get remainingCount => needsFollowUp.length;

  // Ex: 2 -> "العمليتان المتبقيتان"
  String get remainingSubject =>
      remainingCount == 2 ? 'العمليتان المتبقيتان' : 'العمليات المتبقية';

  // Ex: 2 -> "العمليتين المتبقيتين"
  String get remainingObject =>
      remainingCount == 2 ? 'العمليتين المتبقيتين' : 'العمليات المتبقية';

  // ---------- Actions ----------
  void retryAttachment(SyncOperation operation) {
    // TODO: resume the upload of the same attachment (no duplicate copy)
    Get.snackbar('تنبيه', 'إعادة الرفع غير مربوطة بالخادم بعد');
  }

  void syncRemaining() {
    // TODO: send the remaining operations through the sync service
    Get.snackbar('تنبيه', 'المزامنة غير مربوطة بالخادم بعد');
  }
}
