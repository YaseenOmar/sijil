
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/referral_model.dart';
import '../models/received_family_model.dart';

class ReferralRepository {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  ReferralRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  CollectionReference<Map<String, dynamic>> get _referrals =>
      _firestore.collection('referrals');

  // ---------------- Reading ----------------

  Stream<List<ReferralModel>> watchOutgoing({
    required String organizationId,
    String? areaId,
  }) {
    Query<Map<String, dynamic>> query = _referrals.where(
      'sourceOrganizationId',
      isEqualTo: organizationId,
    );

    if (areaId != null) {
      query = query.where('areaId', isEqualTo: areaId);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map(_referralFromDocument)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    );
  }

  Stream<List<ReferralModel>> watchIncoming({
    required String organizationId,
  }) {
    return _referrals
        .where(
      'targetOrganizationId',
      isEqualTo: organizationId,
    )
        .where(
      'status',
      whereIn: const [
        'pending_target_approval',
        'rejected_by_target',
        'accepted',
        'in_progress',
        'completed',
      ],
    )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(_referralFromDocument)
          .toList()
        ..sort(
              (a, b) => b.createdAt.compareTo(a.createdAt),
        ),
    );
  }

  Stream<ReferralModel?> watchReferral(String referralId) {
    return _referrals.doc(referralId).snapshots().map(
          (document) {
        if (!document.exists) return null;
        return _referralFromDocument(document);
      },
    );
  }

  Stream<List<ReceivedFamilyModel>> watchReceivedFamilies({
    required String organizationId,
  }) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('receivedFamilies')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
          .map(_receivedFamilyFromDocument)
          .toList()
        ..sort(
              (a, b) => b.receivedAt.compareTo(a.receivedAt),
        ),
    );
  }


  Stream<List<ReferralStep>> watchReferralSteps(
      String referralId,
      ) {
    return _referrals
        .doc(referralId)
        .collection('events')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      final steps = <ReferralStep>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final timestamp = data['createdAt'];

        // Skip events without a committed server timestamp.
        if (timestamp is! Timestamp) continue;

        final type = data['type'] as String?;
        final actor = _eventActor(type);

        final title = _eventTitle(type);

        if (title == null) continue;

        steps.add(
          ReferralStep(
            title: title,
            at: timestamp.toDate(),
            actor: actor,
          ),
        );
      }

      steps.sort((a, b) => a.at.compareTo(b.at));
      return steps;
    });
  }

  String? _eventTitle(String? type) {
    switch (type) {
      case 'created':
        return 'تم إنشاء طلب الإحالة';

      case 'source_approved':
        return 'وافق مشرف المؤسسة المرسلة';

      case 'source_rejected':
        return 'رفض مشرف المؤسسة المرسلة';

      case 'target_accepted':
        return 'قبلت المؤسسة المستقبلة الإحالة';

      case 'target_rejected':
        return 'رفضت المؤسسة المستقبلة الإحالة';

      case 'service_started':
        return 'بدأ تقديم الخدمة';

      case 'service_completed':
        return 'تم تقديم الخدمة';

      default:
        return null;
    }
  }


  // ---------------- Cloud Functions ----------------

  Future<String> createReferral({
    required String familyId,
    required String targetOrganizationId,
    required String targetServiceId,
    required String reason,
    required bool sharingConfirmed,
  }) async {
    final result = await _call('createReferral', {
      'familyId': familyId,
      'targetOrganizationId': targetOrganizationId,
      'targetServiceId': targetServiceId,
      'reason': reason,
      'sharingConfirmed': sharingConfirmed,
    });

    return result['referralId'] as String;
  }

  Future<void> approveOutgoing(String referralId) async {
    await _call('approveOutgoingReferral', {
      'referralId': referralId,
    });
  }

  Future<void> rejectOutgoing({
    required String referralId,
    required String reason,
  }) async {
    await _call('rejectOutgoingReferral', {
      'referralId': referralId,
      'reason': reason,
    });
  }

  Future<void> acceptIncoming(String referralId) async {
    await _call('acceptIncomingReferral', {
      'referralId': referralId,
    });
  }

  Future<void> rejectIncoming({
    required String referralId,
    required String reason,
  }) async {
    await _call('rejectIncomingReferral', {
      'referralId': referralId,
      'reason': reason,
    });
  }

  Future<void> startService(String referralId) async {
    await _call('startReferralService', {
      'referralId': referralId,
    });
  }

  Future<void> completeService({
    required String referralId,
    required String result,
    String? resultNote,
  }) async {
    await _call('completeReferralService', {
      'referralId': referralId,
      'result': result,
      'resultNote': resultNote,
    });
  }


  Future<Map<String, dynamic>> _call(
      String name,
      Map<String, dynamic> data,
      ) async {
    final response = await _functions
        .httpsCallable(name)
        .call<dynamic>(data);

    final result = response.data;

    if (result is! Map) {
      throw const FormatException(
        'Invalid Cloud Function response',
      );
    }

    return Map<String, dynamic>.from(result);
  }


  // ---------------- Firestore Mapping ----------------

  ReferralModel _referralFromDocument(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data()!;

    final family = Map<String, dynamic>.from(
      data['familySnapshot'] as Map,
    );

    return ReferralModel(
      id: document.id,
      number: data['number'] as String,
      sourceOrganizationId:
      data['sourceOrganizationId'] as String,
      targetOrganizationId:
      data['targetOrganizationId'] as String,
      sourceOrganizationName:
      data['sourceOrganizationName'] as String,
      targetOrganizationName:
      data['targetOrganizationName'] as String,
      sourceFamilyId: data['sourceFamilyId'] as String,
      familyName: family['headName'] as String,
      membersCount: family['membersCount'] as int,
      contactPhone: family['phoneNumber'] as String,
      address: family['address'] as String,
      areaId: data['areaId'] as String,
      targetServiceId: data['targetServiceId'] as String,
      serviceName: data['serviceName'] as String,
      reason: data['reason'] as String,
      status: ReferralStatusExtension.fromValue(
        data['status'] as String,
      ),
      createdBy: data['createdBy'] as String,
      createdAt: _requiredDate(data['createdAt']),
      updatedAt: _requiredDate(data['updatedAt']),
      sourceApprovedBy: data['sourceApprovedBy'] as String?,
      sourceApprovedAt: _optionalDate(data['sourceApprovedAt']),
      targetReviewedBy: data['targetReviewedBy'] as String?,
      targetReviewedAt: _optionalDate(data['targetReviewedAt']),
      rejectionReason: data['rejectionReason'] as String?,
      receivedFamilyId: data['receivedFamilyId'] as String?,
      startedAt: _optionalDate(data['startedAt']),
      completedAt: _optionalDate(data['completedAt']),
      completedBy: data['completedBy'] as String?,
      result: data['result'] as String?,
      resultNote: data['resultNote'] as String?,
      sharingConfirmed: data['sharingConfirmed'] as bool,
      sharingConfirmedAt:
      _optionalDate(data['sharingConfirmedAt']),
    );
  }

  ReceivedFamilyModel _receivedFamilyFromDocument(
      DocumentSnapshot<Map<String, dynamic>> document,
      ) {
    final data = document.data()!;

    return ReceivedFamilyModel(
      id: document.id,
      sourceOrganizationId:
      data['sourceOrganizationId'] as String,
      sourceFamilyId: data['sourceFamilyId'] as String,
      targetOrganizationId:
      data['targetOrganizationId'] as String,
      headName: data['headName'] as String,
      membersCount: data['membersCount'] as int,
      phoneNumber: data['phoneNumber'] as String,
      address: data['address'] as String,
      areaId: data['areaId'] as String,
      firstReferralId: data['firstReferralId'] as String,
      receivedAt: _requiredDate(data['receivedAt']),
      updatedAt: _requiredDate(data['updatedAt']),
    );
  }


  String _eventActor(String? type) {
    switch (type) {
      case 'created':
        return 'منشئ طلب الإحالة';

      case 'source_approved':
      case 'source_rejected':
        return 'مشرف المؤسسة المرسلة';

      case 'target_accepted':
      case 'target_rejected':
      case 'service_started':
      case 'service_completed':
        return 'مشرف المؤسسة المستقبلة';

      default:
        return '';
    }
  }


  DateTime _requiredDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    throw const FormatException('Missing required timestamp');
  }

  DateTime? _optionalDate(dynamic value) {
    if (value == null) return null;
    return _requiredDate(value);
  }
}
