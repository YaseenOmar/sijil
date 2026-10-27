import 'package:get/get.dart';
import 'package:sijil/features/referrals/constants/referral_demo_data.dart';
import 'package:sijil/features/referrals/constants/referral_options.dart';
import 'package:sijil/features/referrals/models/referral_model.dart';
import 'package:sijil/features/referrals/views/create_referral_screen.dart';
import 'package:sijil/features/referrals/views/incoming_referral_review_screen.dart';
import 'package:sijil/features/referrals/views/referral_details_screen.dart';

// Controller of the referrals list (outgoing / incoming tabs + status filter)
class ReferralsController extends GetxController {
  // 0 = outgoing, 1 = incoming
  final tabIndex = 0.obs;
  final selectedFilter = ReferralOptions.filterAll.obs;

  final outgoing = <ReferralModel>[].obs;
  final incoming = <ReferralModel>[].obs;

  // ---------- UI states ----------
  final isLoading = false.obs;
  final loadError = RxnString();

  @override
  void onInit() {
    super.onInit();
    loadReferrals();
  }

  // Referrals of the selected tab after applying the status filter
  List<ReferralModel> get visibleReferrals {
    final source = tabIndex.value == 0 ? outgoing : incoming;
    return source.where(_matchesFilter).toList();
  }

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
}
