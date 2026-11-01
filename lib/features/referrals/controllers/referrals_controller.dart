
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../constants/referral_options.dart';
import '../models/referral_model.dart';
import '../repositories/referral_repository.dart';
import '../views/create_referral_screen.dart';
import '../views/incoming_referral_review_screen.dart';
import '../views/referral_details_screen.dart';

class ReferralsController extends GetxController {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ReferralRepository _repository =
  ReferralRepository();

  // 0 = outgoing, 1 = incoming
  final tabIndex = 0.obs;

  // Filters
  final selectedFilter =
      ReferralOptions.filterAll.obs;

  final selectedIncomingFilter =
      ReferralOptions.filterWaitingDecision.obs;

  // Show more incoming referrals
  final showAllIncoming = false.obs;

  // Referral lists
  final outgoing = <ReferralModel>[].obs;
  final incoming = <ReferralModel>[].obs;

  // UI states
  final isLoading = true.obs;
  final loadError = RxnString();

  // Separate loading flags for both streams
  final isLoadingOutgoing = true.obs;
  final isLoadingIncoming = false.obs;

  // Current user
  final role = ''.obs;
  final organizationId = ''.obs;
  final areaId = ''.obs;

  bool get isSupervisor =>
      role.value == 'supervisor';

  bool get isFieldWorker =>
      role.value == 'field_worker';

  // Firestore listeners
  StreamSubscription<List<ReferralModel>>?
  _outgoingSubscription;

  StreamSubscription<List<ReferralModel>>?
  _incomingSubscription;

  int _loadVersion = 0;

  @override
  void onInit() {
    super.onInit();
    loadReferrals();
  }

  // ---------------- Loading ----------------

