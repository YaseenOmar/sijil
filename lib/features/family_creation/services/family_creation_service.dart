import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sijil/core/constants/demo_context.dart';
import 'package:sijil/features/families/data/datasources/family_remote_datasource.dart';
import 'package:sijil/features/families/data/models/family_model.dart';

// Exception with a message that is safe to show to the user
class FamilyCreationException implements Exception {
  final String message;

  const FamilyCreationException(this.message);

  @override
  String toString() => message;
}

// Wraps FamilyRemoteDataSource and converts raw errors to Arabic messages
class FamilyCreationService {
  final FamilyRemoteDataSource _remote = FamilyRemoteDataSource();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Firestore waits forever when offline, so we stop waiting after a while
  static const Duration _timeout = Duration(seconds: 15);

  static const String _duplicateMessage = 'هذه الأسرة مسجلة مسبقاً';

  // Find an existing family by national ID (null if not registered)
  Future<FamilyModel?> findFamilyByNationalId(String nationalId) async {
    try {
      final snapshot = await _firestore
          .collection('organizations')
          .doc(DemoContext.organizationId)
          .collection('families')
          .where('nationalId', isEqualTo: nationalId.trim())
          .limit(1)
          .get()
          .timeout(_timeout);

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      return FamilyModel.fromMap({...doc.data(), 'id': doc.id});
    } on TimeoutException {
      throw const FamilyCreationException(
        'تعذر الاتصال بالإنترنت، تحقق من الاتصال وحاول مرة أخرى',
      );
    } on FirebaseException catch (e) {
      throw FamilyCreationException(_firebaseMessage(e.code));
    } catch (_) {
      throw const FamilyCreationException('تعذر التحقق من رقم الهوية');
    }
  }

  // Save the family in Firestore
  Future<void> addFamily(FamilyModel family) async {
    try {
      await _remote.addFamily(family).timeout(_timeout);
    } on TimeoutException {
      throw const FamilyCreationException(
        'تعذر الاتصال بالإنترنت، تحقق من الاتصال وأعد المحاولة',
      );
    } on FirebaseException catch (e) {
      throw FamilyCreationException(_firebaseMessage(e.code));
    } catch (e) {
      if (e.toString().contains(_duplicateMessage)) {
        throw const FamilyCreationException(_duplicateMessage);
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
      default:
        return 'حدث خطأ أثناء الاتصال بالخادم';
    }
  }
}
