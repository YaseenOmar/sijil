
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/family_model.dart';

class FamilyRemoteDataSource {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==========================================
  // 1. Get Current User Data
  // ==========================================

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get(const GetOptions(source: Source.server));

    if (!userDoc.exists) {
      throw Exception('لم يتم العثور على بيانات المستخدم');
    }

    final userData = userDoc.data()!;

    if (userData['status'] != 'active') {
      throw Exception('الحساب غير نشط');
    }

    final role = userData['role'];

    if (role != 'supervisor' && role != 'field_worker') {
      throw Exception('الدور الوظيفي غير معتمد');
    }

    final organizationId = userData['organizationId'];

    if (organizationId is! String ||
        organizationId.isEmpty) {
      throw Exception('معرف المؤسسة غير صالح');
    }

    if (role == 'field_worker') {
      final areaId = userData['areaId'];

      if (areaId is! String || areaId.isEmpty) {
        throw Exception('لم يتم تحديد منطقة الموظف');
      }
    }

    return userData;
  }

  // ==========================================
  // 2. Firestore Collections
  // ==========================================

  CollectionReference<Map<String, dynamic>> _families(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('families');
  }

  CollectionReference<Map<String, dynamic>> _familyNationalIds(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('familyNationalIds');
  }

  // ==========================================
  // 3. Get Families
  // ==========================================

  Future<List<FamilyModel>> getFamilies() async {
    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    final role = userData['role'] as String;

    Query<Map<String, dynamic>> query =
    _families(organizationId);

    // Field worker: assigned area only
    if (role == 'field_worker') {
      final areaId = userData['areaId'] as String;

      query = query.where(
        'areaId',
        isEqualTo: areaId,
      );
    }

    // Supervisor: all organization families
    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return FamilyModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  // ==========================================
  // 4. Get Families By Area
  // ==========================================

  Future<List<FamilyModel>> getFamiliesByArea(
      String areaId,
      ) async {
    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    final role = userData['role'] as String;

    final selectedAreaId = areaId.trim();

    if (selectedAreaId.isEmpty) {
      throw Exception('يرجى تحديد المنطقة');
    }

    if (role == 'field_worker' &&
        userData['areaId'] != selectedAreaId) {
      throw Exception(
        'ليس لديك صلاحية الوصول إلى هذه المنطقة',
      );
    }

    final snapshot = await _families(organizationId)
        .where(
      'areaId',
      isEqualTo: selectedAreaId,
    )
        .get();

    return snapshot.docs.map((doc) {
      return FamilyModel.fromMap({
        ...doc.data(),
        'id': doc.id,
      });
    }).toList();
  }

  // ==========================================
  // 5. Check Duplicate National ID
  // ==========================================

  Future<bool> familyExists(String nationalId) async {
    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    final normalizedId = nationalId.trim();

    if (!RegExp(r'^\d{9}$').hasMatch(normalizedId)) {
      throw Exception(
        'رقم الهوية يجب أن يتكون من 9 أرقام',
      );
    }

    // Check the unique national ID reservation
    // across the entire organization.
    final document = await _familyNationalIds(
      organizationId,
    ).doc(normalizedId).get(
      const GetOptions(source: Source.server),
    );

    return document.exists;
  }

  // ==========================================
  // 6. Add Family
  // ==========================================

  Future<void> addFamily(FamilyModel family) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    final role = userData['role'] as String;

    // Verify organization
    if (family.organizationId != organizationId) {
      throw Exception(
        'لا يمكن إضافة أسرة لمؤسسة أخرى',
      );
    }

    // Verify creator
    if (family.createdBy != currentUser.uid) {
      throw Exception(
        'معرف منشئ الأسرة غير صحيح',
      );
    }

    // Field worker can add families
    // only in their assigned area.
    if (role == 'field_worker' &&
        family.areaId != userData['areaId']) {
      throw Exception(
        'لا يمكن إضافة أسرة خارج منطقتك',
      );
    }

    if (family.areaId.trim().isEmpty) {
      throw Exception('يجب تحديد منطقة الأسرة');
    }

    if (family.id.trim().isEmpty ||
        family.id.contains('/')) {
      throw Exception('معرف الأسرة غير صالح');
    }

    // Normalize and validate national ID
    final nationalId = family.nationalId.trim();

    if (!RegExp(r'^\d{9}$').hasMatch(nationalId)) {
      throw Exception(
        'رقم الهوية يجب أن يتكون من 9 أرقام',
      );
    }

    // Family document
    final familyRef = _families(
      organizationId,
    ).doc(family.id);

    // Unique national ID reservation
    final nationalIdRef = _familyNationalIds(
      organizationId,
    ).doc(nationalId);

    // ========================================
    // Atomic Transaction
    // ========================================

    await _firestore.runTransaction((transaction) async {
      // Read before writing
      final nationalIdSnapshot =
      await transaction.get(nationalIdRef);

      final familySnapshot =
      await transaction.get(familyRef);

      // Prevent duplicates in any area
      if (nationalIdSnapshot.exists) {
        throw Exception('هذه الأسرة مسجلة مسبقاً');
      }

      // Prevent overwriting an existing family
      if (familySnapshot.exists) {
        throw Exception(
          'معرف الأسرة مستخدم مسبقاً',
        );
      }

      // Create family
      transaction.set(familyRef, {
        ...family.toMap(),
        'nationalId': nationalId,
      });

      // Reserve national ID
      transaction.set(nationalIdRef, {
        'familyId': family.id,
        'createdBy': currentUser.uid,
      });
    });
  }
}
