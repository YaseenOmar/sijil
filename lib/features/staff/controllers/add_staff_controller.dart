
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/employees/controllers/employee_controller.dart';

class AddStaffController extends GetxController {
  // ==========================================
  // Dependencies
  // ==========================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final UserSessionController session =
  Get.find<UserSessionController>();

  // ==========================================
  // Form
  // ==========================================

  final GlobalKey<FormState> formKey =
  GlobalKey<FormState>();

  final TextEditingController fullNameController =
  TextEditingController();

  final TextEditingController emailController =
  TextEditingController();

  // ==========================================
  // Reactive Values
  // ==========================================

  final RxString fullName = ''.obs;

  final RxnString role = RxnString('عامل ميداني');

  final RxnString areaId = RxnString();

  final RxnString accountStatus =
  RxnString('بانتظار القبول');

  final RxBool isConfirmed = false.obs;

  final RxBool isLoading = false.obs;

  // ==========================================
  // Getters
  // ==========================================

  String get email =>
      emailController.text.trim().toLowerCase();

  String get organizationId =>
      session.organizationId.value;

  String get currentUserId =>
      session.uid.value;

  // Selected area ID only.
  // Area name is loaded by AddStaffScreen.
  String? get selectedAreaId => areaId.value;

  // ==========================================
  // Form Actions
  // ==========================================

  void onNameChanged(String value) {
    fullName.value = value.trim();
    isConfirmed.value = false;
  }

  void selectRole(String? value) {
    if (value == 'عامل ميداني' || value == 'مشرف') {
      role.value = value;
      isConfirmed.value = false;
    }
  }

  void selectArea(String? value) {
    areaId.value = value;
    isConfirmed.value = false;
  }

  void selectAccountStatus(String? value) {
    // Invitation status is always pending.
    // It cannot be changed from this form.
  }

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  // ==========================================
  // Validate Before Review
  // ==========================================

  bool validateForReview() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (isLoading.value) {
      return false;
    }

    if (!session.isProfileLoaded.value ||
        !session.isSupervisor ||
        organizationId.isEmpty) {
      _showError(
        'ليس لديك صلاحية إضافة الموظفين',
      );
      return false;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (fullNameController.text.trim().isEmpty) {
      _showError('يرجى إدخال اسم الموظف');
      return false;
    }

    if (email.isEmpty) {
      _showError('يرجى إدخال البريد الإلكتروني');
      return false;
    }
    if (role.value != 'عامل ميداني' &&
        role.value != 'مشرف') {
      _showError('يرجى اختيار دور وظيفي صحيح');
      return false;
    }

    if (areaId.value == null ||
        areaId.value!.trim().isEmpty) {
      _showError(
        'يرجى اختيار المنطقة المكلف بها',
      );
      return false;
    }

    if (!isConfirmed.value) {
      _showError(
        'يرجى تأكيد مراجعة بيانات الموظف',
      );
      return false;
    }

    return true;
  }

  // ==========================================
  // Confirm Add Staff
  // ==========================================

  Future<void> confirmAdd() async {
    if (isLoading.value) return;

    if (!validateForReview()) return;

    isLoading.value = true;

    try {
      // --------------------------------------
      // 1. Check Authentication
      // --------------------------------------

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception(
          'يجب تسجيل الدخول أولًا',
        );
      }

      if (currentUser.uid != currentUserId) {
        throw Exception(
          'بيانات الجلسة لا تطابق المستخدم الحالي',
        );
      }

      // --------------------------------------
      // 2. Verify Supervisor Permissions
      // --------------------------------------

      final supervisorDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!supervisorDoc.exists) {
        throw Exception(
          'ملف المشرف غير موجود',
        );
      }

      final supervisorData = supervisorDoc.data()!;

      if (supervisorData['role'] != 'supervisor' ||
          supervisorData['status'] != 'active') {
        throw Exception(
          'ليس لديك صلاحية إضافة الموظفين',
        );
      }

      final orgId =
      supervisorData['organizationId'];

      if (orgId is! String || orgId.isEmpty) {
        throw Exception(
          'المشرف غير مرتبط بمؤسسة',
        );
      }

      if (orgId != organizationId) {
        throw Exception(
          'بيانات المؤسسة غير متطابقة',
        );
      }

      // --------------------------------------
      // 3. Validate Selected Area
      // --------------------------------------

      final selectedArea = areaId.value;

      if (selectedArea == null ||
          selectedArea.isEmpty) {
        throw Exception(
          'يرجى اختيار منطقة الموظف',
        );
      }

      final areaDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('areas')
          .doc(selectedArea)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!areaDoc.exists) {
        throw Exception(
          'المنطقة المختارة غير موجودة',
        );
      }

      // --------------------------------------
      // 4. Prepare Staff Data
      // --------------------------------------

      final staffFullName =
      fullNameController.text.trim();

      final staffEmail = email;

      final String staffRole = role.value == 'مشرف' ? 'supervisor' : 'field_worker';

      // Ensure user did not switch accounts
      // during the asynchronous operations.
      if (_auth.currentUser?.uid != currentUser.uid) {
        throw Exception(
          'تغير المستخدم أثناء العملية',
        );
      }

      // --------------------------------------
      // 5. Create Pending Invitation
      // --------------------------------------

      if (!Get.isRegistered<EmployeeController>()) {
        throw Exception(
          'خدمة إدارة الموظفين غير مهيأة',
        );
      }

      final employeeController =
      Get.find<EmployeeController>();

      final success =
      await employeeController.addEmployee(
        fullName: staffFullName,
        email: staffEmail,
        role: staffRole,
        areaId: selectedArea,
        organizationId: orgId,
      );

      if (!success) {
        // EmployeeController should display
        // the underlying failure message.
        return;
      }

      // --------------------------------------
      // 6. Successful Creation
      // --------------------------------------

      // Reset confirmation to avoid
      // submitting the same form again.
      isConfirmed.value = false;

      // Close review sheet.
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      // Return to team screen.
      Get.back(result: true);

      Get.snackbar(
        'تمت الإضافة',
        'تم إنشاء دعوة الموظف بنجاح وهي بانتظار القبول',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFE6F4EA),
        colorText: const Color(0xFF137333),
      );
    } on FirebaseException catch (e) {
      String message;

      switch (e.code) {
        case 'permission-denied':
          message =
          'ليس لديك صلاحية لإضافة موظف لهذه المؤسسة';
          break;

        case 'unavailable':
          message =
          'تعذر الاتصال بالخادم، تحقق من الإنترنت';
          break;

        default:
          message = e.message ??
              'حدث خطأ أثناء إنشاء الدعوة';
      }

      _showError(message);
    } catch (e) {
      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================
  // Error Message
  // ==========================================

  void _showError(String message) {
    Get.snackbar(
      'تنبيه',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFEBEE),
      colorText: const Color(0xFFB71C1C),
    );
  }

  // ==========================================
  // Dispose
  // ==========================================

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();

    super.onClose();
  }
}
