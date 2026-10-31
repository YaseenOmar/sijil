import 'package:get/get.dart';
import 'package:sijil/features/data_conflicts/models/data_conflict_model.dart';

// Controller of the data conflict notice (the supervisor only reads it)
class DataConflictController extends GetxController {
  final DataConflictModel conflict;

  DataConflictController(this.conflict);

  // ---------- Actions ----------
  void acknowledge() {
    // TODO: mark the notification as read in Firestore
    Get.back();
  }

  void openChangeLog() {
    // TODO: open the change log (audit) screen when it exists
    Get.snackbar('تنبيه', 'سجل التغييرات غير متاح بعد');
  }
}
