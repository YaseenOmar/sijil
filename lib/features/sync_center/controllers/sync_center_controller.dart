import 'package:get/get.dart';
import 'package:sijil/features/sync_center/constants/sync_demo_data.dart';
import 'package:sijil/features/sync_center/models/sync_operation.dart';

// Controller of the sync center (the local queue while offline)
class SyncCenterController extends GetxController {
  final operations = <SyncOperation>[].obs;

  // TODO: read it from the connectivity service when it exists
  final isOnline = false.obs;

  final autoSync = true.obs;

  final lastSuccessfulSync = SyncDemoData.lastSuccessfulSync;

  @override
  void onInit() {
    super.onInit();

    // Temporary: demo data until the queue comes from local storage
    operations.assignAll(SyncDemoData.queue);
  }

  // ---------- Clean values ----------
  int get pendingCount => operations
      .where((operation) => operation.status == SyncOperationStatus.pending)
      .length;

  int get attachmentsCount =>
      operations.where((operation) => operation.isAttachment).length;

  // ---------- Actions ----------
  void setAutoSync(bool value) {
    autoSync.value = value;
  }

  void syncNow() {
    if (!isOnline.value) return;

    // TODO: send the queue to the server and open the sync result screen
    Get.snackbar('تنبيه', 'المزامنة غير مربوطة بالخادم بعد');
  }

  void openConnectionSettings() {
    // TODO: open the device connection settings (needs a settings package)
    Get.snackbar('تنبيه', 'فتح إعدادات الاتصال غير متاح بعد');
  }
}
