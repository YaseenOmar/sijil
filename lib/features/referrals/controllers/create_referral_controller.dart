import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/controllers/referrals_controller.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:uuid/uuid.dart';

// One controller for the create referral screen
class CreateReferralController extends GetxController {
  final formKey = GlobalKey<FormState>();

  // ---------- Inputs ----------
  final reasonController = TextEditingController();

  final familyName = RxnString();
  final receivingOrg = RxnString();
  final serviceType = RxnString();

  // ---------- UI states ----------
  final isConfirmed = false.obs;
  final isSaving = false.obs;

  // ---------- Actions ----------
  void selectFamily(String? value) => familyName.value = value;

  void selectReceivingOrg(String? value) => receivingOrg.value = value;

  void selectServiceType(String? value) => serviceType.value = value;

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  // Save the referral to be sent later (status: pending send)
  void saveForLater() {
    if (isSaving.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(formKey.currentState?.validate() ?? false)) return;

    if (!isConfirmed.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى تأكيد توضيح غرض الإحالة ونطاق المشاركة للأسرة',
      );
      return;
    }

    try {
      isSaving.value = true;

      final family = ReferralDemoData.families.firstWhere(
        (item) => item.name == familyName.value,
      );

      final referrals = Get.isRegistered<ReferralsController>()
          ? Get.find<ReferralsController>()
          : null;

      final referral = ReferralModel(
        id: const Uuid().v4(),
        number: (43 + (referrals?.outgoing.length ?? 0)).toString().padLeft(
          4,
          '0',
        ),
        familyName: family.name,
        membersCount: family.membersCount,
        fromOrg: ReferralDemoData.currentOrg,
        toOrg: receivingOrg.value!,
        service: serviceType.value!,
        reason: reasonController.text.trim(),
        area: family.area,
        contactPhone: family.phone,
        status: ReferralStatus.pendingSend,
        createdAt: DateTime.now(),
      );

      // TODO: save it in the local queue (Hive) and send it when online
      referrals?.addReferral(referral);

      Get.back();
      Get.snackbar('تم الحفظ', 'الإحالة بانتظار الإرسال');
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ الإحالة، يرجى المحاولة مرة أخرى');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
