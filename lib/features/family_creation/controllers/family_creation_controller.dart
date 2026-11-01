
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'package:sijil/features/families/data/models/family_model.dart';
import 'package:sijil/features/family_creation/constants/family_options.dart';
import 'package:sijil/features/family_creation/services/family_creation_service.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/views/duplicate_family_screen.dart';
import 'package:sijil/features/family_creation/views/family_housing_needs_screen.dart';
import 'package:sijil/features/family_creation/views/family_review_screen.dart';

import '../../families/views/widgets/family_details_screen.dart';

enum LocalIdStatus {
  idle,
  noMatch,
  match,
}

class FamilyCreationController extends GetxController {
  final FamilyCreationService _service =
  FamilyCreationService();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final ImagePicker _picker =
  ImagePicker();

  // ==========================================
  // Form Keys
  // ==========================================

  final basicFormKey = GlobalKey<FormState>();
  final housingFormKey = GlobalKey<FormState>();

  // ==========================================
  // Step 1: Basic Information
  // ==========================================

  final headNameController = TextEditingController();

  final nationalIdController = TextEditingController();

  final phoneController = TextEditingController();

  final membersCountController = TextEditingController();

  // ==========================================
  // Step 2: Housing and Needs
  // ==========================================

  String areaId = FamilyOptions.defaultAreaId;

  // The displayed name is loaded from Firestore.
  final areaNameController = TextEditingController();

  final userRole = ''.obs;

  final availableAreas = <Map<String, String>>[].obs;

  final selectedAreaId = RxnString();

  final isLoadingAreas = false.obs;

  final areaError = RxnString();

  final addressController = TextEditingController();

  final housingStatus = RxnString();

  final selectedNeeds = <String>[].obs;

  final housingError = RxnString();

  final needsError = RxnString();

  // ==========================================
  // Optional ID Image
  // ==========================================

  final idCardImagePath = RxnString();

  final idCardImageSizeKb = 0.obs;

  // ==========================================
  // UI States
  // ==========================================

  final isCheckingId = false.obs;

  final isSaving = false.obs;

  final isSaved = false.obs;

  final savedFamilyId = RxnString();

  final isConfirmed = false.obs;

  final saveError = RxnString();

  final existingFamily = Rxn<FamilyModel>();

  final localIdStatus = LocalIdStatus.idle.obs;

  // Reuse the same document ID when retrying.
  String? _draftId;

  // ==========================================
  // Initialization
  // ==========================================

  @override
  void onInit() {
    super.onInit();
    _loadAssignedArea();
  }

  // ==========================================
  // Load Assigned Area
  // ==========================================

