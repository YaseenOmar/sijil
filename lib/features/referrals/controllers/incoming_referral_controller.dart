import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/controllers/referrals_controller.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/utils/referral_validators.dart';

// Controller of the incoming referral review (accept or reject with a reason)
class IncomingReferralController extends GetxController {
  final ReferralModel referral;

  IncomingReferralController(this.referral);

  final rejectReasonController = TextEditingController();

  final rejectReason = ''.obs;

  // The error is shown only after the user starts typing
  final isReasonTouched = false.obs;

  // ---------- Clean values ----------
  bool get canReject =>
      ReferralValidators.rejectReason(rejectReason.value) == null;

  String? get rejectError => isReasonTouched.value
      ? ReferralValidators.rejectReason(rejectReason.value)
      : null;

  // The decision is allowed only while the referral waits for it
  bool get isWaitingDecision => referral.status == ReferralStatus.received;

  // ---------- Actions ----------
  void onRejectReasonChanged(String value) {
    isReasonTouched.value = true;
    rejectReason.value = value;
  }

  void acceptReferral() {
    if (!isWaitingDecision) return;

    _updateReferral(
      referral.copyWith(
        status: ReferralStatus.underReview,
        reviewedAt: DateTime.now(),
        reviewedBy: ReferralDemoData.supervisorLabel,
      ),
    );

    Get.back();
    Get.snackbar('تم القبول', 'انتقلت الإحالة إلى «قيد المراجعة»');
  }

  void rejectReferral() {
    if (!isWaitingDecision) return;

    if (!canReject) {
      isReasonTouched.value = true;
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    _updateReferral(
      referral.copyWith(
        status: ReferralStatus.rejected,
        reviewedAt: DateTime.now(),
        reviewedBy: ReferralDemoData.supervisorLabel,
        rejectReason: rejectReason.value.trim(),
      ),
    );

    Get.back();
    Get.snackbar('تم الرفض', 'سيُرسل إشعار بالسبب إلى الموظف المحيل');
  }

  // TODO: save the decision in Firestore and notify the referring employee
  void _updateReferral(ReferralModel updated) {
    if (Get.isRegistered<ReferralsController>()) {
      Get.find<ReferralsController>().updateReferral(updated);
    }
  }

  @override
  void onClose() {
    rejectReasonController.dispose();
    super.onClose();
  }
}
