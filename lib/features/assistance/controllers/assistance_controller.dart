
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:sijil/features/service_catalog/data/models/service_model.dart';

import '../data/assistance_repository.dart';
import '../models/assistance_assignment_model.dart';

class AssistanceController extends GetxController {
  final AssistanceRepository repository;
  final String organizationId;
  static const int maxFamiliesPerRequest = 20;
  AssistanceController({
    required this.repository,
    required this.organizationId,
  });

  // ==========================================
  // Services
  // ==========================================

  final RxList<ServiceModel> services = <ServiceModel>[].obs;

  final Rxn<ServiceModel> selectedService = Rxn<ServiceModel>();

  final RxBool isLoading = false.obs;

  final RxString errorMessage = ''.obs;

  // ==========================================
  // Family Selection
  // ==========================================

  final RxList<String> selectedFamilyIds = <String>[].obs;

  // ==========================================
  // Assignment State
  // ==========================================

  final RxBool isAssigning = false.obs;

  final RxList<Map<String, dynamic>> assignmentResults =
      <Map<String, dynamic>>[].obs;

  // Preserve request identity when a transaction
  // fails with an uncertain commit outcome.
  String? _pendingRequestId;
  String? _pendingServiceId;
  List<String>? _pendingFamilyIds;
  String? _pendingNotes;

  // ==========================================
  // Dashboard
  // ==========================================

  final RxList<AssistanceAssignmentModel>
  dashboardAssignments =
      <AssistanceAssignmentModel>[].obs;

  final RxBool isDashboardLoading = false.obs;

  final RxString dashboardError = ''.obs;

  // ==========================================
  // Initialization
  // ==========================================

  @override
  void onInit() {
    super.onInit();
    loadServices();
  }

  // ==========================================
  // Load Services
  // ==========================================

  Future<void> loadServices() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final result = await repository.getActiveServices(
        organizationId,
      );

      services.assignAll(result);

      final current = selectedService.value;

