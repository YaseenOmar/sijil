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

// Result of the on-device duplicate check.
enum LocalIdStatus { idle, noMatch, match }

class FamilyCreationController extends GetxController {
  final FamilyCreationService _service = FamilyCreationService();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final ImagePicker _picker = ImagePicker();

  // ---------- Form keys ----------
  final basicFormKey = GlobalKey<FormState>();
  final housingFormKey = GlobalKey<FormState>();

  // ---------- Step 1: Basic information ----------
  final headNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();
  final membersCountController = TextEditingController();

  // ---------- Step 2: Housing and needs ----------

  String areaId = FamilyOptions.defaultAreaId;

  final areaNameController = TextEditingController(
    text: FamilyOptions.areaName(FamilyOptions.defaultAreaId),
  );

  final addressController = TextEditingController();

  final housingStatus = RxnString();

  final selectedNeeds = <String>[].obs;

  final housingError = RxnString();
  final needsError = RxnString();

  // ---------- Optional ID image ----------
  final idCardImagePath = RxnString();
  final idCardImageSizeKb = 0.obs;

  // ---------- UI states ----------
  final isCheckingId = false.obs;
  final isSaving = false.obs;
  final isSaved = false.obs;
  final savedFamilyId = RxnString();
  final isConfirmed = false.obs;

  final saveError = RxnString();

  // Keep this property for the existing duplicate screen.
  final existingFamily = Rxn<FamilyModel>();

  final localIdStatus = LocalIdStatus.idle.obs;

  // Reuse the same document ID when retrying.
  String? _draftId;

  @override
  void onInit() {
    super.onInit();
    _loadAssignedArea();
  }

  // Load the field worker's area from their account.

  Future<void> _loadAssignedArea() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get(const GetOptions(source: Source.server));

      if (!userDoc.exists) return;

      final userData = userDoc.data()!;

      if (userData['status'] != 'active') return;

      if (userData['role'] != 'field_worker') {
        return;
      }

      final orgId = userData['organizationId'];
      final invitationId = userData['invitationId'];

      if (orgId is! String ||
          orgId.isEmpty ||
          invitationId is! String ||
          invitationId.isEmpty) {
        throw const FamilyCreationException('بيانات ارتباط الموظف غير مكتملة');
      }

      final employeeDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('employees')
          .doc(invitationId)
          .get(const GetOptions(source: Source.server));

      if (!employeeDoc.exists) {
        throw const FamilyCreationException('سجل الموظف غير موجود');
      }

      final employee = employeeDoc.data()!;

      if (employee['uid'] != currentUser.uid ||
          employee['organizationId'] != orgId ||
          employee['role'] != 'field_worker' ||
          employee['status'] != 'active') {
        throw const FamilyCreationException('سجل الموظف غير صالح');
      }

      final assignedArea = employee['areaId'];

      if (assignedArea is! String || assignedArea.isEmpty) {
        throw const FamilyCreationException('منطقة الموظف غير محددة');
      }

      areaId = assignedArea;

