
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/auth/controllers/user_session_controller.dart';

class AccountSettingsController extends GetxController {
  final RxBool autoSync = true.obs;
  final RxBool largeText = false.obs;

  // Temporary value until connected to local database
  final RxInt pendingOperations = 7.obs;

  // Logout loading state
  final RxBool isLoggingOut = false.obs;

  // Session controller
  final UserSessionController _sessionController =
  Get.find<UserSessionController>();

  void toggleAutoSync() {
    autoSync.value = !autoSync.value;
  }

  void toggleLargeText() {
    largeText.value = !largeText.value;
  }

  // Show confirmation dialog
  void confirmLogout() {
    if (isLoggingOut.value) return;

    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: Text(
          pendingOperations.value > 0
              ? 'لديك ${pendingOperations.value} عمليات '
              'غير متزامنة.\n\n'
              'سيتم الاحتفاظ بالبيانات المحلية، '
              'لكنها لن تُزامن حتى تسجل الدخول '
              'مرة أخرى بالحساب المناسب.\n\n'
              'هل تريد تسجيل الخروج؟'
              : 'هل أنت متأكد من تسجيل الخروج؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              logout();
            },
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Logout through UserSessionController
  Future<void> logout() async {
    if (isLoggingOut.value) return;

    try {
      isLoggingOut.value = true;

      await _sessionController.logout();

    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ أثناء تسجيل الخروج',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }
}