  Future<void> loadReferrals() async {
    final int version = ++_loadVersion;

    await _cancelSubscriptions();

    if (isClosed || version != _loadVersion) return;

    isLoading.value = true;
    isLoadingOutgoing.value = true;
    isLoadingIncoming.value = false;
    loadError.value = null;

    outgoing.clear();
    incoming.clear();

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (isClosed || version != _loadVersion) return;

      if (!userDoc.exists) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final data = userDoc.data()!;

      if (data['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      final currentRole = data['role'] as String?;
      final currentOrg =
      data['organizationId'] as String?;
      final currentArea = data['areaId'] as String?;

      if (currentOrg == null ||
          !['supervisor', 'field_worker']
              .contains(currentRole)) {
        throw Exception('بيانات صلاحيات المستخدم غير مكتملة');
      }

      if (currentRole == 'field_worker' &&
          (currentArea == null || currentArea.isEmpty)) {
        throw Exception('منطقة الموظف غير محددة');
      }

      if (currentRole == 'field_worker') {
        selectedIncomingFilter.value = ReferralOptions.filterAll;
      }
      role.value = currentRole!;
      organizationId.value = currentOrg;
      areaId.value = currentArea ?? '';

      if (!isSupervisor) {
        tabIndex.value = 0;
      }

      // Outgoing referrals
      _outgoingSubscription =
          _repository.watchOutgoing(
            organizationId: currentOrg,
            areaId: isFieldWorker ? currentArea : null,
            createdBy: isFieldWorker ? user.uid : null,
          ).listen(
                (items) {
              if (isClosed || version != _loadVersion) return;

              outgoing.assignAll(items);
              isLoadingOutgoing.value = false;
              _updateLoadingState();
            },
            onError: (Object error) {
              if (isClosed || version != _loadVersion) return;

              isLoadingOutgoing.value = false;
              loadError.value = _errorMessage(error);
              _updateLoadingState();
            },
          );

      // Supervisor: all relevant incoming. Worker: accepted and later.
      if (isSupervisor || isFieldWorker) {
        isLoadingIncoming.value = true;

        _incomingSubscription =
            _repository.watchIncoming(
              organizationId: currentOrg,
              employeeOnly: isFieldWorker,
            ).listen(
                  (items) {
                if (isClosed || version != _loadVersion) {
                  return;
                }

                incoming.assignAll(items);
                isLoadingIncoming.value = false;
                _updateLoadingState();
              },
              onError: (Object error) {
                if (isClosed || version != _loadVersion) {
                  return;
                }

                isLoadingIncoming.value = false;
                loadError.value = _errorMessage(error);
                _updateLoadingState();
              },
            );
      }

      _updateLoadingState();
    } catch (e) {
      if (isClosed || version != _loadVersion) return;

      loadError.value = _errorMessage(e);
      isLoadingOutgoing.value = false;
      isLoadingIncoming.value = false;
      _updateLoadingState();
    }
  }

  void _updateLoadingState() {
    isLoading.value =
        isLoadingOutgoing.value ||
            isLoadingIncoming.value;
  }

  Future<void> _cancelSubscriptions() async {
    await _outgoingSubscription?.cancel();
    await _incomingSubscription?.cancel();

    _outgoingSubscription = null;
    _incomingSubscription = null;
  }

  // ---------------- Outgoing Filters ----------------

  List<ReferralModel> get visibleReferrals {
    return outgoing.where(_matchesFilter).toList();
  }

  bool _matchesFilter(ReferralModel referral) {
    switch (selectedFilter.value) {
      case ReferralOptions.filterPending:
        return referral.status ==
            ReferralStatus.pendingSourceApproval;

      case ReferralOptions.filterInProgress:
        return [
          ReferralStatus.pendingTargetApproval,
          ReferralStatus.accepted,
          ReferralStatus.inProgress,
        ].contains(referral.status);

      case ReferralOptions.filterCompleted:
        return referral.status ==
            ReferralStatus.completed;

      case ReferralOptions.filterOutgoingRejected:
        return referral.status ==
            ReferralStatus.rejectedBySource ||
            referral.status ==
                ReferralStatus.rejectedByTarget;

      default:
        return true;
    }
  }

  // ---------------- Incoming Filters ----------------

  List<ReferralModel> get filteredIncoming {
    final items = incoming
        .where(_matchesIncomingFilter)
        .toList();

    items.sort(
          (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return items;
  }

  bool _matchesIncomingFilter(ReferralModel referral) {
    switch (selectedIncomingFilter.value) {
      case ReferralOptions.filterWaitingDecision:
        return referral.status ==
            ReferralStatus.pendingTargetApproval;

      case ReferralOptions.filterUnderReview:
        return referral.status ==
            ReferralStatus.accepted ||
            referral.status ==
                ReferralStatus.inProgress;

      case ReferralOptions.filterServiceDone:
        return referral.status ==
            ReferralStatus.completed;

      case ReferralOptions.filterRejected:
        return referral.status ==
            ReferralStatus.rejectedByTarget;

      default:
        return true;
    }
  }

  List<ReferralModel> get displayedIncoming {
    final items = filteredIncoming;

    if (isFieldWorker || showAllIncoming.value || items.length <= 1) {
      return items;
    }

    return items.take(1).toList();
  }

  int get hiddenIncomingCount =>
      filteredIncoming.length -
          displayedIncoming.length;

  // ---------------- UI Actions ----------------

  void selectTab(int index) {
    if (index == 0 || index == 1) {
      tabIndex.value = index;
    }
  }

  void selectFilter(String filter) {
    selectedFilter.value = filter;
  }

  void resetFilter() {
    selectedFilter.value =
        ReferralOptions.filterAll;
  }

  void selectIncomingFilter(String filter) {
    selectedIncomingFilter.value = filter;
    showAllIncoming.value = false;
  }

  void showRestOfIncoming() {
    showAllIncoming.value = true;
  }

  // ---------------- Navigation ----------------

  void openReferral(ReferralModel referral) {
    if (tabIndex.value == 1) {
      Get.to(
            () => IncomingReferralReviewScreen(
          referral: referral,
          isSupervisor: isSupervisor,
        ),
      );
    } else {
      Get.to(
            () => ReferralDetailsScreen(
          referral: referral,
        ),
      );
    }
  }

  void openCreateReferral() {
    Get.to(() => CreateReferralScreen());
  }

  void backToSupervisorDashboard() {
    Get.back();
  }

  // ---------------- Error Handling ----------------

  String _errorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'لا تملك صلاحية لعرض هذه الإحالات';

        case 'unavailable':
          return 'تعذر الاتصال بخدمة Firebase';

        case 'failed-precondition':
          return 'قد يكون استعلام Firestore بحاجة إلى Index';

        default:
          return error.message ??
              'تعذر تحميل الإحالات';
      }
    }

    return error.toString().replaceFirst(
      'Exception: ',
      '',
    );
  }

  @override
  void onClose() {
    ++_loadVersion;
    _outgoingSubscription?.cancel();
    _incomingSubscription?.cancel();

    super.onClose();
  }
}
