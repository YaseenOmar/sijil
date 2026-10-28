import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/service_catalog/constants/service_options.dart';

// One controller for the add service screen
class AddServiceController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // ---------- Inputs ----------
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final cooldownDaysController = TextEditingController();
  final cooldownReasonController = TextEditingController();
  final unitController = TextEditingController();

  // Used by the settings review while the user types
  final name = ''.obs;
  final cooldownDays = ''.obs;

  final availability = RxnString(ServiceOptions.availabilities.first);

  // ---------- Switches ----------
  final acceptsReferrals = true.obs;
  final hasCooldown = false.obs;

  // ---------- Clean values ----------
  int get cooldownDaysValue =>
      int.tryParse(toLatinDigits(cooldownDays.value.trim())) ?? 0;

  // Ex: "دعم تعليمي · متاحة بعد تأكيد الحفظ"
  String get availabilityLine {
    final title = name.value.isEmpty ? 'الخدمة الجديدة' : name.value;
    return '$title · ${availability.value ?? '-'} بعد تأكيد الحفظ';
  }

  // Ex: "استقبال الإحالات مفعّل · منع تكرار ١٨٠ يوماً"
  String get rulesLine {
    final referrals = acceptsReferrals.value
        ? 'استقبال الإحالات مفعّل'
        : 'استقبال الإحالات غير مفعّل';

    if (!hasCooldown.value || cooldownDaysValue == 0) return referrals;

    return '$referrals · منع تكرار ${toArabicDigits(cooldownDaysValue)} يوماً';
  }

  // ---------- Actions ----------
  void onNameChanged(String value) => name.value = value.trim();

  void onCooldownDaysChanged(String value) => cooldownDays.value = value;

  void selectAvailability(String? value) => availability.value = value;

  void setAcceptsReferrals(bool value) {
    acceptsReferrals.value = value;
  }

  void setHasCooldown(bool value) {
    hasCooldown.value = value;
  }

  // true when the form is valid and ready for the final confirmation
  bool validateForReview() {
    FocusManager.instance.primaryFocus?.unfocus();

    return formKey.currentState?.validate() ?? false;
  }

  void confirmSave() {
    // Close the review sheet
    Get.back();

    // TODO: save the service in Firestore and publish it only after the server confirms
    Get.snackbar(
      'تنبيه',
      'تمت مراجعة الخدمة. لن تُنشر قبل تأكيد الحفظ على الخادم.',
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    cooldownDaysController.dispose();
    cooldownReasonController.dispose();
    unitController.dispose();
    super.onClose();
  }
}
