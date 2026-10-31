
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/referral_service.dart';

class CreateReferralController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ReferralService _referralService =
  ReferralService();

  final reasonController = TextEditingController();

  // Selected IDs
  final selectedFamilyId = RxnString();
  final selectedOrganizationId = RxnString();
  final selectedServiceId = RxnString();

  // Firestore data
  final families = <Map<String, dynamic>>[].obs;
  final organizations = <Map<String, dynamic>>[].obs;
  final services = <Map<String, dynamic>>[].obs;

  // UI states
  final isLoading = false.obs;
  final isLoadingServices = false.obs;
  final isSaving = false.obs;
  final isConfirmed = false.obs;
  final loadError = RxnString();
  final servicesError = RxnString();

  // Current user
  String? organizationId;
  String? areaId;
  String? role;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  // ---------------- Initial Data ----------------

  Future<void> loadInitialData() async {
    if (isLoading.value) return;

    try {
      isLoading.value = true;
      loadError.value = null;

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('المستخدم غير مسجل الدخول');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final data = userDoc.data()!;

      if (data['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      role = data['role'] as String?;
      organizationId = data['organizationId'] as String?;
      areaId = data['areaId'] as String?;

      if (organizationId == null ||
          !['supervisor', 'field_worker'].contains(role)) {
        throw Exception('بيانات صلاحيات المستخدم غير مكتملة');
      }

      if (role == 'field_worker' && areaId == null) {
        throw Exception('منطقة عمل الموظف غير محددة');
      }

      await Future.wait([
        loadFamilies(),
        loadOrganizations(),
      ]);
    } catch (e) {
      loadError.value = _errorMessage(e);
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------- Families ----------------

  Future<void> loadFamilies() async {
    final orgId = organizationId;

    if (orgId == null) return;

    Query<Map<String, dynamic>> query = _firestore
        .collection('organizations')
        .doc(orgId)
        .collection('families');

    if (role == 'field_worker') {
      query = query.where(
        'areaId',
        isEqualTo: areaId,
      );
    }

    final snapshot = await query.get();

    families.assignAll(
      snapshot.docs.map((doc) {
        return <String, dynamic>{
          'id': doc.id,
          ...doc.data(),
        };
      }).toList(),
    );
  }

  // ---------------- Organizations ----------------


  Future<void> loadOrganizations() async {
    final currentOrgId = organizationId;

    if (currentOrgId == null || currentOrgId.isEmpty) {
      throw Exception('المؤسسة الحالية غير محددة');
    }

    final snapshot = await _firestore
        .collection('referralDirectory')
        .where('isActive', isEqualTo: true)
        .get();

    organizations.assignAll(
      snapshot.docs
          .where((doc) => doc.id != currentOrgId)
          .map((doc) {
        final data = doc.data();

        return <String, dynamic>{
          'id': doc.id,
          'name': data['name'] ?? '',
          'isActive': data['isActive'] ?? false,
        };
      })
          .where((org) =>
      (org['name'] as String).trim().isNotEmpty)
          .toList(),
    );

    if (organizations.isEmpty) {
      selectedOrganizationId.value = null;
      selectedServiceId.value = null;
      services.clear();
    }
  }


  // ---------------- Services ----------------


  int _servicesRequestVersion = 0;

  Future<void> loadServices(String targetOrgId) async {
    final int requestVersion = ++_servicesRequestVersion;

    try {
      isLoadingServices.value = true;
      servicesError.value = null;
      services.clear();
      selectedServiceId.value = null;

      final snapshot = await _firestore
          .collection('organizations')
          .doc(targetOrgId)
          .collection('services')
          .where('isActive', isEqualTo: true)
          .where('acceptsReferrals', isEqualTo: true)
          .get();

      if (requestVersion != _servicesRequestVersion ||
          selectedOrganizationId.value != targetOrgId) {
        return;
      }

      services.assignAll(
        snapshot.docs.map((doc) {
          return <String, dynamic>{
            'id': doc.id,
            ...doc.data(),
          };
        }).toList(),
      );
    } catch (e) {
      if (requestVersion == _servicesRequestVersion) {
        servicesError.value = _errorMessage(e);
      }
    } finally {
      if (requestVersion == _servicesRequestVersion) {
        isLoadingServices.value = false;
      }
    }
  }


  // ---------------- Selections ----------------

  void selectFamily(String? familyId) {
    selectedFamilyId.value = familyId;
  }

  void selectReceivingOrg(String? orgId) {
    ++_servicesRequestVersion;

    selectedOrganizationId.value = orgId;
    selectedServiceId.value = null;
    services.clear();
    servicesError.value = null;
    isLoadingServices.value = false;

    if (orgId != null) {
      loadServices(orgId);
    }
  }

  void selectServiceType(String? serviceId) {
    selectedServiceId.value = serviceId;
  }

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  // ---------------- Submit ----------------

  Future<void> submitReferral() async {
    if (isSaving.value || isLoading.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final familyId = selectedFamilyId.value;
    final targetOrgId = selectedOrganizationId.value;
    final serviceId = selectedServiceId.value;

    if (familyId == null ||
        targetOrgId == null ||
        serviceId == null) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار الأسرة والمؤسسة والخدمة',
      );
      return;
    }

    if (!isConfirmed.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى تأكيد توضيح غرض الإحالة ونطاق المشاركة للأسرة',
      );
      return;
    }

    // Prevent submitting a stale or invalid selection.
    if (!families.any((item) => item['id'] == familyId) ||
        !organizations.any(
              (item) => item['id'] == targetOrgId,
        ) ||
        !services.any(
              (item) => item['id'] == serviceId,
        )) {
      Get.snackbar(
        'تنبيه',
        'البيانات المختارة غير متاحة، يرجى إعادة الاختيار',
      );
      return;
    }

    if (targetOrgId == organizationId) {
      Get.snackbar(
        'تنبيه',
        'لا يمكن إحالة الأسرة إلى نفس المؤسسة',
      );
      return;
    }

    if (isLoadingServices.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى انتظار تحميل الخدمات المتاحة',
      );
      return;
    }

    try {
      isSaving.value = true;

      await _referralService.createReferral(
        familyId: familyId,
        targetOrganizationId: targetOrgId,
        targetServiceId: serviceId,
        reason: reasonController.text.trim(),
        sharingConfirmed: isConfirmed.value,
      );

      Get.back();

      Get.snackbar(
        'تم إنشاء الإحالة',
        role == 'supervisor'
            ? 'تم إرسال الإحالة للمؤسسة المستقبلة'
            : 'تم إرسال الطلب للمشرف للموافقة عليه',
      );
    } catch (e) {
      Get.snackbar(
        'تعذر إنشاء الإحالة',
        _errorMessage(e),
      );
    } finally {
      isSaving.value = false;
    }
  }

  String _errorMessage(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'ليس لديك صلاحية لإتمام العملية';
        case 'unavailable':
          return 'تعذر الاتصال بخدمة Firebase';
        case 'not-found':
          return 'البيانات المطلوبة غير موجودة';
        default:
          return error.message ?? 'حدث خطأ غير متوقع';
      }
    }

    return error.toString().replaceFirst(
      'Exception: ',
      '',
    );
  }

  @override
  void onClose() {
    reasonController.dispose();
    super.onClose();
  }
}
