
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import 'package:sijil/features/family_creation/utils/text_utils.dart';

import '../../auth/controllers/user_session_controller.dart';
import '../data/models/service_model.dart';
import '../repositories/service_repository.dart';

class AddServiceController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final ServiceRepository _repository;

  AddServiceController({
    ServiceRepository? repository,
  }) : _repository = repository ?? ServiceRepository();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final UserSessionController _session;

  // ==========================================
  // Service categories
  // ==========================================

  static const Map<String, String> categories = {
    'food': 'مساعدات غذائية',
    'hygiene': 'مستلزمات نظافة',
    'education': 'دعم تعليمي',
    'medical': 'دعم طبي',
    'shelter': 'دعم إيواء',
    'cash': 'مساعدات نقدية',
    'other': 'أخرى',
  };

  // ==========================================
  // Text controllers
  // ==========================================

  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final unitController = TextEditingController();
  final cooldownDaysController = TextEditingController();
  final cooldownReasonController = TextEditingController();

  // ==========================================
  // Reactive values
  // ==========================================

  final name = ''.obs;

  final category = RxnString();

  final cooldownDays = ''.obs;

  final isActive = true.obs;

  final acceptsReferrals = true.obs;

  final hasCooldown = false.obs;

  // ==========================================
  // UI states
  // ==========================================

  final isLoading = false.obs;
  final isSaved = false.obs;

  // ==========================================
  // Lifecycle
  // ==========================================

  @override
  void onInit() {
    super.onInit();

    _session = Get.find<UserSessionController>();
  }

  // ==========================================
  // Clean values
  // ==========================================

  String get cleanName =>
      nameController.text.trim();

  String get cleanDescription =>
      descriptionController.text.trim();

  String get cleanUnit =>
      unitController.text.trim();

  String get cleanCooldownReason =>
      cooldownReasonController.text.trim();

  int get cooldownDaysValue {
    if (!hasCooldown.value) return 0;

    return int.tryParse(
      toLatinDigits(
        cooldownDaysController.text.trim(),
      ),
    ) ??
        0;
  }

  // ==========================================
  // Preview
  // ==========================================

  String get availabilityLine {
    final title = name.value.isEmpty
        ? 'الخدمة الجديدة'
        : name.value;

    final status = isActive.value
        ? 'متاحة'
        : 'غير متاحة';

    return '$title · $status';
  }

  String get rulesLine {
    final referrals = acceptsReferrals.value
        ? 'استقبال الإحالات مفعّل'
        : 'استقبال الإحالات غير مفعّل';

    if (!hasCooldown.value) {
      return '$referrals · بدون فترة منع تكرار';
    }

    return '$referrals · منع تكرار '
        '${toArabicDigits(cooldownDaysValue)} يومًا '
        'من التسليم الفعلي';
  }

  // ==========================================
  // Form actions
  // ==========================================

  void onNameChanged(String value) {
    name.value = value.trim();
  }

  void selectCategory(String? value) {
    if (value == null ||
        !categories.containsKey(value)) {
      category.value = null;
      return;
    }

    category.value = value;
  }

  void onCooldownDaysChanged(String value) {
    cooldownDays.value = value;
  }

  void setIsActive(bool value) {
    isActive.value = value;
  }

  void setAcceptsReferrals(bool value) {
    acceptsReferrals.value = value;
  }

  void setHasCooldown(bool value) {
    hasCooldown.value = value;

    if (!value) {
      cooldownDaysController.clear();
      cooldownReasonController.clear();
      cooldownDays.value = '';
    }
  }

  // ==========================================
  // Validation
  // ==========================================

  bool validateForReview() {
    FocusManager.instance.primaryFocus?.unfocus();

    if (isLoading.value || isSaved.value) {
      return false;
    }

    if (!(formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (cleanName.isEmpty || cleanName.length > 150) {
      _showError('اسم الخدمة غير صالح');
      return false;
    }

    if (cleanDescription.isEmpty ||
        cleanDescription.length > 1000) {
      _showError('وصف الخدمة غير صالح');
      return false;
    }

    if (category.value == null ||
        !categories.containsKey(category.value)) {
      _showError('يرجى اختيار تصنيف الخدمة');
      return false;
    }

    if (cleanUnit.length > 100) {
      _showError('وحدة الخدمة طويلة جدًا');
      return false;
    }

    if (hasCooldown.value) {
      final days = cooldownDaysValue;

      if (days < 1 || days > 36500) {
        _showError(
          'فترة منع التكرار يجب أن تكون بين 1 و36500 يوم',
        );
        return false;
      }

      if (cleanCooldownReason.isEmpty) {
        _showError('يرجى كتابة سبب فترة منع التكرار');
        return false;
      }

      if (cleanCooldownReason.length > 500) {
        _showError('سبب فترة منع التكرار طويل جدًا');
        return false;
      }
    }

    return true;
  }

  // ==========================================
  // Build ServiceModel
  // ==========================================

  ServiceModel _buildService() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('يجب تسجيل الدخول أولًا');
    }

    final organizationId =
        _session.organizationId.value;

    if (organizationId.isEmpty) {
      throw Exception('لم يتم تحديد المؤسسة');
    }

    if (_session.uid.value != currentUser.uid) {
      throw Exception(
        'بيانات الجلسة لا تطابق المستخدم الحالي',
      );
    }

    if (category.value == null) {
      throw Exception('تصنيف الخدمة مطلوب');
    }

    final now = DateTime.now();

    return ServiceModel(
      id: const Uuid().v4(),
      name: cleanName,
      description: cleanDescription,
      category: category.value!,
      unit: cleanUnit,
      isActive: isActive.value,
      acceptsReferrals: acceptsReferrals.value,
      hasCooldown: hasCooldown.value,
      cooldownDays: hasCooldown.value
          ? cooldownDaysValue
          : 0,
      cooldownReason: hasCooldown.value
          ? cleanCooldownReason
          : '',
      organizationId: organizationId,
      createdBy: currentUser.uid,
      createdAt: now,
      updatedAt: now,
    );
  }

  // ==========================================
  // Save Service
  // ==========================================

  Future<void> confirmSave() async {
    if (isLoading.value || isSaved.value) return;

    if (!validateForReview()) return;

    isLoading.value = true;

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولًا');
      }

      // Refresh and verify the current user's token.
      await currentUser.reload();
      await currentUser.getIdToken(true);

      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        throw Exception(
          'يجب التحقق من البريد الإلكتروني أولًا',
        );
      }

      if (!_session.isSupervisor) {
        throw Exception(
          'إضافة الخدمات متاحة للمشرف فقط',
        );
      }

      final service = _buildService();

      await _repository.addService(service);

      isSaved.value = true;

      // Close the review sheet first.
      if (Get.isBottomSheetOpen == true) {
        Get.back();
      }

      // Return to the previous screen.
      Get.back(result: true);

      Get.snackbar(
        'تم الحفظ بنجاح',
        'تمت إضافة الخدمة إلى خدمات المؤسسة',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseException catch (e) {
      _showError(_firebaseErrorMessage(e));
    } catch (e) {
      _showError(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // ==========================================
  // Error handling
  // ==========================================

  String _firebaseErrorMessage(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return 'رفض Firestore العملية. تحقق من صلاحيات '
            'المشرف ومسار services والحقول المسموحة '
            'في قواعد الأمان.';

      case 'unavailable':
        return 'تعذر الاتصال بالخادم. تحقق من الإنترنت.';

      case 'already-exists':
        return 'الخدمة موجودة مسبقًا.';

      default:
        return e.message ?? 'تعذر حفظ الخدمة.';
    }
  }

  void _showError(String message) {
    Get.snackbar(
      'تعذر حفظ الخدمة',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFFFEBEE),
      colorText: const Color(0xFFB71C1C),
    );
  }

  // ==========================================
  // Dispose
  // ==========================================

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    unitController.dispose();
    cooldownDaysController.dispose();
    cooldownReasonController.dispose();

    super.onClose();
  }
}
