
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/referral_model.dart';
import '../repositories/referral_repository.dart';
import '../services/referral_service.dart';
import '../utils/referral_validators.dart';

class IncomingReferralController extends GetxController {
  final ReferralModel initialReferral;

  final bool isSupervisor;

  IncomingReferralController(this.initialReferral, {this.isSupervisor = true});

  final ReferralRepository _repository = ReferralRepository();
  final ReferralService _service = ReferralService();

  // Current referral from Firestore
  final currentReferral = Rxn<ReferralModel>();

  StreamSubscription<ReferralModel?>? _subscription;

  // Rejection
  final rejectReasonController = TextEditingController();
  final rejectReason = ''.obs;
  final isReasonTouched = false.obs;

  // Service result
  final resultController = TextEditingController();
  final resultNoteController = TextEditingController();

  // UI
  final isLoading = true.obs;
  final isProcessing = false.obs;
  final loadError = RxnString();

  ReferralModel? get referral => currentReferral.value;

  bool get isWaitingDecision =>
      isSupervisor && referral?.status == ReferralStatus.pendingTargetApproval;

  bool get canStartService =>
      !isSupervisor && referral?.status == ReferralStatus.accepted;

  bool get canCompleteService =>
      !isSupervisor &&
      referral?.status == ReferralStatus.inProgress &&
      referral?.assignedTo == FirebaseAuth.instance.currentUser?.uid;

  bool get isCompleted =>
      referral?.status == ReferralStatus.completed;

  bool get canReject =>
      isSupervisor && isWaitingDecision &&
          ReferralValidators.rejectReason(rejectReason.value) == null;

  String? get rejectError => isReasonTouched.value
      ? ReferralValidators.rejectReason(rejectReason.value)
      : null;

  @override
  void onInit() {
    super.onInit();

    currentReferral.value = initialReferral;
    watchReferral();
  }

  void watchReferral() {
    isLoading.value = true;
    loadError.value = null;

    _subscription = _repository
        .watchReferral(initialReferral.id)
        .listen(
          (item) {
        if (isClosed) return;

        currentReferral.value = item;
        isLoading.value = false;

        if (item == null) {
          loadError.value = 'الإحالة غير موجودة';
        } else {
          loadError.value = null;
        }
      },
      onError: (Object error) {
        if (isClosed) return;

        isLoading.value = false;
        loadError.value = _errorMessage(error);
      },
    );
  }

  void onRejectReasonChanged(String value) {
    isReasonTouched.value = true;
    rejectReason.value = value;
  }

  // ---------------- Accept ----------------

  Future<void> acceptReferral() async {
    if (isProcessing.value || !isWaitingDecision) return;

    await _execute(
          () => _service.acceptIncoming(initialReferral.id),
      'تم قبول الإحالة',
      'أُضيفت الأسرة إلى سجلات الإحالات الواردة',
    );
  }

  // ---------------- Reject ----------------

  Future<void> rejectReferral() async {
    if (isProcessing.value || !isWaitingDecision) return;

    if (!canReject) {
      isReasonTouched.value = true;
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await _execute(
          () => _service.rejectIncoming(
        referralId: initialReferral.id,
        reason: rejectReason.value.trim(),
      ),
      'تم رفض الإحالة',
      'تم حفظ قرار الرفض وسببه',
    );
  }

  // ---------------- Start Service ----------------

  Future<void> startService() async {
    if (isProcessing.value || !canStartService) return;

    await _execute(
          () => _service.startService(initialReferral.id),
      'تم بدء الخدمة',
      'تم تحديث حالة الإحالة إلى جاري تقديم الخدمة',
    );
  }

  // ---------------- Complete Service ----------------

  Future<void> completeService() async {
    if (isProcessing.value || !canCompleteService) return;

    final result = resultController.text.trim();
    final note = resultNoteController.text.trim();

    if (result.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى كتابة نتيجة الخدمة قبل إنهائها',
      );
      return;
    }

    if (result.length > 2000 || note.length > 2000) {
      Get.snackbar(
        'تنبيه',
        'يجب ألا تتجاوز النتيجة أو الملاحظات 2000 حرف',
      );
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    await _execute(
          () => _service.completeService(
        referralId: initialReferral.id,
        result: result,
        resultNote: note.isEmpty ? null : note,
      ),
      'تم إكمال الخدمة',
      'تم حفظ نتيجة الخدمة وتحديث الإحالة',
    );
  }

  // ---------------- Shared Action Handler ----------------

  Future<void> _execute(
      Future<void> Function() action,
      String successTitle,
      String successMessage,
      ) async {
    if (isProcessing.value) return;

    try {
      isProcessing.value = true;
      loadError.value = null;

      await action();

      if (isClosed) return;

      Get.snackbar(successTitle, successMessage);
    } catch (e) {
      if (isClosed) return;

      final message = _errorMessage(e);
      loadError.value = message;

      Get.snackbar('تعذر تنفيذ العملية', message);
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية لتنفيذ هذه العملية';

        case 'failed-precondition':
          return 'حالة الإحالة لا تسمح بهذه العملية';

        case 'not-found':
          return 'الإحالة غير موجودة';

        case 'unauthenticated':
          return 'يرجى تسجيل الدخول مجددًا';

        case 'unavailable':
          return 'تعذر الاتصال بخدمة Firebase';

        default:
          return error.message ?? 'حدث خطأ غير متوقع';
      }
    }

    return 'تعذر تنفيذ العملية، يرجى المحاولة مرة أخرى';
  }

  @override
  void onClose() {
    _subscription?.cancel();
    rejectReasonController.dispose();
    resultController.dispose();
    resultNoteController.dispose();
    super.onClose();
  }
}