      if (current != null) {
        final matching = result.where(
              (service) => service.id == current.id,
        );

        if (matching.isEmpty) {
          selectedService.value = null;
          _clearPendingRequest();
        } else {
          selectedService.value = matching.first;
        }
      }
    } catch (error) {
      errorMessage.value =
      'تعذر تحميل الخدمات: ${_errorText(error)}';
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================
  // Select Service
  // ==========================================

  void selectService(ServiceModel service) {
    if (isAssigning.value) return;

    if (selectedService.value?.id == service.id) {
      return;
    }

    selectedService.value = service;

    assignmentResults.clear();
    errorMessage.value = '';

    _clearPendingRequest();
  }

  // ==========================================
  // Select Families
  // ==========================================

  void toggleFamily(String familyId) {
    if (isAssigning.value) return;

    if (selectedFamilyIds.contains(familyId)) {
      selectedFamilyIds.remove(familyId);
    } else {
      if (selectedFamilyIds.length > maxFamiliesPerRequest) {
        errorMessage.value =
        'يمكن اختيار 20 أسرة كحد أقصى';
        return;
      }

      selectedFamilyIds.add(familyId);
    }

    errorMessage.value = '';
    assignmentResults.clear();

    _clearPendingRequest();
  }

  void selectFamilies(List<String> familyIds) {
    if (isAssigning.value) return;

    final uniqueIds = familyIds.toSet().toList();

    if (uniqueIds.length > 20) {
      errorMessage.value =
      'يمكن اختيار 20 أسرة كحد أقصى';
      return;
    }

    selectedFamilyIds.assignAll(uniqueIds);

    assignmentResults.clear();
    errorMessage.value = '';

    _clearPendingRequest();
  }

  void clearSelection() {
    if (isAssigning.value) return;

    selectedFamilyIds.clear();
    selectedService.value = null;

    assignmentResults.clear();
    errorMessage.value = '';

    _clearPendingRequest();
  }

  // ==========================================
  // Assign Selected Service
  // ==========================================

  Future<void> assignSelectedAssistance({
    String notes = '',
  }) async {
    if (isAssigning.value) return;

    errorMessage.value = '';

    final service = selectedService.value;

    if (service == null) {
      errorMessage.value = 'يرجى اختيار الخدمة';
      return;
    }

    if (!service.isActive) {
      errorMessage.value =
      'الخدمة المختارة غير فعالة';
      return;
    }

    if (selectedFamilyIds.isEmpty) {
      errorMessage.value =
      'يرجى اختيار أسرة واحدة على الأقل';
      return;
    }

    if (selectedFamilyIds.length > 20) {
      errorMessage.value =
      'يمكن تخصيص الخدمة إلى 20 أسرة كحد أقصى';
      return;
    }

    if (notes.length > 500) {
      errorMessage.value =
      'الملاحظات يجب ألا تتجاوز 500 حرف';
      return;
    }

    final familyIds = selectedFamilyIds.toSet().toList()
      ..sort();

    try {
      isAssigning.value = true;
      assignmentResults.clear();

      final isSamePendingRequest =
          _pendingRequestId != null &&
              _pendingServiceId == service.id &&
              _pendingNotes == notes &&
              _sameFamilies(
                _pendingFamilyIds,
                familyIds,
              );

      if (!isSamePendingRequest) {
        _pendingRequestId = FirebaseFirestore.instance
            .collection('_requestIds')
            .doc()
            .id;

        _pendingServiceId = service.id;
        _pendingFamilyIds = List<String>.from(familyIds);
        _pendingNotes = notes;
      }

      final response = await repository.assignAssistance(
        organizationId: organizationId,
        serviceId: service.id,
        familyIds: familyIds,
        requestId: _pendingRequestId!,
        notes: notes,
      );

      final rawResults =
          response['results'] as List<dynamic>? ?? [];

      final parsedResults = rawResults.map((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      // Never treat an incomplete response as a
      // completely resolved assignment request.
      if (parsedResults.length != familyIds.length) {
        throw StateError(
          'نتيجة التخصيص غير مكتملة. '
              'أعد المحاولة بنفس الطلب.',
        );
      }


      assignmentResults.assignAll(parsedResults);

      final hasPendingVerification =
          response['hasPendingVerification'] == true;

      if (hasPendingVerification) {
        errorMessage.value =
        'تعذر التأكد من نتيجة بعض الأسر. '
            'يمكن إعادة المحاولة بنفس الطلب '
            'دون إنشاء تخصيص جديد.';

        // Preserve requestId for safe retry.
      } else {
        // Every family's result is known.
        _clearPendingRequest();
      }


      // Refresh the dashboard only after the
      // assignment request has completed.
      await loadDashboardAssignments();
    } catch (error) {
      errorMessage.value =
      'تعذر إكمال التخصيص: ${_errorText(error)}. '
          'يمكن إعادة المحاولة دون تغيير الأسر '
          'أو الخدمة أو الملاحظات.';

      // Do not clear _pendingRequestId here.
      // A previous transaction might already
      // have committed successfully.
    } finally {
      isAssigning.value = false;
    }
  }

  // ==========================================
  // Assignment Results
  // ==========================================

  int get successfulAssignments {
    return assignmentResults
        .where((result) => result['success'] == true)
        .length;
  }

  int get failedAssignments {
    return assignmentResults
        .where((result) => result['success'] == false)
        .length;
  }

  bool get hasAssignmentResults {
    return assignmentResults.isNotEmpty;
  }

  bool get hasCooldownFailures {
    return assignmentResults.any(
          (result) =>
      result['success'] == false &&
          result['code'] == 'cooldown_active',
    );
  }

  Map<String, dynamic>? cooldownResultForFamily(
      String familyId,
      ) {
    for (final result in assignmentResults) {
      if (result['familyId'] == familyId &&
          result['code'] == 'cooldown_active') {
        return result;
      }
    }

    return null;
  }

  // Keep only unsuccessful families selected.
  // This is intended for an explicit user action,
  // not automatic retry of an uncertain request.
  void keepFailedFamiliesSelected() {
    if (isAssigning.value) return;

    if (assignmentResults.isEmpty) return;

    final failedIds = assignmentResults
        .where((result) => result['success'] == false)
        .map((result) => result['familyId'])
        .whereType<String>()
        .toList();

    selectedFamilyIds.assignAll(failedIds);

    assignmentResults.clear();

    _clearPendingRequest();
  }

  // ==========================================
  // Family History
  // ==========================================

  Future<List<AssistanceAssignmentModel>>
  loadFamilyHistory(String familyId) {
    return repository.getFamilyAssignments(
      organizationId: organizationId,
      familyId: familyId,
    );
  }

  // ==========================================
  // Dashboard
  // ==========================================

  Future<void> loadDashboardAssignments() async {
    try {
      isDashboardLoading.value = true;
      dashboardError.value = '';

      final result =
      await repository.getDashboardAssignments(
        organizationId: organizationId,
      );

      dashboardAssignments.assignAll(result);
    } catch (error) {
      dashboardError.value =
      'تعذر تحميل عمليات المساعدات: '
          '${_errorText(error)}';
    } finally {
      isDashboardLoading.value = false;
    }
  }

  // ==========================================
  // Private Helpers
  // ==========================================

  bool _sameFamilies(
      List<String>? first,
      List<String> second,
      ) {
    if (first == null ||
        first.length != second.length) {
      return false;
    }

    return first.toSet().containsAll(second);
  }

  void _clearPendingRequest() {
    _pendingRequestId = null;
    _pendingServiceId = null;
    _pendingFamilyIds = null;
    _pendingNotes = null;
  }

  String _errorText(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية لتنفيذ العملية';

        case 'unavailable':
          return 'تعذر الاتصال بـ Firebase';

        case 'deadline-exceeded':
          return 'انتهت مهلة الاتصال';

        case 'failed-precondition':
          return 'شروط تنفيذ العملية غير مكتملة';

        case 'aborted':
          return 'حدث تعارض أثناء التخصيص';

        default:
          return error.message ?? error.code;
      }
    }

    if (error is StateError) {
      return error.message.toString();
    }

    if (error is ArgumentError) {
      return error.message?.toString() ??
          'بيانات الطلب غير صحيحة';
    }

    return error.toString();
  }
}
