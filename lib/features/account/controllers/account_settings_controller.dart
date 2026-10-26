
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AccountSettingsController extends GetxController {
  final RxBool autoSync = true.obs;
  final RxBool largeText = false.obs;

  // Temporary value until connected to local database
  final RxInt pendingOperations = 7.obs;

  // Logout loading state
  final RxBool isLoggingOut = false.obs;

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

  // Firebase logout
  Future<void> logout() async {
    if (isLoggingOut.value) return;

    try {
      isLoggingOut.value = true;

      await FirebaseAuth.instance.signOut();

      // TODO: Navigate to your actual login route.
      // Example (after registering /login in GetMaterialApp):
      //
      // Get.offAllNamed('/login');

    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر تسجيل الخروج: ${e.message ?? e.code}',
        snackPosition: SnackPosition.BOTTOM,
      );
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
