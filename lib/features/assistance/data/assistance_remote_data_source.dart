import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sijil/features/service_catalog/data/models/service_model.dart';
import '../models/assistance_assignment_model.dart';
import '../models/assistance_eligibility_model.dart';

class AssistanceRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AssistanceRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  static const int maxFamiliesPerRequest = 20;
  static const int maxNotesLength = 500;


  Future<void> debugAssignmentPermissions({
    required String organizationId,
    required String serviceId,
    required String familyId,
    required String requestId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('المستخدم غير مسجل الدخول');
    }

    final assignmentId = '${requestId}_$familyId';

    final tests = <String,
        DocumentReference<Map<String, dynamic>>>{
      'USER': _firestore.collection('users').doc(user.uid),
      'SERVICE': _services(organizationId).doc(serviceId),
      'FAMILY': _families(organizationId).doc(familyId),
      'ELIGIBILITY': _eligibilityRef(
        organizationId: organizationId,
        familyId: familyId,
        serviceId: serviceId,
      ),
      'ASSIGNMENT': _assignments(
        organizationId,
      ).doc(assignmentId),
    };

    for (final entry in tests.entries) {
      try {
        final snapshot = await entry.value.get(
          const GetOptions(source: Source.server),
        );

        debugPrint(
          'PERMISSION TEST ${entry.key}: '
              'ALLOWED, exists=${snapshot.exists}',
        );
      } on FirebaseException catch (error) {
        debugPrint(
          'PERMISSION TEST ${entry.key}: '
              'DENIED, code=${error.code}',
        );
      }
    }
  }


  DocumentReference<Map<String, dynamic>> _organization(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId);
  }

  CollectionReference<Map<String, dynamic>> _services(
      String organizationId,
      ) {
    return _organization(organizationId).collection('services');
  }

  CollectionReference<Map<String, dynamic>> _families(
      String organizationId,
      ) {
    return _organization(organizationId).collection('families');
  }

  CollectionReference<Map<String, dynamic>> _assignments(
      String organizationId,
      ) {
    return _organization(organizationId)
        .collection('assistanceAssignments');
  }

  DocumentReference<Map<String, dynamic>> _eligibilityRef({
    required String organizationId,
    required String familyId,
    required String serviceId,
  }) {
    return _organization(organizationId)
        .collection('assistanceEligibility')
        .doc(familyId)
        .collection('services')
        .doc(serviceId);
  }

  bool _validId(String value) {
    return value.isNotEmpty &&
        value.length <= 120 &&
        value != '.' &&
        value != '..' &&
        !value.contains('/');
  }

  Future<Map<String, dynamic>> _authorizedProfile(
      String organizationId,
      ) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    final profile = snapshot.data();

    if (profile == null) {
      throw StateError('ملف المستخدم غير موجود');
    }

    if (profile['status'] != 'active') {
      throw StateError('حساب المستخدم غير فعال');
    }

    if (profile['organizationId'] != organizationId) {
      throw StateError('المؤسسة غير مطابقة');
    }

    final role = profile['role'];

    if (role != 'field_worker' && role != 'supervisor') {
      throw StateError('ليس لديك صلاحية');
    }

    if (role == 'field_worker') {
      final areaId = profile['areaId'];

      if (areaId is! String || !_validId(areaId)) {
        throw StateError('منطقة الموظف غير محددة');
      }
    }

    return profile;
  }

  Future<List<ServiceModel>> getActiveServices(
      String organizationId,
      ) async {
    await _authorizedProfile(organizationId);

    final snapshot = await _services(organizationId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => ServiceModel.fromMap(
        doc.data(),
        id: doc.id,
      ),
    )
        .toList();
  }

  Future<List<ServiceModel>> getAllServices(
      String organizationId,
      ) async {
    await _authorizedProfile(organizationId);

    final snapshot = await _services(organizationId).get();

    return snapshot.docs
        .map(
          (doc) => ServiceModel.fromMap(
        doc.data(),
        id: doc.id,
      ),
    )
        .toList();
  }

  Future<ServiceModel?> getServiceById({
    required String organizationId,
    required String serviceId,
  }) async {
    await _authorizedProfile(organizationId);

    final doc = await _services(organizationId)
        .doc(serviceId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ServiceModel.fromMap(
      doc.data()!,
      id: doc.id,
    );
  }

  Future<List<AssistanceAssignmentModel>> getFamilyAssignments({
    required String organizationId,
    required String familyId,
  }) async {
    final profile = await _authorizedProfile(organizationId);

    final familySnapshot = await _families(organizationId)
        .doc(familyId)
        .get();

    final family = familySnapshot.data();

    if (family == null) {
      throw StateError('الأسرة غير موجودة');
    }

    if (family['organizationId'] != organizationId) {
      throw StateError('الأسرة لا تتبع المؤسسة');
    }

    if (profile['role'] == 'field_worker' &&
        family['areaId'] != profile['areaId']) {
      throw StateError('الأسرة خارج نطاق صلاحياتك');
    }

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

  Future<AssistanceEligibilityModel?> getEligibility({
    required String organizationId,
    required String familyId,
    required String serviceId,
  }) async {
    await _authorizedProfile(organizationId);

    final doc = await _eligibilityRef(
      organizationId: organizationId,
      familyId: familyId,
      serviceId: serviceId,
    ).get();

    if (!doc.exists) {
      return null;
    }

    return AssistanceEligibilityModel.fromFirestore(doc);
  }


  Future<Map<String, dynamic>> assignAssistance({
    required String organizationId,
    required String serviceId,
    required List<String> familyIds,
    required String requestId,
    String notes = '',
  }) async {
    if (!_validId(organizationId) ||
        !_validId(serviceId) ||
        !_validId(requestId)) {
      throw ArgumentError('معرفات طلب التخصيص غير صحيحة');
    }

    final uniqueFamilies = familyIds.toSet().toList()
      ..sort();

    if (uniqueFamilies.isEmpty ||
        uniqueFamilies.length > maxFamiliesPerRequest ||
        !uniqueFamilies.every(_validId)) {
      throw ArgumentError(
        'يجب اختيار من أسرة واحدة إلى 20 أسرة',
      );
    }

    if (notes.length > maxNotesLength) {
      throw ArgumentError(
        'الملاحظات يجب ألا تتجاوز 500 حرف',
      );
    }

    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('يجب تسجيل الدخول أولاً');
    }

    await _authorizedProfile(organizationId);

    final results = <Map<String, dynamic>>[];

    final serviceRef = _services(
      organizationId,
    ).doc(serviceId);

    final userRef = _firestore
        .collection('users')
        .doc(user.uid);

    for (final familyId in uniqueFamilies) {
      final assignmentId = '${requestId}_$familyId';

      final assignmentRef = _assignments(
        organizationId,
      ).doc(assignmentId);

      final familyRef = _families(
        organizationId,
      ).doc(familyId);

      final eligibilityRef = _eligibilityRef(
        organizationId: organizationId,
        familyId: familyId,
        serviceId: serviceId,
      );

      try {
        final result =
        await _firestore.runTransaction<Map<String, dynamic>>(
              (transaction) async {
            // All reads must be completed before writes.
            final userSnap =
            await transaction.get(userRef);

            final assignmentSnap =
            await transaction.get(assignmentRef);

            final serviceSnap =
            await transaction.get(serviceRef);

            final familySnap =
            await transaction.get(familyRef);

            final eligibilitySnap =
            await transaction.get(eligibilityRef);

            final profile = userSnap.data();
            final existingAssignment =
            assignmentSnap.data();

            final service = serviceSnap.data();
            final family = familySnap.data();

            if (profile == null ||
                profile['status'] != 'active' ||
                profile['organizationId'] !=
                    organizationId) {
              throw StateError(
                'حساب المستخدم غير فعال أو لا يتبع المؤسسة',
              );
            }

            final role = profile['role'];

            if (role != 'supervisor' &&
                role != 'field_worker') {
              throw StateError(
                'ليس لديك صلاحية تخصيص المساعدة',
              );
            }

            // ====================================
            // Idempotency
            // ====================================

            if (existingAssignment != null) {
              final sameAssignment =
                  existingAssignment['organizationId'] ==
                      organizationId &&
                      existingAssignment['serviceId'] ==
                          serviceId &&
                      existingAssignment['familyId'] ==
                          familyId &&
                      existingAssignment['assignedBy'] ==
                          user.uid &&
                      existingAssignment['notes'] == notes;

              if (!sameAssignment) {
                throw StateError(
                  'معرف الطلب مستخدم لتخصيص مختلف',
                );
              }

              return {
                'familyId': familyId,
                'success': true,
                'assignmentId': assignmentId,
                'alreadyProcessed': true,
                'message':
                'تم تخصيص هذه المساعدة مسبقًا ضمن نفس الطلب',
              };
            }

            // ====================================
            // Service Checks
            // ====================================

            if (service == null) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'service_not_found',
                'message': 'الخدمة غير موجودة',
              };
            }

            if (service['isActive'] != true) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'service_inactive',
                'message': 'الخدمة غير فعالة',
              };
            }

            if (service['organizationId'] !=
                organizationId) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'invalid_service_organization',
                'message': 'الخدمة لا تتبع المؤسسة',
              };
            }

            // ====================================
            // Family Checks
            // ====================================

            if (family == null) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'family_not_found',
                'message': 'الأسرة غير موجودة',
              };
            }

            if (family['organizationId'] !=
                organizationId ||
                (role == 'field_worker' &&
                    family['areaId'] !=
                        profile['areaId'])) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'permission_denied',
                'message':
                'الأسرة خارج نطاق صلاحياتك',
              };
            }

            // ====================================
            // Cooldown Checks
            // ====================================

            final hasCooldown =
                service['hasCooldown'] == true;

            final cooldownValue =
            service['cooldownDays'];

            if (hasCooldown &&
                (cooldownValue is! int ||
                    cooldownValue <= 0 ||
                    cooldownValue > 36500)) {
              return {
                'familyId': familyId,
                'success': false,
                'code': 'invalid_cooldown',
                'message':
                'فترة منع التكرار غير صحيحة',
              };
            }

            final cooldownDays = hasCooldown
                ? cooldownValue as int
                : 0;

            final now = DateTime.now().toUtc();

            final eligibility =
            eligibilitySnap.data();

            if (hasCooldown && eligibility != null) {
              final previousNextEligible =
              eligibility['nextEligibleAt'];

              if (previousNextEligible is! Timestamp) {
                return {
                  'familyId': familyId,
                  'success': false,
                  'code': 'invalid_eligibility',
                  'message':
                  'بيانات أهلية الأسرة غير صحيحة',
                };
              }

              if (previousNextEligible
                  .toDate()
                  .isAfter(now)) {
                final lastAssigned =
                eligibility['lastAssignedAt'];

                return {
                  'familyId': familyId,
                  'success': false,
                  'code': 'cooldown_active',
                  'message':
                  'الأسرة ضمن فترة منع تكرار هذه الخدمة',
                  'lastAssignmentId':
                  eligibility['lastAssignmentId'],
                  'lastAssignedAt':
                  lastAssigned is Timestamp
                      ? lastAssigned
                      .toDate()
                      .toIso8601String()
                      : null,
                  'nextEligibleAt':
                  previousNextEligible
                      .toDate()
                      .toIso8601String(),
                };
              }
            }

            // ====================================
            // Atomic Writes
            // ====================================

            final assignedAt =
            Timestamp.fromDate(now);

            final nextEligibleAt = hasCooldown
                ? Timestamp.fromDate(
              now.add(
                Duration(days: cooldownDays),
              ),
            )
                : null;

            transaction.set(assignmentRef, {
              'organizationId': organizationId,
              'serviceId': serviceId,
              'familyId': familyId,
              'areaId': family['areaId'],
              'assignedBy': user.uid,
              'assignedAt': assignedAt,
              'nextEligibleAt': nextEligibleAt,
              'status': 'assigned',
              'notes': notes,
            });

            // Always update the deterministic
            // eligibility document in the same
            // transaction.
            transaction.set(eligibilityRef, {
              'familyId': familyId,
              'serviceId': serviceId,
              'lastAssignmentId': assignmentId,
              'lastAssignedAt': assignedAt,
              'nextEligibleAt':
              nextEligibleAt ?? assignedAt,
            });

            return {
              'familyId': familyId,
              'success': true,
              'assignmentId': assignmentId,
              'alreadyProcessed': false,
              'message':
              'تم تخصيص المساعدة بنجاح',
            };
          },
          maxAttempts: 5,
        );

        results.add(result);

      } on FirebaseException catch (error, stackTrace) {
        debugPrint('========== ASSISTANCE ERROR ==========');
        debugPrint('Family ID: $familyId');
        debugPrint('Service ID: $serviceId');
        debugPrint('Request ID: $requestId');
        debugPrint('Firebase Code: ${error.code}');
        debugPrint('Firebase Message: ${error.message}');
        debugPrint('Firebase Plugin: ${error.plugin}');
        debugPrintStack(stackTrace: stackTrace);
        debugPrint('======================================');

        final isPermissionDenied =
            error.code == 'permission-denied';

        results.add({
          'familyId': familyId,
          'success': false,
          'pendingVerification': !isPermissionDenied,
          'code': error.code,
          'message': isPermissionDenied
              ? 'تم رفض التخصيص بسبب صلاحيات Firestore'
              : 'تعذر التأكد من نتيجة التخصيص: '
              '${error.message ?? error.code}',
        });
      } catch (error, stackTrace) {
        debugPrint('========== ASSISTANCE ERROR ==========');
        debugPrint('Family ID: $familyId');
        debugPrint('Error: $error');
        debugPrintStack(stackTrace: stackTrace);
        debugPrint('======================================');

        results.add({
          'familyId': familyId,
          'success': false,
          'pendingVerification': true,
          'code': 'unknown_outcome',
          'message': 'تعذر التأكد من نتيجة التخصيص',
        });
      }

    }

    final successfulCount = results
        .where((result) => result['success'] == true)
        .length;

    final failedCount = results
        .where(
          (result) =>
      result['success'] == false &&
          result['pendingVerification'] != true,
    )
        .length;

    final pendingCount = results
        .where(
          (result) =>
      result['pendingVerification'] == true,
    )
        .length;

    return {
      'requestId': requestId,
      'results': results,
      'successfulCount': successfulCount,
      'failedCount': failedCount,
      'pendingCount': pendingCount,
      'hasPendingVerification': pendingCount > 0,
    };
  }


  Future<List<AssistanceAssignmentModel>>
  getDashboardAssignments({
    required String organizationId,
  }) async {
    final profile =
    await _authorizedProfile(organizationId);

    Query<Map<String, dynamic>> query =
    _assignments(organizationId);

    if (profile['role'] == 'field_worker') {
      query = query.where(
        'areaId',
        isEqualTo: profile['areaId'],
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
