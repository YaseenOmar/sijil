
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assistance_model.dart';
import '../models/assistance_assignment_model.dart';
import '../models/assistance_eligibility_model.dart';

class AssistanceRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  AssistanceRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(
              region: 'us-central1',
            );

  CollectionReference<Map<String, dynamic>> _assistances(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('assistances');
  }

  CollectionReference<Map<String, dynamic>> _assignments(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('assistanceAssignments');
  }

  CollectionReference<Map<String, dynamic>> _eligibility(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('assistanceEligibility');
  }

  // Fetch active assistances.
  Future<List<AssistanceModel>> getActiveAssistances(
      String organizationId,
      ) async {
    final snapshot = await _assistances(organizationId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(AssistanceModel.fromFirestore)
        .toList();
  }

  // Fetch all assistances (including inactive).
  Future<List<AssistanceModel>> getAllAssistances(
      String organizationId,
      ) async {
    final snapshot =
    await _assistances(organizationId).get();

    return snapshot.docs
        .map(AssistanceModel.fromFirestore)
        .toList();
  }

  // Fetch one assistance.
  Future<AssistanceModel?> getAssistanceById({
    required String organizationId,
    required String assistanceId,
  }) async {
    final doc = await _assistances(
      organizationId,
    ).doc(assistanceId).get();

    if (!doc.exists) return null;

    return AssistanceModel.fromFirestore(doc);
  }

  // Fetch assignment history for one family.
  Future<List<AssistanceAssignmentModel>>
  getFamilyAssignments({
    required String organizationId,
    required String familyId,
  }) async {
    final snapshot = await _assignments(organizationId)
        .where('familyId', isEqualTo: familyId)
        .get();

    final assignments = snapshot.docs
        .map(AssistanceAssignmentModel.fromFirestore)
        .toList();

    assignments.sort(
          (a, b) => b.assignedAt.compareTo(a.assignedAt),
    );

    return assignments;
  }

  // Fetch the eligibility document using its ID.
  Future<AssistanceEligibilityModel?> getEligibility({
    required String organizationId,
    required String eligibilityId,
  }) async {
    final doc = await _eligibility(
      organizationId,
    ).doc(eligibilityId).get();

    if (!doc.exists) return null;

    return AssistanceEligibilityModel.fromFirestore(doc);
  }

  // Send an assignment request to the trusted backend.
  Future<Map<String, dynamic>> assignAssistance({
    required String organizationId,
    required String assistanceId,
    required List<String> familyIds,
    required String requestId,
    String notes = '',
  }) async {
    final callable = _functions.httpsCallable(
      'assignAssistance',
      options: HttpsCallableOptions(
        timeout: const Duration(seconds: 120),
      ),
    );

    final response = await callable.call({
      'organizationId': organizationId,
      'assistanceId': assistanceId,
      'familyIds': familyIds,
      'requestId': requestId,
      'notes': notes,
    });

    return Map<String, dynamic>.from(
      response.data as Map,
    );
  }

  Future<List<AssistanceAssignmentModel>>
  getDashboardAssignments({
    required String organizationId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      throw StateError('ملف المستخدم غير موجود');
    }

    final profile = userDoc.data()!;

    if (profile['organizationId'] != organizationId) {
      throw StateError('المؤسسة غير مطابقة');
    }

    if (profile['status'] != 'active') {
      throw StateError('حساب المستخدم غير فعال');
    }

    final role = profile['role'] as String?;
    final areaId = profile['areaId'] as String?;

    if (!['employee', 'supervisor', 'manager'].contains(role)) {
      throw StateError('ليس لديك صلاحية عرض المساعدات');
    }

    Query<Map<String, dynamic>> query =
    _assignments(organizationId);

    if (role == 'employee') {
      if (areaId == null || areaId.isEmpty) {
        throw StateError('منطقة الموظف غير محددة');
      }

      query = query.where(
        'areaId',
        isEqualTo: areaId,
      );
    }

    final snapshot = await query
        .orderBy('assignedAt', descending: true)
        .limit(100)
        .get();

    return snapshot.docs
        .map(AssistanceAssignmentModel.fromFirestore)
        .toList();
  }

}
