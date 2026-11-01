
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';

class AccountSettingsController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final UserSessionController _sessionController =
  Get.find<UserSessionController>();

  // General Settings
  final RxBool autoSync = true.obs;
  final RxBool largeText = false.obs;

  // Temporary until local database is connected
  final RxInt pendingOperations = 7.obs;

  // Logout
  final RxBool isLoggingOut = false.obs;

  // Profile State
  final RxBool isLoadingProfile = false.obs;
  final RxString profileError = ''.obs;

  // User Profile Data
  final RxString userName = ''.obs;
  final RxString organizationName = ''.obs;
  final RxString userRole = ''.obs;
  final RxString userArea = ''.obs;
  final RxString userEmail = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserProfile();
  }

  // =====================================
  // Load User Profile From Firestore
  // =====================================

  Future<void> loadUserProfile() async {
    try {
      isLoadingProfile.value = true;
      profileError.value = '';

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('لا يوجد مستخدم مسجل الدخول');
      }

      // 1. Get User Document
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists || userDoc.data() == null) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final userData = userDoc.data()!;

      final organizationId =
      (userData['organizationId'] ?? '').toString();

      final role =
      (userData['role'] ?? '').toString();

      final areaId =
      (userData['areaId'] ?? '').toString();

      if (userData['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      if (organizationId.isEmpty) {
        throw Exception('المستخدم غير مرتبط بمنظمة');
      }

      if (role != 'supervisor' &&
          role != 'field_worker') {
        throw Exception('دور المستخدم غير معروف');
      }

      // 2. Prepare User Data
      final fullName =
      (userData['fullName'] ??
          userData['name'] ??
          'غير متوفر')
          .toString();

      final email =
      (userData['email'] ??
          currentUser.email ??
          'غير متوفر')
          .toString();

      // 3. Get Organization Document
      final organizationDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .get();

      if (!organizationDoc.exists) {
        throw Exception('بيانات المنظمة غير موجودة');
      }

      final orgData = organizationDoc.data();

      final orgName =
      (orgData?['name'] ?? 'غير متوفر').toString();

      // 4. Translate User Role
      String roleName;

      if (role == 'supervisor') {
        roleName = 'مشرف';
      } else {
        roleName = 'عامل ميداني';
      }

      // 5. Get Assigned Area
      String areaName = 'جميع مناطق المنظمة';

      if (role == 'field_worker') {
        if (areaId.isEmpty) {
          areaName = 'لم يتم تحديد منطقة';
        } else {
          final areaDoc = await _firestore
              .collection('organizations')
              .doc(organizationId)
              .collection('areas')
              .doc(areaId)
              .get();

          if (areaDoc.exists) {
            areaName =
                (areaDoc.data()?['name'] ??
                    'غير متوفر')
                    .toString();
          } else {
            areaName = 'المنطقة غير موجودة';
          }
        }
      }

      // 6. Update Reactive Values
      userName.value = fullName;
      userEmail.value = email;
      userRole.value = roleName;
      organizationName.value = orgName;
      userArea.value = areaName;

    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        profileError.value =
        'ليس لديك صلاحية لقراءة بيانات الحساب '
            'أو المنظمة أو المنطقة.';
      } else if (e.code == 'unavailable') {
        profileError.value =
        'تعذر الاتصال بقاعدة البيانات. '
            'تحقق من الاتصال وحاول مجددًا.';
      } else {
        profileError.value =
        'تعذر تحميل بيانات الحساب: ${e.message ?? e.code}';
      }

    } catch (e) {
      profileError.value =
          e.toString().replaceFirst('Exception: ', '');

    } finally {
      isLoadingProfile.value = false;
    }
  }

  // =====================================
  // General Settings
  // =====================================

  void toggleAutoSync() {
    autoSync.value = !autoSync.value;
  }

  void toggleLargeText() {
    largeText.value = !largeText.value;
  }

  // =====================================
  // Logout Confirmation
  // =====================================

  void confirmLogout() {
    if (isLoggingOut.value) return;

    Get.dialog(
      AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: Text('هل أنت متأكد من تسجيل الخروج؟',),
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

  // =====================================
  // Logout
  // =====================================

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