  Future<void> _loadAssignedArea() async {
    try {
      isLoadingAreas.value = true;
      areaError.value = null;

      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw const FamilyCreationException(
          'يجب تسجيل الدخول أولاً',
        );
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) {
        throw const FamilyCreationException(
          'ملف المستخدم غير موجود',
        );
      }

      final userData = userDoc.data()!;

      if (userData['status'] != 'active') {
        throw const FamilyCreationException(
          'حساب المستخدم غير فعال',
        );
      }

      final role = userData['role'] as String?;
      final orgId = userData['organizationId'] as String?;

      if (!['supervisor', 'field_worker'].contains(role) ||
          orgId == null ||
          orgId.isEmpty) {
        throw const FamilyCreationException(
          'بيانات صلاحيات المستخدم غير مكتملة',
        );
      }

      userRole.value = role!;

      if (role == 'supervisor') {
        areaId = '';
        selectedAreaId.value = null;
        areaNameController.clear();
        availableAreas.clear();

        final snapshot = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('areas')
            .get(const GetOptions(source: Source.server));

        if (isClosed ||
            _auth.currentUser?.uid != currentUser.uid) {
          return;
        }

        final areas = snapshot.docs
            .where((doc) =>
        doc.data()['name'] is String &&
            (doc.data()['name'] as String).trim().isNotEmpty)
            .map((doc) => <String, String>{
          'id': doc.id,
          'name': (doc.data()['name'] as String).trim(),
        })
            .toList();

        areas.sort(
              (a, b) => a['name']!.compareTo(b['name']!),
        );

        availableAreas.assignAll(areas);

        if (areas.isEmpty) {
          areaError.value = 'لا توجد مناطق مسجلة في المؤسسة';
        }
      } else {
        final assignedArea = userData['areaId'] as String?;

        if (assignedArea == null || assignedArea.isEmpty) {
          throw const FamilyCreationException(
            'منطقة الموظف غير محددة',
          );
        }

        final areaDoc = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('areas')
            .doc(assignedArea)
            .get(const GetOptions(source: Source.server));

        if (!areaDoc.exists) {
          throw const FamilyCreationException(
            'منطقة الموظف غير موجودة',
          );
        }

        if (isClosed ||
            _auth.currentUser?.uid != currentUser.uid) {
          return;
        }

        areaId = assignedArea;
        selectedAreaId.value = assignedArea;
        areaNameController.text =
            areaDoc.data()?['name'] as String? ?? '';
      }
    } catch (e) {
      if (isClosed) return;

      areaError.value = e is FamilyCreationException
          ? e.message
          : 'تعذر تحميل المناطق: $e';
    } finally {
      if (!isClosed) {
        isLoadingAreas.value = false;
      }
    }
  }

  // ==========================================
  // Clean Values
  // ==========================================

  String get headName =>
      headNameController.text.trim();

  String get nationalId =>
      toLatinDigits(
        nationalIdController.text.trim(),
      );

  String get phone =>
      toLatinDigits(
        phoneController.text,
      ).replaceAll(
        RegExp(r'[\s-]'),
        '',
      );

  int get membersCount =>
      int.tryParse(
        toLatinDigits(
          membersCountController.text.trim(),
        ),
      ) ??
          0;

  String get address =>
      addressController.text.trim();

  List<String> get orderedNeeds =>
      FamilyOptions.needs
          .where(
            (need) => selectedNeeds.contains(need),
      )
          .toList();

  // ==========================================
  // Step 1: Check National ID Locally
  // ==========================================

  Future<void> onNationalIdChanged(
      String _,
      ) async {
    final id = nationalId;

    if (!RegExp(r'^\d{9}$').hasMatch(id)) {
      localIdStatus.value =
          LocalIdStatus.idle;
      return;
    }

    final found =
    await _service.findLocalFamilyByNationalId(
      id,
    );

    if (id != nationalId) return;

    localIdStatus.value = found == null
        ? LocalIdStatus.idle
        : LocalIdStatus.match;
  }

  // ==========================================
  // Step 1: Submit Basic Information
  // ==========================================

  Future<void> submitBasicInfo() async {
    if (isCheckingId.value) return;

    FocusManager.instance.primaryFocus
        ?.unfocus();

    if (!(basicFormKey.currentState
        ?.validate() ??
        false)) {
      return;
    }

    try {
      isCheckingId.value = true;

      final existing =
      await _service.findFamilyByNationalId(
        nationalId,
      );

      if (existing != null) {
        existingFamily.value = existing;

        localIdStatus.value =
            LocalIdStatus.match;

        Get.to(
              () => const DuplicateFamilyScreen(),
        );

        return;
      }

      existingFamily.value = null;

      localIdStatus.value =
          LocalIdStatus.noMatch;

      Get.to(
            () => FamilyHousingNeedsScreen(),
      );
    } on FamilyCreationException catch (e) {
      if (e.message.startsWith(
        'هذه الأسرة مسجلة مسبقاً',
      )) {
        localIdStatus.value =
            LocalIdStatus.match;
      }

      Get.snackbar(
        'تنبيه',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(
          seconds: 5,
        ),
      );
    } catch (e) {
      debugPrint(
        'FAMILY ID CHECK ERROR: $e',
      );

      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء التحقق من رقم الهوية',
      );
    } finally {
      isCheckingId.value = false;
    }
  }

  // ==========================================
  // Step 2: Housing
  // ==========================================

  void selectHousingStatus(String status) {
    housingStatus.value = status;

    housingError.value = null;
  }

  void toggleNeed(String need) {
    if (selectedNeeds.contains(need)) {
      selectedNeeds.remove(need);
    } else {
      selectedNeeds.add(need);
    }

    needsError.value = null;
  }

  // ==========================================
  // Image Picker
  // ==========================================

  Future<void> pickIdCardImage(
      ImageSource source,
      ) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );

      if (picked == null) return;

      final bytes =
      await File(picked.path).length();

      idCardImagePath.value = picked.path;

      idCardImageSizeKb.value =
          (bytes / 1024).ceil();
    } catch (e) {
      debugPrint(
        'FAMILY IMAGE ERROR: $e',
      );

      Get.snackbar(
        'خطأ',
        'تعذر إرفاق الصورة، تحقق من صلاحيات الكاميرا والمعرض',
      );
    }
  }

  void removeIdCardImage() {
    idCardImagePath.value = null;

    idCardImageSizeKb.value = 0;
  }

  // ==========================================
  // Step 2: Submit Housing
  // ==========================================

  void submitHousingInfo() {
    FocusManager.instance.primaryFocus
        ?.unfocus();

    final isFormValid =
        housingFormKey.currentState
            ?.validate() ??
            false;

    if (isLoadingAreas.value) {
      Get.snackbar('تنبيه', 'يرجى انتظار تحميل المناطق');
      return;
    }

    if (areaId.trim().isEmpty ||
        selectedAreaId.value == null) {
      areaError.value = 'يرجى تحديد منطقة الأسرة';
      return;
    }

    housingError.value =
    housingStatus.value == null
        ? 'يرجى اختيار حالة السكن'
        : null;

    needsError.value =
    selectedNeeds.isEmpty
        ? 'يرجى اختيار احتياج واحد على الأقل'
        : null;

    if (!isFormValid ||
        housingError.value != null ||
        needsError.value != null) {
      return;
    }

    if (isLoadingAreas.value) {
      Get.snackbar('تنبيه', 'يرجى انتظار تحميل المنطقة');
      return;
    }

    if (areaId.trim().isEmpty) {
      Get.snackbar(
        'تنبيه',
        userRole.value == 'supervisor'
            ? 'يرجى اختيار منطقة الأسرة'
            : 'لم يتم تحديد منطقة الموظف',
      );
      return;
    }

    Get.to(
          () => FamilyReviewScreen(),
    );
  }

  // ==========================================
  // Step 3: Confirmation
  // ==========================================

  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  void editBasicInfo() {
    Get.close(2);
  }

  void editHousingInfo() {
    Get.back();
  }

  // ==========================================
  // Step 3: Save Family
  // ==========================================

  Future<void> saveFamily() async {
    if (isSaving.value ||
        isSaved.value) {
      return;
    }

    if (!isConfirmed.value) {
      Get.snackbar(
        'تنبيه',
        'يرجى تأكيد التحقق من البيانات مع الأسرة',
      );

      return;
    }

    try {
      isSaving.value = true;

      saveError.value = null;

      final family = await _buildFamily();

      final familyId =
      await _service.addFamily(family);

      savedFamilyId.value = familyId;

      isSaved.value = true;

      Get.snackbar(
        'نجاح',
        'تم حفظ الأسرة بنجاح',
      );
    } on FamilyCreationException catch (e) {
      saveError.value = e.message;

      Get.snackbar(
        'خطأ',
        e.message,
      );
    } catch (e) {
      debugPrint(
        'FAMILY SAVE ERROR: $e',
      );

      saveError.value =
      'حدث خطأ غير متوقع أثناء حفظ الأسرة';

      Get.snackbar(
        'خطأ',
        saveError.value!,
      );
    } finally {
      isSaving.value = false;
    }
  }

  // ==========================================
  // Build Family Model
  // ==========================================

  Future<FamilyModel> _buildFamily() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw const FamilyCreationException(
        'يجب تسجيل الدخول أولاً',
      );
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get(
      const GetOptions(source: Source.server),
    );

    if (!userDoc.exists) {
      throw const FamilyCreationException(
        'لم يتم العثور على بيانات المستخدم',
      );
    }

    final userData = userDoc.data()!;

    if (userData['status'] != 'active') {
      throw const FamilyCreationException(
        'الحساب غير نشط',
      );
    }

    final role = userData['role'];

    if (role != 'supervisor' &&
        role != 'field_worker') {
      throw const FamilyCreationException(
        'ليس لديك صلاحية لإضافة الأسر',
      );
    }

    final organizationId =
    userData['organizationId'];

    if (organizationId is! String ||
        organizationId.isEmpty) {
      throw const FamilyCreationException(
        'لم يتم تحديد المؤسسة',
      );
    }

    if (role == 'supervisor') {
      if (areaId.isEmpty ||
          !availableAreas.any((area) => area['id'] == areaId)) {
        throw const FamilyCreationException(
          'يرجى اختيار منطقة صحيحة من مناطق المؤسسة',
        );
      }
    }

    String selectedAreaId = areaId;

    if (role == 'field_worker') {
      final assignedArea =
      userData['areaId'];

      if (assignedArea is! String ||
          assignedArea.trim().isEmpty) {
        throw const FamilyCreationException(
          'لم يتم تحديد منطقة الموظف',
        );
      }

      selectedAreaId =
          assignedArea.trim();
    }

    if (!RegExp(r'^\d{9}$').hasMatch(
      nationalId,
    )) {
      throw const FamilyCreationException(
        'رقم الهوية يجب أن يتكون من 9 أرقام',
      );
    }

    _draftId ??= const Uuid().v4();

    return FamilyModel(
      id: _draftId!,
      headName: headName,
      nationalId: nationalId,
      phoneNumber: phone,
      membersCount: membersCount,
      address: address,
      housingStatus: housingStatus.value!,
      idCardImagePath: idCardImagePath.value,
      needs: orderedNeeds,
      areaId: selectedAreaId,
      createdBy: currentUser.uid,
      organizationId: organizationId,
    );
  }

  // ==========================================
  // Open Saved Family
  // ==========================================

  Future<void> openSavedFamily() async {
    final familyId = savedFamilyId.value;

    if (familyId == null ||
        familyId.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لم يتم العثور على معرف الأسرة المحفوظة',
      );

      return;
    }

    try {
      final currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        throw const FamilyCreationException(
          'يجب تسجيل الدخول أولاً',
        );
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!userDoc.exists) {
        throw const FamilyCreationException(
          'لم يتم العثور على بيانات الحساب',
        );
      }

      final organizationId =
      userDoc.data()?['organizationId'];

      if (organizationId is! String ||
          organizationId.isEmpty) {
        throw const FamilyCreationException(
          'لم يتم تحديد المؤسسة',
        );
      }

      final familyDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('families')
          .doc(familyId)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!familyDoc.exists) {
        throw const FamilyCreationException(
          'تعذر العثور على الأسرة المحفوظة',
        );
      }

      final family = FamilyModel.fromMap({
        ...familyDoc.data()!,
        'id': familyDoc.id,
      });

      Get.to(
            () => FamilyDetailsScreen(
          family: family,
        ),
      );
    } on FamilyCreationException catch (e) {
      Get.snackbar(
        'تنبيه',
        e.message,
      );
    } on FirebaseException catch (e) {
      Get.snackbar(
        'خطأ',
        e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لعرض بيانات هذه الأسرة'
            : 'تعذر تحميل بيانات الأسرة',
      );
    } catch (e) {
      debugPrint(
        'OPEN FAMILY ERROR: $e',
      );

      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء فتح تفاصيل الأسرة',
      );
    }
  }

  // ==========================================
  // After Saving
  // ==========================================

  void goHome() {
    Get.until(
          (route) => route.isFirst,
    );
  }

  void startAnotherFamily() {
    _resetDraft();

    Get.close(2);
  }

  void _resetDraft() {
    headNameController.clear();
    nationalIdController.clear();
    phoneController.clear();
    membersCountController.clear();
    addressController.clear();

    housingStatus.value = null;
    selectedNeeds.clear();

    housingError.value = null;
    needsError.value = null;

    savedFamilyId.value = null;
    removeIdCardImage();

    existingFamily.value = null;
    localIdStatus.value =
        LocalIdStatus.idle;

    saveError.value = null;
    isConfirmed.value = false;
    isSaved.value = false;

    _draftId = null;
  }

  // ==========================================
  // Dispose Controllers
  // ==========================================

  @override
  void onClose() {
    headNameController.dispose();
    nationalIdController.dispose();
    phoneController.dispose();
    membersCountController.dispose();

    areaNameController.dispose();
    addressController.dispose();

    super.onClose();
  }
  void selectArea(String? value) {
    selectedAreaId.value = value;
    areaId = value ?? '';
    areaError.value = null;

    final selected = availableAreas.firstWhereOrNull(
          (area) => area['id'] == value,
    );

    areaNameController.text = selected?['name'] ?? '';
  }
}
