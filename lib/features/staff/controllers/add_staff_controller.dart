import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/features/staff/constants/staff_options.dart';
import 'package:sijil/features/employees/controllers/employee_controller.dart';

class AddStaffController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final EmployeeController _employeeController =
  Get.find<EmployeeController>();

  // Inputs
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  // Reactive values
  final fullName = ''.obs;
  final role = RxnString();
  final areaId = RxnString();

  final accountStatus =
  RxnString('نشط بعد قبول الدعوة والتحقق');

  final isConfirmed = false.obs;
  final isLoading = false.obs;

  String get email =>
      emailController.text.trim().toLowerCase();

  String? get areaName =>
      areaId.value == null
          ? null
          : StaffOptions.areaName(areaId.value!);

  void onNameChanged(String value) {
    fullName.value = value.trim();
  }

  void selectRole(String? value) {
    role.value = value;
  }

  void selectArea(String? value) {
    areaId.value = value;
  }

  void selectAccountStatus(String? value) {
    // Status is determined automatically.
  }

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  bool validateForReview() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (role.value != 'عامل ميداني') {
      Get.snackbar(
        'تنبيه',
        'يمكن إضافة عامل ميداني فقط حاليًا',
      );
      return false;
    }

    if (!isConfirmed.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى تأكيد مراجعة بيانات الموظف',
      );
      return false;
    }

    return true;
  }

  Future<void> confirmAdd() async {
    if (isLoading.value) return;
    if (!validateForReview()) return;

    try {
      isLoading.value = true;

      // Get signed-in supervisor
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      // Read supervisor profile
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final userData = userDoc.data()!;

      if (userData['role'] != 'supervisor' ||
          userData['status'] != 'active') {
        throw Exception(
          'ليس لديك صلاحية إضافة الموظفين',
        );
      }

      final organizationId = userData['organizationId'];

      if (organizationId is! String ||
          organizationId.isEmpty) {
        throw Exception('معرّف المؤسسة غير صالح');
      }

      // Convert the selected role to Firestore value
      const employeeRole = 'field_worker';

      // Save and send invitation
      final success = await _employeeController.addEmployee(
        fullName: fullNameController.text.trim(),
        email: email,
        role: employeeRole,
        areaId: areaId.value!,
        organizationId: organizationId,
      );

      if (success) {
        Get.back(); // Close review sheet
        Get.back(); // Return from add staff screen
      }
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