      areaNameController.text = FamilyOptions.areaName(assignedArea);
    } catch (e) {
      debugPrint('Failed to load assigned area: $e');

      Get.snackbar(
        'تعذر تحميل المنطقة',
        'لم نتمكن من تحديد منطقة الموظف. تحقق من الاتصال وأعد المحاولة.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ---------- Clean values ----------

  String get headName => headNameController.text.trim();

  String get nationalId => toLatinDigits(nationalIdController.text.trim());

  String get phone =>
      toLatinDigits(phoneController.text).replaceAll(RegExp(r'[\s-]'), '');

  int get membersCount =>
      int.tryParse(toLatinDigits(membersCountController.text.trim())) ?? 0;

  String get address => addressController.text.trim();

  List<String> get orderedNeeds => FamilyOptions.needs
      .where((need) => selectedNeeds.contains(need))
      .toList();

  // ---------- Step 1 ----------

  // Check only locally cached data while typing.
  Future<void> onNationalIdChanged(String _) async {
    final id = nationalId;

    if (!RegExp(r'^\d{9}$').hasMatch(id)) {
      localIdStatus.value = LocalIdStatus.idle;
      return;
    }

    final found = await _service.findLocalFamilyByNationalId(id);

    // Ignore outdated results.
    if (id != nationalId) return;

    // A cache miss does not prove the ID is available.
    localIdStatus.value = found == null
        ? LocalIdStatus.idle
        : LocalIdStatus.match;
  }

  Future<void> submitBasicInfo() async {
    if (isCheckingId.value) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (!(basicFormKey.currentState?.validate() ?? false)) {
      return;
    }

    try {
      isCheckingId.value = true;

      final existing = await _service.findFamilyByNationalId(nationalId);

      if (existing != null) {
        existingFamily.value = existing;
        localIdStatus.value = LocalIdStatus.match;

        Get.to(() => const DuplicateFamilyScreen());
        return;
      }

      // National ID is not reserved on the server.
      existingFamily.value = null;
      localIdStatus.value = LocalIdStatus.noMatch;

      Get.to(() => FamilyHousingNeedsScreen());
    } on FamilyCreationException catch (e) {
      if (e.message.startsWith('هذه الأسرة مسجلة مسبقاً')) {
        localIdStatus.value = LocalIdStatus.match;
      }

      Get.snackbar(
        'تنبيه',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع أثناء التحقق من رقم الهوية');
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

  void editBasicInfo() => Get.close(2);

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

      // Build with the authenticated user's actual data.
      final family = await _buildFamily();

      // Remote transaction saves family and ID reservation.
      final familyId = await _service.addFamily(family);

      savedFamilyId.value = familyId;
      isSaved.value = true;

      Get.snackbar('نجاح', 'تم حفظ الأسرة بنجاح');
    } on FamilyCreationException catch (e) {
      saveError.value = e.message;
      Get.snackbar('خطأ', e.message);
    } catch (e) {
      saveError.value = 'حدث خطأ غير متوقع أثناء حفظ الأسرة';

      Get.snackbar('خطأ', saveError.value!);
    } finally {
      isSaving.value = false;
    }
  }

  // Build family using the authenticated user.
  Future<FamilyModel> _buildFamily() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw const FamilyCreationException('يجب تسجيل الدخول أولاً');
    }

    final userDoc = await _firestore
        .collection('users')
        .doc(currentUser.uid)
        .get(const GetOptions(source: Source.server));

    if (!userDoc.exists) {
      throw const FamilyCreationException('لم يتم العثور على بيانات المستخدم');
    }

    final userData = userDoc.data()!;

    if (userData['status'] != 'active') {
      throw const FamilyCreationException('الحساب غير نشط');
    }

    final role = userData['role'];

    if (role != 'supervisor' && role != 'field_worker') {
      throw const FamilyCreationException('ليس لديك صلاحية لإضافة الأسر');
    }

    final organizationId = userData['organizationId'];

    if (organizationId is! String || organizationId.isEmpty) {
      throw const FamilyCreationException('لم يتم تحديد المؤسسة');
    }

    String selectedAreaId = areaId;

    if (role == 'field_worker') {
      final invitationId = userData['invitationId'];

      if (invitationId is! String || invitationId.isEmpty) {
        throw const FamilyCreationException('سجل دعوة الموظف غير محدد');
      }

      final employeeDoc = await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('employees')
          .doc(invitationId)
          .get(const GetOptions(source: Source.server));

      if (!employeeDoc.exists) {
        throw const FamilyCreationException('سجل الموظف غير موجود');
      }

      final employee = employeeDoc.data()!;

      if (employee['uid'] != currentUser.uid ||
          employee['organizationId'] != organizationId ||
          employee['role'] != 'field_worker' ||
          employee['status'] != 'active') {
        throw const FamilyCreationException('لا توجد صلاحية فعالة لإضافة أسرة');
      }

      final assignedArea = employee['areaId'];

      if (assignedArea is! String || assignedArea.isEmpty) {
        throw const FamilyCreationException('لم يتم تحديد منطقة الموظف');
      }

      selectedAreaId = assignedArea;
    }

    if (!RegExp(r'^\d{9}$').hasMatch(nationalId)) {
      throw const FamilyCreationException('رقم الهوية يجب أن يتكون من 9 أرقام');
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


  Future<void> openSavedFamily() async {
    final familyId = savedFamilyId.value;

    if (familyId == null || familyId.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لم يتم العثور على معرف الأسرة المحفوظة',
      );
      return;
    }

    try {
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
          .get(const GetOptions(source: Source.server));

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
            () => FamilyDetailsScreen(family: family),
      );
    } on FamilyCreationException catch (e) {
      Get.snackbar('تنبيه', e.message);
    } on FirebaseException catch (e) {
      Get.snackbar(
        'خطأ',
        e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لعرض بيانات هذه الأسرة'
            : 'تعذر تحميل بيانات الأسرة',
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء فتح تفاصيل الأسرة',
      );
    }
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
    savedFamilyId.value = null;
    removeIdCardImage();

    existingFamily.value = null;
    localIdStatus.value = LocalIdStatus.idle;

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
