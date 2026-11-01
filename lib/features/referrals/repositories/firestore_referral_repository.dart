
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
}
