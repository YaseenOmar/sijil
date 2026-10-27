import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/staff/constants/staff_options.dart';

// One controller for the add staff screen
class AddStaffController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // ---------- Inputs ----------
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();

  // Used by the permissions preview while the user types
  final fullName = ''.obs;

  final role = RxnString();
  final areaId = RxnString();
  final accountStatus = RxnString(StaffOptions.accountStatuses.first);

  // ---------- UI states ----------
  final isConfirmed = false.obs;

  // ---------- Clean values ----------
  String get email => emailController.text.trim().toLowerCase();

  String? get areaName =>
      areaId.value == null ? null : StaffOptions.areaName(areaId.value!);

  // ---------- Actions ----------
  void onNameChanged(String value) => fullName.value = value.trim();

  void selectRole(String? value) => role.value = value;

  void selectArea(String? value) => areaId.value = value;

  void selectAccountStatus(String? value) => accountStatus.value = value;

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  // true when the form is valid and the user confirmed the review
  bool validateForReview() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return false;

    if (!isConfirmed.value) {
      Get.snackbar('تنبيه', 'يرجى تأكيد مراجعة بيانات الموظف');
      return false;
    }

    return true;
  }

  void confirmAdd() {
    // Close the review sheet
    Get.back();

    Get.snackbar(
      'تنبيه',
      'تمت مراجعة الصلاحيات. لن تُرسل الدعوة قبل الربط مع الخادم.',
    );
  }

  @override
  void onClose() {
    fullNameController.dispose();
    emailController.dispose();
    super.onClose();
  }
}
