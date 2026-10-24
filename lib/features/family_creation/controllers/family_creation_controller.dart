import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sijil/core/constants/demo_context.dart';
import 'package:sijil/features/families/data/models/family_model.dart';
import 'package:sijil/features/family_creation/constants/family_options.dart';
import 'package:sijil/features/family_creation/services/family_creation_service.dart';
import 'package:sijil/features/family_creation/utils/text_utils.dart';
import 'package:sijil/features/family_creation/views/duplicate_family_screen.dart';
import 'package:sijil/features/family_creation/views/family_housing_needs_screen.dart';
import 'package:sijil/features/family_creation/views/family_review_screen.dart';
import 'package:uuid/uuid.dart';

// One controller for the 3 steps: basic data -> housing & needs -> review
class FamilyCreationController extends GetxController {
  final FamilyCreationService _service = FamilyCreationService();
  final ImagePicker _picker = ImagePicker();

  // One form key per step (each key belongs to one Form only)
  final basicFormKey = GlobalKey<FormState>();
  final housingFormKey = GlobalKey<FormState>();

  // ---------- Step 1: basic data ----------
  final headNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();
  final membersCountController = TextEditingController();

  // ---------- Step 2: housing & needs ----------
  final String areaId = FamilyOptions.defaultAreaId;
  final areaNameController = TextEditingController(
    text: FamilyOptions.areaName(FamilyOptions.defaultAreaId),
  );
  final addressController = TextEditingController();

  final housingStatus = RxnString();
  final selectedNeeds = <String>[].obs;
  final housingError = RxnString();
  final needsError = RxnString();

  // Local ID card image (optional)
  final idCardImagePath = RxnString();
  final idCardImageSizeKb = 0.obs;

  // ---------- UI states ----------
  final isCheckingId = false.obs;
  final isSaving = false.obs;
  final isSaved = false.obs;
  final isConfirmed = false.obs;
  final saveError = RxnString();

  // Family found by national ID (duplicate screen)
  final existingFamily = Rxn<FamilyModel>();

  // Same ID is reused when the user retries saving the same family
  String? _draftId;

  // ---------- Clean values ----------
  String get headName => headNameController.text.trim();
  String get nationalId => toLatinDigits(nationalIdController.text.trim());
  String get phone =>
      toLatinDigits(phoneController.text).replaceAll(RegExp(r'[\s-]'), '');
  int get membersCount =>
      int.tryParse(toLatinDigits(membersCountController.text.trim())) ?? 0;
  String get address => addressController.text.trim();

  // Needs in the same order as the options list
  List<String> get orderedNeeds => FamilyOptions.needs
      .where((need) => selectedNeeds.contains(need))
      .toList();

  // ---------- Step 1 ----------
  Future<void> submitBasicInfo() async {
    if (isCheckingId.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(basicFormKey.currentState?.validate() ?? false)) return;

    try {
      isCheckingId.value = true;

      // Check if the family is already registered
      final existing = await _service.findFamilyByNationalId(nationalId);

      if (existing != null) {
        existingFamily.value = existing;
        Get.to(() => const DuplicateFamilyScreen());
        return;
      }

      existingFamily.value = null;
      Get.to(() => FamilyHousingNeedsScreen());
    } on FamilyCreationException catch (e) {
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع');
    } finally {
      isCheckingId.value = false;
    }
  }

  // ---------- Step 2 ----------
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

  Future<void> pickIdCardImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );

      // User closed the picker
      if (picked == null) return;

      final bytes = await File(picked.path).length();

      idCardImagePath.value = picked.path;
      idCardImageSizeKb.value = (bytes / 1024).ceil();
    } catch (e) {
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

  void submitHousingInfo() {
    FocusManager.instance.primaryFocus?.unfocus();

    final isFormValid = housingFormKey.currentState?.validate() ?? false;

    housingError.value = housingStatus.value == null
        ? 'يرجى اختيار حالة السكن'
        : null;
    needsError.value = selectedNeeds.isEmpty
        ? 'يرجى اختيار احتياج واحد على الأقل'
        : null;

    if (!isFormValid ||
        housingError.value != null ||
        needsError.value != null) {
      return;
    }

    Get.to(() => FamilyReviewScreen());
  }

  // ---------- Step 3 ----------
  void setConfirmed(bool value) {
    isConfirmed.value = value;
  }

  // Back to step 1 (review -> housing -> basic)
  void editBasicInfo() => Get.close(2);

  // Back to step 2
  void editHousingInfo() => Get.back();

  Future<void> saveFamily() async {
    if (isSaving.value || isSaved.value) return;

    if (!isConfirmed.value) {
      Get.snackbar('تنبيه', 'يرجى تأكيد التحقق من البيانات مع الأسرة');
      return;
    }

    try {
      isSaving.value = true;
      saveError.value = null;

      await _service.addFamily(_buildFamily());

      isSaved.value = true;
      Get.snackbar('نجاح', 'تم حفظ الأسرة بنجاح');
    } on FamilyCreationException catch (e) {
      saveError.value = e.message;
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      saveError.value = 'حدث خطأ غير متوقع أثناء حفظ الأسرة';
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع');
    } finally {
      isSaving.value = false;
    }
  }

  FamilyModel _buildFamily() {
    // Create the ID once; retrying must not create a new family ID
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
      areaId: areaId,
      createdBy: DemoContext.employeeId,
      organizationId: DemoContext.organizationId,
    );
  }

  // ---------- After saving ----------
  void goHome() {
    Get.until((route) => route.isFirst);
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
    removeIdCardImage();

    existingFamily.value = null;
    saveError.value = null;
    isConfirmed.value = false;
    isSaved.value = false;
    _draftId = null;
  }

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
}
