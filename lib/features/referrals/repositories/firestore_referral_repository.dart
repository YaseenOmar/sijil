
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cloud_functions_referral_repository.dart';

class FirestoreReferralRepository
    extends CloudFunctionsReferralRepository {

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  FirestoreReferralRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        super(firestore: firestore);

  @override
  Future<String> createReferral({
    required String familyId,
    required String targetOrganizationId,
    required String targetServiceId,
    required String reason,
    required bool sharingConfirmed,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يرجى تسجيل الدخول أولًا');
    }

    if (!sharingConfirmed) {
      throw Exception('يجب تأكيد مشاركة بيانات الأسرة');
    }

    final cleanReason = reason.trim();

    if (cleanReason.isEmpty) {
      throw Exception('يرجى إدخال سبب الإحالة');
    }

    final userRef = _db.collection('users').doc(user.uid);

    final userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw Exception('بيانات المستخدم غير موجودة');
    }

    final userData = userSnapshot.data()!;

    final sourceOrgId =
    userData['organizationId'] as String?;

    final role = userData['role'] as String?;
    final userAreaId = userData['areaId'] as String?;

    if (userData['status'] != 'active' ||
        sourceOrgId == null ||
        sourceOrgId.isEmpty ||
        !['supervisor', 'field_worker'].contains(role)) {
      throw Exception('ليس لديك صلاحية لإنشاء الإحالة');
    }

    if (sourceOrgId == targetOrganizationId) {
      throw Exception('لا يمكن الإحالة إلى نفس المؤسسة');
    }

    if (role == 'field_worker' &&
        (userAreaId == null || userAreaId.isEmpty)) {
      throw Exception('لم يتم تحديد منطقة الموظف');
    }

    final familyRef = _db
        .collection('organizations')
        .doc(sourceOrgId)
        .collection('families')
        .doc(familyId);

    final sourceDirectoryRef = _db
        .collection('referralDirectory')
        .doc(sourceOrgId);

    final targetDirectoryRef = _db
        .collection('referralDirectory')
        .doc(targetOrganizationId);

    final serviceRef = _db
        .collection('organizations')
        .doc(targetOrganizationId)
        .collection('services')
        .doc(targetServiceId);

    final referralRef =
    _db.collection('referrals').doc();

    final eventRef =
    referralRef.collection('events').doc('created');

    Future<void> testRead(
        String name,
        DocumentReference<Map<String, dynamic>> ref,
        ) async {
      try {
        await ref.get(const GetOptions(source: Source.server));
        print('✅ READ SUCCESS: $name');
      } catch (e) {
        print('❌ READ FAILED: $name');
        print(e);
      }
    }

    await testRead('FAMILY', familyRef);
    await testRead('SOURCE DIRECTORY', sourceDirectoryRef);
    await testRead('TARGET DIRECTORY', targetDirectoryRef);
    await testRead('TARGET SERVICE', serviceRef);

    await _db.runTransaction((transaction) async {
      // All reads must come before writes.
      final familyDoc =
      await transaction.get(familyRef);

      final sourceDoc =
      await transaction.get(sourceDirectoryRef);

      final targetDoc =
      await transaction.get(targetDirectoryRef);

      final serviceDoc =
      await transaction.get(serviceRef);

      if (!familyDoc.exists) {
        throw Exception('الأسرة غير موجودة');
      }

      if (!sourceDoc.exists || !targetDoc.exists) {
        throw Exception('بيانات المؤسسة غير متوفرة');
      }

      if (!serviceDoc.exists) {
        throw Exception('الخدمة المطلوبة غير موجودة');
      }

      final family = familyDoc.data()!;
      final source = sourceDoc.data()!;
      final target = targetDoc.data()!;
      final service = serviceDoc.data()!;

      if (source['isActive'] != true ||
          target['isActive'] != true) {
        throw Exception('إحدى المؤسستين غير مفعّلة');
      }

      if (service['isActive'] != true ||
          service['acceptsReferrals'] != true) {
        throw Exception('الخدمة لا تستقبل الإحالات');
      }

      final familyAreaId =
      family['areaId'] as String?;

      if (familyAreaId == null ||
          familyAreaId.isEmpty) {
        throw Exception('منطقة الأسرة غير محددة');
      }

      if (role == 'field_worker' &&
          familyAreaId != userAreaId) {
        throw Exception(
          'لا يمكنك إحالة أسرة خارج منطقتك',
        );
      }

      String requiredText(
          Map<String, dynamic> data,
          String key,
          ) {
        final value = data[key];

        if (value is! String ||
            value.trim().isEmpty) {
          throw Exception('البيانات المطلوبة ناقصة: $key');
        }

        return value.trim();
      }

      final sourceName =
      requiredText(source, 'name');

      final targetName =
      requiredText(target, 'name');

      final serviceName =
      requiredText(service, 'name');

      final familySnapshot = <String, dynamic>{
        'headName':
        requiredText(family, 'headName'),
        'membersCount': family['membersCount'],
        'phoneNumber':
        requiredText(family, 'phoneNumber'),
        'address':
        requiredText(family, 'address'),
      };

      if (familySnapshot['membersCount'] is! int ||
          (familySnapshot['membersCount'] as int) < 1) {
        throw Exception('عدد أفراد الأسرة غير صالح');
      }

      final isSupervisor = role == 'supervisor';

      final status = isSupervisor
          ? 'pending_target_approval'
          : 'pending_source_approval';

      final now = FieldValue.serverTimestamp();

      transaction.set(referralRef, {
        // Temporary readable identifier.
        'number': referralRef.id,

        'sourceOrganizationId': sourceOrgId,
        'targetOrganizationId':
        targetOrganizationId,

        'sourceOrganizationName': sourceName,
        'targetOrganizationName': targetName,

        'sourceFamilyId': familyId,
        'familySnapshot': familySnapshot,
        'areaId': familyAreaId,

        'targetServiceId': targetServiceId,
        'serviceName': serviceName,

        'reason': cleanReason,
        'status': status,

        'createdBy': user.uid,
        'createdAt': now,
        'updatedAt': now,

        'sourceApprovedBy':
        isSupervisor ? user.uid : null,
        'sourceApprovedAt':
        isSupervisor ? now : null,

        'targetReviewedBy': null,
        'targetReviewedAt': null,

        'rejectionReason': null,
        'receivedFamilyId': null,

        'startedAt': null,
        'completedAt': null,
        'completedBy': null,

        'result': null,
        'resultNote': null,

        'sharingConfirmed': true,
        'sharingConfirmedAt': now,
      });

      transaction.set(eventRef, {
        'type': 'created',
        'actorId': user.uid,
        'createdAt': now,
      });
    });

    return referralRef.id;
  }

  Future<Map<String, dynamic>> _actor() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('يرجى تسجيل الدخول');
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || data['status'] != 'active') {
      throw Exception('الحساب غير فعال');
    }
    return {...data, 'uid': uid};
  }

  Future<void> _changeStatus({
    required String referralId,
    required String expected,
    required String next,
    required bool supervisor,
    required bool incoming,
    String? reason,
    String? result,
    String? resultNote,
  }) async {
    final actor = await _actor();
    final role = actor['role'];
    if (supervisor && role != 'supervisor') {
      throw Exception('هذه العملية للمشرف فقط');
    }
    if (!supervisor && role != 'field_worker') {
      throw Exception('هذه العملية للموظف فقط');
    }
    final uid = actor['uid'] as String;
    final orgId = actor['organizationId'] as String;
    final ref = _db.collection('referrals').doc(referralId);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) throw Exception('الإحالة غير موجودة');
      final data = doc.data()!;
      final orgField = incoming ? 'targetOrganizationId' : 'sourceOrganizationId';
      if (data[orgField] != orgId) throw Exception('الإحالة ليست تابعة لمؤسستك');
      if (data['status'] != expected) {
        throw Exception('تم تغيير حالة الإحالة، حدّث الصفحة');
      }
      if (expected == 'in_progress' && data['assignedTo'] != uid) {
        throw Exception('هذه الخدمة يستكملها الموظف الذي بدأها فقط');
      }
      final patch = <String, dynamic>{
        'status': next,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (expected == 'pending_source_approval') {
        if (next == 'pending_target_approval') {
          patch['sourceApprovedBy'] = uid;
          patch['sourceApprovedAt'] = FieldValue.serverTimestamp();
        } else {
          patch['rejectionReason'] = reason;
        }
      } else if (expected == 'pending_target_approval') {
        patch['targetReviewedBy'] = uid;
        patch['targetReviewedAt'] = FieldValue.serverTimestamp();
        if (next == 'rejected_by_target') patch['rejectionReason'] = reason;
        if (next == 'accepted') patch['receivedFamilyId'] = referralId;
      } else if (expected == 'accepted') {
        patch['assignedTo'] = uid;
        patch['assignedAt'] = FieldValue.serverTimestamp();
        patch['startedAt'] = FieldValue.serverTimestamp();
      } else if (expected == 'in_progress') {
        patch['completedBy'] = uid;
        patch['completedAt'] = FieldValue.serverTimestamp();
        patch['result'] = result;
        patch['resultNote'] = resultNote;
      }
      if (next == 'accepted') {
        final receivedRef = _db.collection('organizations').doc(orgId)
            .collection('receivedFamilies').doc(referralId);
        final family = Map<String, dynamic>.from(data['familySnapshot'] as Map);
        // All reads happen before writes.
        final oldFamily = await tx.get(receivedRef);
        if (!oldFamily.exists) {
          tx.set(receivedRef, {
            'sourceOrganizationId': data['sourceOrganizationId'],
            'sourceFamilyId': data['sourceFamilyId'],
            'targetOrganizationId': orgId,
            'headName': family['headName'],
            'membersCount': family['membersCount'],
            'phoneNumber': family['phoneNumber'],
            'address': family['address'],
            'areaId': data['areaId'],
            'firstReferralId': referralId,
            'receivedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      tx.update(ref, patch);
    });
  }

  @override
  Future<void> approveOutgoing(String referralId) => _changeStatus(
    referralId: referralId, expected: 'pending_source_approval',
    next: 'pending_target_approval', supervisor: true, incoming: false);

  @override
  Future<void> rejectOutgoing({required String referralId, required String reason}) => _changeStatus(
    referralId: referralId, expected: 'pending_source_approval',
    next: 'rejected_by_source', supervisor: true, incoming: false, reason: reason);

  @override
  Future<void> acceptIncoming(String referralId) => _changeStatus(
    referralId: referralId, expected: 'pending_target_approval',
    next: 'accepted', supervisor: true, incoming: true);

  @override
  Future<void> rejectIncoming({required String referralId, required String reason}) => _changeStatus(
    referralId: referralId, expected: 'pending_target_approval',
    next: 'rejected_by_target', supervisor: true, incoming: true, reason: reason);

  @override
  Future<void> startService(String referralId) => _changeStatus(
    referralId: referralId, expected: 'accepted',
    next: 'in_progress', supervisor: false, incoming: true);

  @override
  Future<void> completeService({required String referralId, required String result, String? resultNote}) => _changeStatus(
    referralId: referralId, expected: 'in_progress',
    next: 'completed', supervisor: false, incoming: true,
    result: result, resultNote: resultNote);

}
