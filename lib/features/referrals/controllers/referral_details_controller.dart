
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/referral_model.dart';
import '../repositories/referral_repository.dart';
import '../services/referral_service.dart';

class ReferralDetailsController extends GetxController {
  final String referralId;

  ReferralDetailsController(this.referralId);

  final ReferralRepository _repository = ReferralRepository();
  final ReferralService _service = ReferralService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final rejectReasonController = TextEditingController();

  // Referral data
  final referral = Rxn<ReferralModel>();
  final referralSteps = <ReferralStep>[].obs;
  final isLoadingSteps = true.obs;
  final stepsError = RxnString();

  // UI states
  final isLoading = true.obs;
  final isProcessing = false.obs;
  final loadError = RxnString();

  // Current user
  final isSupervisor = false.obs;
  final currentOrganizationId = ''.obs;

  // Rejection
  final rejectReason = ''.obs;
  final showRejectField = false.obs;

  StreamSubscription<ReferralModel?>? _subscription;
  StreamSubscription<List<ReferralStep>>? _stepsSubscription;

  // Supervisor can only review referrals from their organization
  // while they are awaiting source approval.
  bool get canReview {
    final item = referral.value;

    return item != null &&
        isSupervisor.value &&
        item.sourceOrganizationId ==
            currentOrganizationId.value &&
        item.status == ReferralStatus.pendingSourceApproval;
  }

  bool get canReject =>
      canReview && rejectReason.value.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadDetails();
  }

  // ---------------- Load Referral ----------------

  Future<void> loadDetails() async {
    try {
      isLoading.value = true;
      loadError.value = null;

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (isClosed) return;

      if (!userDoc.exists) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final userData = userDoc.data()!;

      if (userData['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      isSupervisor.value = userData['role'] == 'supervisor';
      currentOrganizationId.value =
          userData['organizationId'] as String? ?? '';

      watchSteps();

      await _subscription?.cancel();

      if (isClosed) return;

      _subscription = _repository
          .watchReferral(referralId)
          .listen(
            (item) {
          if (isClosed) return;

          referral.value = item;
          isLoading.value = false;

          loadError.value =
          item == null ? 'الإحالة غير موجودة' : null;
        },
        onError: (Object error) {
          if (isClosed) return;

          isLoading.value = false;
          loadError.value = _errorMessage(error);
        },
      );
    } catch (e) {
      if (isClosed) return;

      isLoading.value = false;
      loadError.value = _errorMessage(e);
    }
  }

  // ---------------- Rejection UI ----------------

  void toggleRejectField() {
    if (!canReview || isProcessing.value) return;

    showRejectField.value = !showRejectField.value;
  }

  void onRejectReasonChanged(String value) {
    rejectReason.value = value;
  }

  // ---------------- Approve Referral ----------------

  Future<void> approveReferral() async {
    if (!canReview || isProcessing.value) return;

    try {
      isProcessing.value = true;
      loadError.value = null;

      await _service.approveOutgoing(referralId);

      if (isClosed) return;

      Get.snackbar(
        'تم اعتماد الإحالة',
        'تم إرسال الإحالة إلى المؤسسة المستقبلة',
      );
    } catch (e) {
      if (isClosed) return;

      loadError.value = _errorMessage(e);
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  // ---------------- Reject Referral ----------------

  Future<void> rejectReferral() async {
    if (!canReject || isProcessing.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    try {
      isProcessing.value = true;
      loadError.value = null;

      await _service.rejectOutgoing(
        referralId: referralId,
        reason: rejectReason.value.trim(),
      );

      if (isClosed) return;

      showRejectField.value = false;

      Get.snackbar(
        'تم رفض الإحالة',
        'تم تسجيل سبب الرفض بنجاح',
      );
    } catch (e) {
      if (isClosed) return;

      loadError.value = _errorMessage(e);
    } finally {
      if (!isClosed) {
        isProcessing.value = false;
      }
    }
  }

  // ---------------- Error Handling ----------------

  String _errorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية لتنفيذ العملية';

        case 'failed-precondition':
          return 'حالة الإحالة لا تسمح بهذه العملية';

        case 'not-found':
          return 'الإحالة غير موجودة';

        case 'unavailable':
          return 'تعذر الاتصال بخدمة Firebase';

        default:
          return error.message ?? 'حدث خطأ غير متوقع';
      }
    }

    return error.toString().replaceFirst('Exception: ', '');
  }


  void watchSteps() {
    isLoadingSteps.value = true;
    stepsError.value = null;

    _stepsSubscription?.cancel();

    _stepsSubscription = _repository
        .watchReferralSteps(referralId)
        .listen(
          (steps) {
        if (isClosed) return;

        referralSteps.assignAll(steps);
        isLoadingSteps.value = false;
        stepsError.value = null;
      },
      onError: (Object error) {
        if (isClosed) return;

        isLoadingSteps.value = false;
        stepsError.value = _errorMessage(error);
      },
    );
  }


  @override
  void onClose() {
    _subscription?.cancel();
    _stepsSubscription?.cancel();

    rejectReasonController.dispose();

    super.onClose();
  }
}
