import 'package:get/get.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/views/create_referral_screen.dart';
import 'package:sijil/features/referrals/views/incoming_referral_review_screen.dart';
import 'package:sijil/features/referrals/views/referral_details_screen.dart';

// Controller of the referrals list (outgoing / incoming tabs + status filters)
class ReferralsController extends GetxController {
  // 0 = outgoing, 1 = incoming
  final tabIndex = 0.obs;

  // Outgoing filter
  final selectedFilter = ReferralOptions.filterAll.obs;

  // Incoming filter (supervisor view)
  final selectedIncomingFilter = ReferralOptions.filterWaitingDecision.obs;

  // Only the latest incoming referral is shown until the supervisor asks for the rest
  final showAllIncoming = false.obs;

  final outgoing = <ReferralModel>[].obs;
  final incoming = <ReferralModel>[].obs;

  // ---------- UI states ----------
  final isLoading = false.obs;
  final loadError = RxnString();

  // ---------- Connection ----------
  // TODO: connect them with the connectivity and sync services
  final isOnline = true.obs;
  final lastSyncAt = ReferralDemoData.lastSyncAt.obs;

  @override
  void onInit() {
    super.onInit();
    loadReferrals();
  }

  // Referrals of the selected tab after applying the status filter
  List<ReferralModel> get visibleReferrals {
    if (tabIndex.value == 1) return filteredIncoming;

    return outgoing.where(_matchesFilter).toList();
  }

  // Incoming referrals after the status filter, latest received first
  List<ReferralModel> get filteredIncoming {
    final List<ReferralModel> items = incoming
        .where(_matchesIncomingFilter)
        .toList();

    items.sort((a, b) => _receivedTime(b).compareTo(_receivedTime(a)));

    return items;
  }

  // Incoming referrals shown on the screen
  List<ReferralModel> get displayedIncoming {
    final List<ReferralModel> items = filteredIncoming;

    if (showAllIncoming.value || items.length <= 1) return items;

    return items.take(1).toList();
  }

  int get hiddenIncomingCount =>
      filteredIncoming.length - displayedIncoming.length;

  DateTime _receivedTime(ReferralModel referral) =>
      referral.receivedAt ?? referral.createdAt;

  bool _matchesFilter(ReferralModel referral) {
    switch (selectedFilter.value) {
      case ReferralOptions.filterInProgress:
        return referral.status == ReferralStatus.sent ||
            referral.status == ReferralStatus.received ||
            referral.status == ReferralStatus.underReview;
      case ReferralOptions.filterPending:
        return referral.status == ReferralStatus.pendingSend;
      case ReferralOptions.filterCompleted:
        return referral.status == ReferralStatus.completed;
      default:
        return true;
    }
  }

  bool _matchesIncomingFilter(ReferralModel referral) {
    switch (selectedIncomingFilter.value) {
      case ReferralOptions.filterWaitingDecision:
        return referral.status == ReferralStatus.received;
      case ReferralOptions.filterUnderReview:
        return referral.status == ReferralStatus.underReview;
      case ReferralOptions.filterServiceDone:
        return referral.status == ReferralStatus.completed;
      case ReferralOptions.filterRejected:
        return referral.status == ReferralStatus.rejected;
      default:
        return true;
    }
  }

  void loadReferrals() {
    try {
      isLoading.value = true;
      loadError.value = null;

      // Temporary: demo data until referrals come from Firestore
      outgoing.assignAll(ReferralDemoData.outgoing);
      incoming.assignAll(ReferralDemoData.incoming);
    } catch (e) {
      loadError.value = 'تعذر تحميل الإحالات، يرجى المحاولة مرة أخرى';
    } finally {
      isLoading.value = false;
    }
  }

  void selectTab(int index) => tabIndex.value = index;

  void selectFilter(String filter) => selectedFilter.value = filter;

  void resetFilter() => selectedFilter.value = ReferralOptions.filterAll;

  void selectIncomingFilter(String filter) {
    selectedIncomingFilter.value = filter;
    showAllIncoming.value = false;
  }

  void showRestOfIncoming() => showAllIncoming.value = true;

  // Called after saving a new referral
  void addReferral(ReferralModel referral) {
    outgoing.insert(0, referral);
  }

  // Called after the receiving organization decides
  void updateReferral(ReferralModel updated) {
    final inIndex = incoming.indexWhere((item) => item.id == updated.id);
    if (inIndex != -1) incoming[inIndex] = updated;

    final outIndex = outgoing.indexWhere((item) => item.id == updated.id);
    if (outIndex != -1) outgoing[outIndex] = updated;
  }

  // ---------- Navigation ----------
  void openReferral(ReferralModel referral) {
    if (tabIndex.value == 1) {
      Get.to(() => IncomingReferralReviewScreen(referral: referral));
    } else {
      Get.to(() => ReferralDetailsScreen(referral: referral));
    }
  }

  void openCreateReferral() => Get.to(() => CreateReferralScreen());

  // TODO: open the supervisor dashboard when it is ready
  void backToSupervisorDashboard() => Get.back();
}
