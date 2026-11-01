
import 'package:cloud_functions/cloud_functions.dart';
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
    if (isClosed || isSaving.value || isLoading.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    // 1. Validate form
    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    // 2. Get selected values
    final familyId = selectedFamilyId.value;
    final targetOrgId = selectedOrganizationId.value;
    final serviceId = selectedServiceId.value;
    final reason = reasonController.text.trim();

    // 3. Validate required selections
    if (familyId == null ||
        targetOrgId == null ||
        serviceId == null) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار الأسرة والمؤسسة والخدمة',
      );
      return;
    }

    // 4. Validate referral reason
    if (reason.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال سبب الإحالة',
      );
      return;
    }

    // 5. Confirm information sharing
    if (!isConfirmed.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى تأكيد توضيح غرض الإحالة ونطاق المشاركة للأسرة',
      );
      return;
    }

    // 6. Prevent referral to the same organization
    if (targetOrgId == organizationId) {
      Get.snackbar(
        'تنبيه',
        'لا يمكن إحالة الأسرة إلى نفس المؤسسة',
      );
      return;
    }

    // 7. Wait for available services to load
    if (isLoadingServices.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى انتظار تحميل الخدمات المتاحة',
      );
      return;
    }

    // 8. Validate that selected data is still available
    final familyExists = families.any(
          (item) => item['id'] == familyId,
    );

    final organizationExists = organizations.any(
          (item) => item['id'] == targetOrgId,
    );

    final serviceExists = services.any(
          (item) => item['id'] == serviceId,
    );

    if (!familyExists ||
        !organizationExists ||
        !serviceExists) {
      Get.snackbar(
        'تنبيه',
        'البيانات المختارة غير متاحة، يرجى إعادة الاختيار',
      );
      return;
    }

    try {
      isSaving.value = true;

      // 9. Debug information
      debugPrint('========== CREATE REFERRAL ==========');
      debugPrint('Source organization: $organizationId');
      debugPrint('Family ID: $familyId');
      debugPrint('Target organization: $targetOrgId');
      debugPrint('Target service: $serviceId');
      debugPrint('User role: $role');
      debugPrint('Sharing confirmed: ${isConfirmed.value}');

      // 10. Call Firebase Cloud Function
      await _referralService.createReferral(
        familyId: familyId,
        targetOrganizationId: targetOrgId,
        targetServiceId: serviceId,
        reason: reason,
        sharingConfirmed: isConfirmed.value,
      );

      debugPrint('CREATE REFERRAL: SUCCESS');

      if (isClosed) return;

      // 11. Return to referrals screen
      Get.back();

      Get.snackbar(
        'تم إنشاء الإحالة',
        role == 'supervisor'
            ? 'تم إرسال الإحالة للمؤسسة المستقبلة'
            : 'تم إرسال الطلب للمشرف للموافقة عليه',
      );

    } on FirebaseFunctionsException catch (e, stackTrace) {
      debugPrint('========== CLOUD FUNCTION ERROR ==========');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('DETAILS: ${e.details}');
      debugPrint('PLUGIN: ${e.plugin}');
      debugPrintStack(stackTrace: stackTrace);

      if (isClosed) return;

      String message;

      switch (e.code) {
        case 'permission-denied':
          message = e.message ??
              'ليس لديك صلاحية لإنشاء هذه الإحالة';
          break;

        case 'unauthenticated':
          message = 'انتهت جلسة تسجيل الدخول، يرجى الدخول مجددًا';
          break;

        case 'invalid-argument':
          message = e.message ??
              'بيانات الإحالة غير صحيحة';
          break;

        case 'failed-precondition':
          message = e.message ??
              'لا يمكن إنشاء الإحالة في الحالة الحالية';
          break;

        case 'not-found':
          message = e.message ??
              'الأسرة أو المؤسسة أو الخدمة غير موجودة';
          break;

        case 'unavailable':
          message = 'تعذر الاتصال بخدمة Firebase';
          break;

        case 'internal':
          message =
          'حدث خطأ داخل الخادم أثناء إنشاء الإحالة. '
              'يرجى مراجعة Cloud Functions Logs.';
          break;

        default:
          message = e.message ??
              'تعذر إنشاء الإحالة، يرجى المحاولة مجددًا';
      }

      Get.snackbar(
        'تعذر إنشاء الإحالة',
        message,
      );

    } catch (e, stackTrace) {
      debugPrint('========== CREATE REFERRAL ERROR ==========');
      debugPrint('ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (isClosed) return;

      Get.snackbar(
        'تعذر إنشاء الإحالة',
        _errorMessage(e),
      );

    } finally {
      if (!isClosed) {
        isSaving.value = false;
      }
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
