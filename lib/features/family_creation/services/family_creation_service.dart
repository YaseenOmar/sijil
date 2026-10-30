
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sijil/features/families/data/models/family_model.dart';

// Exception with a safe message for the user.
class FamilyCreationException implements Exception {
  final String message;

  const FamilyCreationException(this.message);

  @override
  String toString() => message;
}

class FamilyCreationService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFunctions _functions =
  FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  static const Duration _readTimeout =
  Duration(seconds: 15);

  static const Duration _writeTimeout =
  Duration(seconds: 65);

  static const String _duplicateMessage =
      'هذه الأسرة مسجلة مسبقاً';

  // ----------------------------------------
  // Get authenticated user's profile
  // ----------------------------------------

  Future<Map<String, dynamic>> _getUserData({
    Source source = Source.server,
  }) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw const FamilyCreationException(
        'يجب تسجيل الدخول أولاً',
      );
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get(GetOptions(source: source));

    if (!snapshot.exists) {
      throw const FamilyCreationException(
        'لم يتم العثور على بيانات الحساب',
      );
    }

    final data = snapshot.data()!;

    if (data['status'] != 'active') {
      throw const FamilyCreationException(
        'الحساب غير نشط',
      );
    }

    final role = data['role'];

    if (role != 'supervisor' &&
        role != 'field_worker') {
      throw const FamilyCreationException(
        'ليس لديك صلاحية لإدارة الأسر',
      );
    }

    final orgId = data['organizationId'];

    if (orgId is! String || orgId.isEmpty) {
      throw const FamilyCreationException(
        'لم يتم تحديد المؤسسة',
      );
    }

    return data;
  }

  // ----------------------------------------
  // Get current field worker area
  // ----------------------------------------

  Future<String?> _getCurrentAreaId({
    required Map<String, dynamic> userData,
    Source source = Source.server,
  }) async {
    if (userData['role'] == 'supervisor') {
      return null;
    }

    final orgId = userData['organizationId'];
    final invitationId = userData['invitationId'];

    if (orgId is! String ||
        invitationId is! String ||
        invitationId.isEmpty) {
      throw const FamilyCreationException(
        'بيانات ارتباط الموظف غير مكتملة',
      );
    }

    final employeeDoc = await _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('employees')
        .doc(invitationId)
        .get(GetOptions(source: source));

    final employee = employeeDoc.data();

    if (!employeeDoc.exists ||
        employee == null ||
        employee['status'] != 'active' ||
        employee['role'] != 'field_worker' ||
        employee['organizationId'] != orgId ||
        employee['uid'] != _auth.currentUser?.uid) {
      throw const FamilyCreationException(
        'سجل الموظف غير فعال أو غير صالح',
      );
    }

    final areaId = employee['areaId'];

    if (areaId is! String || areaId.isEmpty) {
      throw const FamilyCreationException(
        'لم يتم تحديد منطقة الموظف',
      );
    }

    return areaId;
  }

  // ----------------------------------------
  // Check national ID on server
  // ----------------------------------------

  Future<FamilyModel?> findFamilyByNationalId(
      String nationalId,
      ) async {
    try {
      final normalizedId = nationalId.trim();

      if (!RegExp(r'^[0-9]{9}$')
          .hasMatch(normalizedId)) {
        throw const FamilyCreationException(
          'رقم الهوية يجب أن يتكون من 9 أرقام',
        );
      }

      final userData = await _getUserData();

      final organizationId =
      userData['organizationId'] as String;

      final organizationRef = _firestore
          .collection('organizations')
          .doc(organizationId);

      final reservation = await organizationRef
          .collection('familyNationalIds')
          .doc(normalizedId)
          .get(
        const GetOptions(source: Source.server),
      )
          .timeout(_readTimeout);

      if (!reservation.exists) {
        return null;
      }

      final reservationData = reservation.data()!;
      final familyId = reservationData['familyId'];

      final registeredBy =
      reservationData['createdByName'] as String?;

      final duplicateMessage =
      _buildDuplicateMessage(registeredBy);

      if (familyId is! String || familyId.isEmpty) {
        throw FamilyCreationException(
          duplicateMessage,
        );
      }

      // The worker may not read family details
      // from another area.
      try {
        final familyDoc = await organizationRef
            .collection('families')
            .doc(familyId)
            .get(
          const GetOptions(source: Source.server),
        )
            .timeout(_readTimeout);

        if (!familyDoc.exists) {
          throw FamilyCreationException(
            duplicateMessage,
          );
        }

        return FamilyModel.fromMap({
          ...familyDoc.data()!,
          'id': familyDoc.id,
        });
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          throw FamilyCreationException(
            duplicateMessage,
          );
        }

        rethrow;
      }
    } on FamilyCreationException {
      rethrow;
    } on TimeoutException {
      throw const FamilyCreationException(
        'تعذر الاتصال بالخادم للتحقق من رقم الهوية',
      );
    } on FirebaseException catch (e) {
      throw FamilyCreationException(
        _firebaseMessage(e.code),
      );
    } catch (_) {
      throw const FamilyCreationException(
        'تعذر التحقق من رقم الهوية',
      );
    }
  }

  // ----------------------------------------
  // Check local cached families
  // ----------------------------------------

  Future<FamilyModel?> findLocalFamilyByNationalId(
      String nationalId,
      ) async {
    try {
      final normalizedId = nationalId.trim();

      if (!RegExp(r'^[0-9]{9}$')
          .hasMatch(normalizedId)) {
        return null;
      }

      if (_auth.currentUser == null) {
        return null;
      }

      final userData = await _getUserData(
        source: Source.cache,
      );

      final organizationId =
      userData['organizationId'] as String;

      Query<Map<String, dynamic>> query =
      _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('families')
          .where(
        'nationalId',
        isEqualTo: normalizedId,
      );

      if (userData['role'] == 'field_worker') {
        final currentArea = await _getCurrentAreaId(
          userData: userData,
          source: Source.cache,
        );

        if (currentArea == null) {
          return null;
        }

        query = query.where(
          'areaId',
          isEqualTo: currentArea,
        );
      }

      final snapshot = await query
          .limit(1)
          .get(
        const GetOptions(source: Source.cache),
      );

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;

      return FamilyModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    } catch (_) {
      // Missing cached data never proves that
      // the national ID is available.
      return null;
    }
  }

  // ----------------------------------------
  // Create family using Cloud Function
  // ----------------------------------------

  Future<String> addFamily(FamilyModel family) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw const FamilyCreationException(
          'يجب تسجيل الدخول أولاً',
        );
      }

      final userData = await _getUserData();

      final organizationId =
      userData['organizationId'] as String;

      final normalizedNationalId =
      family.nationalId.trim();

      if (!RegExp(r'^[0-9]{9}$')
          .hasMatch(normalizedNationalId)) {
        throw const FamilyCreationException(
          'رقم الهوية يجب أن يتكون من 9 أرقام',
        );
      }

      if (family.organizationId != organizationId) {
        throw const FamilyCreationException(
          'الأسرة لا تتبع المؤسسة الحالية',
        );
      }

      // Client-side permission check.
      // The Cloud Function independently verifies it.
      final currentArea = await _getCurrentAreaId(
        userData: userData,
      );

      if (currentArea != null &&
          family.areaId != currentArea) {
        throw const FamilyCreationException(
          'لا يمكنك إضافة أسرة خارج منطقتك',
        );
      }

      final callable = _functions.httpsCallable(
        'createFamily',
        options: HttpsCallableOptions(
          timeout: _writeTimeout,
        ),
      );


      final result = await callable.call<Map<String, dynamic>>({
        'organizationId': organizationId,
        'family': {
          'headName': family.headName.trim(),
          'nationalId': normalizedNationalId,
          'phoneNumber': family.phoneNumber,
          'membersCount': family.membersCount,
          'address': family.address,
          'housingStatus': family.housingStatus,
          'needs': family.needs,
          'areaId': family.areaId,
          'idCardImagePath': family.idCardImagePath,
        },
      });

      final data = result.data;

      if (data['success'] != true ||
          data['familyId'] is! String ||
          (data['familyId'] as String).isEmpty) {
        throw const FamilyCreationException(
          'لم يتم استلام معرف الأسرة من الخادم',
        );
      }

      return data['familyId'] as String;


    } on FamilyCreationException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'already-exists') {
        final details = e.details;

        String? createdByName;

        if (details is Map) {
          final value = details['createdByName'];

          if (value is String && value.isNotEmpty) {
            createdByName = value;
          }
        }

        throw FamilyCreationException(
          _buildDuplicateMessage(createdByName),
        );
      }

      throw FamilyCreationException(
        _functionsMessage(e),
      );
    } on TimeoutException {
      throw const FamilyCreationException(
        'انتهت مهلة الاتصال. قد تكون الأسرة حُفظت؛ '
            'تحقق من رقم الهوية قبل إعادة المحاولة',
      );
    } on FirebaseException catch (e) {
      throw FamilyCreationException(
        _firebaseMessage(e.code),
      );
    } catch (_) {
      throw const FamilyCreationException(
        'تعذر تأكيد نتيجة الحفظ، تحقق من رقم الهوية '
            'قبل إعادة المحاولة',
      );
    }
  }

  // ----------------------------------------
  // User-friendly error messages
  // ----------------------------------------

  String _buildDuplicateMessage(String? employeeName) {
    if (employeeName != null &&
        employeeName.trim().isNotEmpty) {
      return 'هذه الأسرة مسجلة مسبقاً من قِبل '
          '$employeeName';
    }

    return _duplicateMessage;
  }

  String _functionsMessage(
      FirebaseFunctionsException error,
      ) {
    switch (error.code) {
      case 'unauthenticated':
        return 'يجب تسجيل الدخول أولاً';

      case 'permission-denied':
        return error.message ??
            'ليس لديك صلاحية لتنفيذ هذه العملية';

      case 'invalid-argument':
        return error.message ??
            'بيانات الأسرة غير صحيحة';

      case 'failed-precondition':
        return error.message ??
            'تعذر تنفيذ العملية';

      case 'unavailable':
      case 'deadline-exceeded':
        return 'تعذر تأكيد نتيجة الحفظ بسبب الاتصال. '
            'تحقق من رقم الهوية قبل إعادة المحاولة';

      case 'already-exists':
        return _duplicateMessage;

      default:
        return 'تعذر حفظ الأسرة: '
            '${error.message ?? 'خطأ غير معروف'}';
    }
  }

  String _firebaseMessage(String code) {
    switch (code) {
      case 'permission-denied':
        return 'ليس لديك صلاحية لتنفيذ هذه العملية';

      case 'unavailable':
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت';

      case 'deadline-exceeded':
        return 'انتهت مهلة الاتصال بالخادم';

      case 'failed-precondition':
        return 'تعذر تنفيذ العملية، تحقق من إعدادات قاعدة البيانات';

      case 'aborted':
        return 'حدث تعارض أثناء الحفظ، يرجى المحاولة مرة أخرى';

      default:
        return 'حدث خطأ أثناء الاتصال بالخادم';
    }
  }
}
