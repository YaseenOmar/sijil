
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_model.dart';

class ServiceRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ServiceRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // ------------------------------------------
  // Get current user's profile and validate it.
  // ------------------------------------------

  Future<Map<String, dynamic>> _getCurrentUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

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

    if (organizationId is! String || organizationId.isEmpty) {
      throw Exception('معرف المؤسسة غير صالح');
    }

    return userData;
  }

  // ------------------------------------------
  // Services collection.
  // organizations/{organizationId}/services
  // ------------------------------------------

  CollectionReference<Map<String, dynamic>> _services(
      String organizationId,
      ) {
    return _firestore
        .collection('organizations')
        .doc(organizationId)
        .collection('services');
  }

  // ------------------------------------------
  // Validate supervisor permissions.
  // ------------------------------------------

  Future<Map<String, dynamic>> _getSupervisorData() async {
    final userData = await _getCurrentUserData();

    if (userData['role'] != 'supervisor') {
      throw Exception(
        'ليس لديك صلاحية لإدارة خدمات المؤسسة',
      );
    }

    return userData;
  }

  // ------------------------------------------
  // Add a new service.
  // ------------------------------------------

  Future<void> addService(ServiceModel service) async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final userData = await _getSupervisorData();

    final organizationId =
    userData['organizationId'] as String;

    if (service.organizationId != organizationId) {
      throw Exception(
        'لا يمكن إضافة خدمة لمؤسسة أخرى',
      );
    }

    if (service.createdBy != currentUser.uid) {
      throw Exception('معرف منشئ الخدمة غير صحيح');
    }

    if (service.id.trim().isEmpty) {
      throw Exception('معرف الخدمة مطلوب');
    }

    if (service.name.trim().isEmpty) {
      throw Exception('اسم الخدمة مطلوب');
    }

    if (service.category.trim().isEmpty) {
      throw Exception('تصنيف الخدمة مطلوب');
    }

    if (service.hasCooldown &&
        (service.cooldownDays <= 0 ||
            (service.cooldownReason?.trim().isEmpty ?? true))) {
      throw Exception('بيانات منع التكرار غير مكتملة');
    }

    final serviceRef = _services(organizationId)
        .doc(service.id);

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(serviceRef);

      if (existing.exists) {
        throw Exception('معرف الخدمة مستخدم مسبقاً');
      }

      final data = service.toMap();

      // Use Firestore server timestamps.
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      transaction.set(serviceRef, data);
    });
  }

  // ------------------------------------------
  // Get services in the current organization.
  // ------------------------------------------

  Future<List<ServiceModel>> getServices({
    bool activeOnly = false,
  }) async {
    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    Query<Map<String, dynamic>> query =
    _services(organizationId);

    if (activeOnly) {
      query = query.where(
        'isActive',
        isEqualTo: true,
      );
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      return ServiceModel.fromMap(
        doc.data(),
        id: doc.id,
      );
    }).toList();
  }

  // ------------------------------------------
  // Get a specific service by ID.
  // ------------------------------------------

  Future<ServiceModel?> getServiceById(
      String serviceId,
      ) async {
    if (serviceId.trim().isEmpty) {
      throw Exception('معرف الخدمة مطلوب');
    }

    final userData = await _getCurrentUserData();

    final organizationId =
    userData['organizationId'] as String;

    final doc = await _services(organizationId)
        .doc(serviceId)
        .get();

    if (!doc.exists) {
      return null;
    }

    return ServiceModel.fromMap(
      doc.data()!,
      id: doc.id,
    );
  }

  // ------------------------------------------
  // Update an existing service.
  // ------------------------------------------

  Future<void> updateService(
      ServiceModel service,
      ) async {
    final userData = await _getSupervisorData();

    final organizationId =
    userData['organizationId'] as String;

    if (service.organizationId != organizationId) {
      throw Exception(
        'لا يمكن تعديل خدمة تابعة لمؤسسة أخرى',
      );
    }

    if (service.id.trim().isEmpty) {
      throw Exception('معرف الخدمة مطلوب');
    }

    if (service.name.trim().isEmpty ||
        service.category.trim().isEmpty) {
      throw Exception('بيانات الخدمة الأساسية مطلوبة');
    }

    if (service.hasCooldown &&
        (service.cooldownDays <= 0 ||
            (service.cooldownReason?.trim().isEmpty ?? true))) {
      throw Exception('بيانات منع التكرار غير مكتملة');
    }

    final serviceRef = _services(organizationId)
        .doc(service.id);

    final existing = await serviceRef.get();

    if (!existing.exists) {
      throw Exception('الخدمة غير موجودة');
    }

    final data = service.toMap();

    // Do not modify original creation information.
    data.remove('createdAt');
    data.remove('createdBy');
    data.remove('organizationId');

    // Update timestamp from server.
    data['updatedAt'] = FieldValue.serverTimestamp();

    await serviceRef.update(data);
  }

  // ------------------------------------------
  // Activate or deactivate a service.
  // ------------------------------------------

  Future<void> updateServiceStatus(
      String serviceId,
      bool isActive,
      ) async {
    final userData = await _getSupervisorData();

    final organizationId =
    userData['organizationId'] as String;

    if (serviceId.trim().isEmpty) {
      throw Exception('معرف الخدمة مطلوب');
    }

    final serviceRef = _services(organizationId)
        .doc(serviceId);

    final existing = await serviceRef.get();

    if (!existing.exists) {
      throw Exception('الخدمة غير موجودة');
    }

    await serviceRef.update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
