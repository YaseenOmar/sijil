
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sijil/features/families/data/datasources/family_remote_datasource.dart';
import 'package:sijil/features/families/data/models/family_model.dart';

// Exception with a message safe to display to the user.
class FamilyCreationException implements Exception {
  final String message;

  const FamilyCreationException(this.message);

  @override
  String toString() => message;
}

class FamilyCreationService {
  final FamilyRemoteDataSource _remote =
  FamilyRemoteDataSource();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const Duration _timeout =
  Duration(seconds: 15);

  static const String _duplicateMessage =
      'هذه الأسرة مسجلة مسبقاً';

  // Get the authenticated user's account information.
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

    if (data['role'] != 'supervisor' &&
        data['role'] != 'field_worker') {
      throw const FamilyCreationException(
        'ليس لديك صلاحية لإدارة الأسر',
      );
    }

    if (data['organizationId'] is! String ||
        (data['organizationId'] as String).isEmpty) {
      throw const FamilyCreationException(
        'لم يتم تحديد المؤسسة',
      );
    }

    if (data['role'] == 'field_worker' &&
        (data['areaId'] is! String ||
            (data['areaId'] as String).isEmpty)) {
      throw const FamilyCreationException(
        'لم يتم تحديد منطقة الموظف',
      );
    }

    return data;
  }

  // Search for a reserved national ID in the entire organization.
  //
  // If the user can access the family, return its data.
  // If the family belongs to another area, report a duplicate
  // without revealing its details.
  //
  // null means the national ID is not registered.
  Future<FamilyModel?> findFamilyByNationalId(
      String nationalId,
      ) async {
    try {
      final normalizedId = nationalId.trim();

      if (!RegExp(r'^[0-9]{9}$').hasMatch(normalizedId)) {
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
          .get(const GetOptions(source: Source.server))
          .timeout(_timeout);

      // No reservation: national ID is available.
      if (!reservation.exists) {
        return null;
      }

      final familyId = reservation.data()?['familyId'];

      if (familyId is! String || familyId.isEmpty) {
        throw const FamilyCreationException(
          _duplicateMessage,
        );
      }

      // We already know the ID is registered.
      // Try to retrieve family details only if permitted.
      try {
        final familyDoc = await organizationRef
            .collection('families')
            .doc(familyId)
            .get(const GetOptions(source: Source.server))
            .timeout(_timeout);

        if (!familyDoc.exists) {
          throw const FamilyCreationException(
            _duplicateMessage,
          );
        }

        return FamilyModel.fromMap({
          ...familyDoc.data()!,
          'id': familyDoc.id,
        });
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied') {
          // Registered in another area:
          // do not expose private family information.
          throw const FamilyCreationException(
            _duplicateMessage,
          );
        }

        rethrow;
      }
    } on FamilyCreationException {
      rethrow;
    } on TimeoutException {
      throw const FamilyCreationException(
        'تعذر الاتصال بالإنترنت، تحقق من الاتصال وحاول مرة أخرى',
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

  // Local check while typing.
  //
  // This checks only family documents cached on this device,
  // inside the current user's authorized area.
  //
  // A missing cached result does NOT prove the ID is available.
  Future<FamilyModel?> findLocalFamilyByNationalId(
      String nationalId,
      ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return null;

      final userData = await _getUserData(
        source: Source.cache,
      );

      final organizationId =
      userData['organizationId'] as String;

      Query<Map<String, dynamic>> query = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('families')
          .where(
        'nationalId',
        isEqualTo: nationalId.trim(),
      );

      if (userData['role'] == 'field_worker') {
        query = query.where(
          'areaId',
          isEqualTo: userData['areaId'] as String,
        );
      }

      final snapshot = await query
          .limit(1)
          .get(const GetOptions(source: Source.cache));

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;

      return FamilyModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    } catch (_) {
      // Cache is unavailable or has no matching family.
      // Server validation still happens before proceeding.
      return null;
    }
  }

  // Save through the remote data source.
  //
  // The remote data source must use a transaction that
  // creates the family and national ID reservation together.
  Future<void> addFamily(FamilyModel family) async {
    try {
      await _remote
          .addFamily(family)
          .timeout(_timeout);
    } on FamilyCreationException {
      rethrow;
    } on TimeoutException {
      throw const FamilyCreationException(
        'انتهت مهلة الاتصال. تحقق من Firestore قبل إعادة المحاولة',
      );
    } on FirebaseException catch (e) {
      throw FamilyCreationException(
        _firebaseMessage(e.code),
      );
    } catch (e) {
      if (e.toString().contains(_duplicateMessage)) {
        throw const FamilyCreationException(
          _duplicateMessage,
        );
      }

      if (e.toString().contains('معرف الأسرة مستخدم')) {
        throw const FamilyCreationException(
          'تعذر الحفظ: معرف الأسرة مستخدم مسبقاً',
        );
      }

      throw const FamilyCreationException(
        'تعذر حفظ الأسرة، يرجى المحاولة مرة أخرى',
      );
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
