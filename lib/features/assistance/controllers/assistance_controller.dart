
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';

import '../data/assistance_repository.dart';
import '../models/assistance_model.dart';
import '../models/assistance_assignment_model.dart';

class AssistanceController extends GetxController {
  final AssistanceRepository repository;
  final String organizationId;

  final RxList<AssistanceAssignmentModel>
  dashboardAssignments =
      <AssistanceAssignmentModel>[].obs;

  final RxBool isDashboardLoading = false.obs;

  final RxString dashboardError = ''.obs;

  AssistanceController({
    required this.repository,
    required this.organizationId,
  });

  final RxList<AssistanceModel> assistances =
      <AssistanceModel>[].obs;

  final RxList<String> selectedFamilyIds =
      <String>[].obs;

  final Rxn<AssistanceModel> selectedAssistance =
  Rxn<AssistanceModel>();

  final RxList<Map<String, dynamic>> assignmentResults =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isAssigning = false.obs;

  final RxString errorMessage = ''.obs;

  String? _pendingRequestId;
  String? _pendingAssistanceId;
  List<String>? _pendingFamilyIds;
  String? _pendingNotes;

  @override
  void onInit() {
    super.onInit();
    loadAssistances();
  }

  // Load active assistances.
  Future<void> loadAssistances() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result =
      await repository.getActiveAssistances(
        organizationId,
      );

      assistances.assignAll(result);
    } catch (e) {
      errorMessage.value = 'تعذر تحميل المساعدات';
    } finally {
      isLoading.value = false;
    }
  }

  // Select an assistance.
  void selectAssistance(AssistanceModel assistance) {
    selectedAssistance.value = assistance;
    assignmentResults.clear();
    _clearPendingRequest();
  }

  // Select/unselect one family.
  void toggleFamily(String familyId) {
    if (isAssigning.value) return;

    if (selectedFamilyIds.contains(familyId)) {
      selectedFamilyIds.remove(familyId);
    } else {
      selectedFamilyIds.add(familyId);
    }

    assignmentResults.clear();
    _clearPendingRequest();
  }

  // Select multiple families.
  void selectFamilies(List<String> familyIds) {
    if (isAssigning.value) return;

    selectedFamilyIds.assignAll(
      familyIds.toSet().toList(),
    );

    assignmentResults.clear();
    _clearPendingRequest();
  }

  void clearSelection() {
    if (isAssigning.value) return;

    selectedFamilyIds.clear();
    selectedAssistance.value = null;
    assignmentResults.clear();
    _clearPendingRequest();
  }

  // Assign the selected assistance.
  Future<void> assignSelectedAssistance({
    String notes = '',
  }) async {
    if (isAssigning.value) return;

    final assistance = selectedAssistance.value;

    if (assistance == null) {
      errorMessage.value = 'يرجى اختيار المساعدة';
      return;
    }

    if (!assistance.isActive) {
      errorMessage.value = 'هذه المساعدة غير متاحة';
      return;
    }

    if (selectedFamilyIds.isEmpty) {
      errorMessage.value = 'يرجى اختيار أسرة واحدة على الأقل';
      return;
    }

    final familyIds = selectedFamilyIds.toList();

    if (familyIds.length > 20) {
      errorMessage.value =
      'يمكن تخصيص المساعدة إلى 20 أسرة في العملية الواحدة';
      return;
    }

    try {
      isAssigning.value = true;
      errorMessage.value = '';

      // Keep the same ID when retrying an uncertain request.
      final sameRequest =
          _pendingAssistanceId == assistance.id &&
              _pendingNotes == notes &&
              _sameFamilies(_pendingFamilyIds, familyIds);

      if (!sameRequest || _pendingRequestId == null) {
        _pendingRequestId = FirebaseFirestore.instance.collection('_requestIds').doc().id;

        _pendingAssistanceId = assistance.id;
        _pendingFamilyIds = familyIds;
        _pendingNotes = notes;
      }

      final response = await repository.assignAssistance(
        organizationId: organizationId,
        assistanceId: assistance.id,
        familyIds: familyIds,
        requestId: _pendingRequestId!,
        notes: notes,
      );

      final rawResults =
          response['results'] as List<dynamic>? ?? [];

      assignmentResults.assignAll(
        rawResults.map(
              (item) => Map<String, dynamic>.from(
            item as Map,
          ),
        ),
      );

      // A complete response means this request is resolved.
      _clearPendingRequest();
    } on FirebaseFunctionsException catch (e) {
      errorMessage.value =
          e.message ?? 'تعذر تنفيذ التخصيص';
    } catch (e) {
      errorMessage.value =
      'تعذر الاتصال بالخادم. يمكن إعادة المحاولة.';
    } finally {
      isAssigning.value = false;
    }
  }

  bool _sameFamilies(
      List<String>? first,
      List<String> second,
      ) {
    if (first == null || first.length != second.length) {
      return false;
    }

    return first.toSet().containsAll(second);
  }

  void _clearPendingRequest() {
    _pendingRequestId = null;
    _pendingAssistanceId = null;
    _pendingFamilyIds = null;
    _pendingNotes = null;
  }

  int get successfulAssignments {
    return assignmentResults
        .where((item) => item['success'] == true)
        .length;
  }

  int get failedAssignments {
    return assignmentResults
        .where((item) => item['success'] != true)
        .length;
  }

  // Remove successful families from the current selection.
  void keepFailedFamiliesSelected() {
    if (isAssigning.value) return;

    final failedIds = assignmentResults
        .where((item) => item['success'] != true)
        .map((item) => item['familyId'] as String)
        .toList();

    selectedFamilyIds.assignAll(failedIds);
    _clearPendingRequest();
  }

  // Fetch assignment history for a family.
  Future<List<AssistanceAssignmentModel>>
  loadFamilyHistory(String familyId) {
    return repository.getFamilyAssignments(
      organizationId: organizationId,
      familyId: familyId,
    );
  }

  Future<void> loadDashboardAssignments() async {
    try {
      isDashboardLoading.value = true;
      dashboardError.value = '';

      final assignments =
      await repository.getDashboardAssignments(
        organizationId: organizationId,
      );

      dashboardAssignments.assignAll(assignments);
    } catch (e) {
      dashboardError.value =
      'تعذر تحميل عمليات المساعدات: $e';
    } finally {
      isDashboardLoading.value = false;
    }
  }

}
