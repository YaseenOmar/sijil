import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../models/employee_model.dart';

class EmployeeController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  final RxBool isLoading = false.obs;
  // Stores the received sign-in link
  final RxnString pendingInvitationLink = RxnString();

  @override
  void onInit() {
    super.onInit();
    listenForInvitationLinks();
  }

  // Add employee and send invitation
  Future<void> addEmployee({
    required String fullName,
    required String email,
    required String role,
    required String areaId,
    required String organizationId,
  }) async {
    if (isLoading.value) return;

    isLoading.value = true;

    bool employeeSaved = false;

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final employeeEmail = email.trim().toLowerCase();

      if (fullName.trim().isEmpty ||
          employeeEmail.isEmpty ||
          role.isEmpty ||
          areaId.isEmpty ||
          organizationId.isEmpty) {
        throw Exception('يرجى تعبئة جميع الحقول');
      }

      final employee = EmployeeModel(
        id: '',
        fullName: fullName.trim(),
        email: employeeEmail,
        role: role,
        areaId: areaId,
        organizationId: organizationId,
        createdBy: currentUser.uid,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      // Save employee in Firestore
      await _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('employees')
          .add(employee.toMap());

      employeeSaved = true;

      // Send invitation email
      await sendEmployeeInvitation(email: employee.email);

      Get.snackbar(
        'تم إرسال الدعوة',
        'تم حفظ بيانات الموظف وطلب إرسال رابط تسجيل الدخول',
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        employeeSaved
            ? 'تم حفظ الموظف، لكن فشل إرسال البريد: $e'
            : 'فشلت إضافة الموظف: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Send Firebase email sign-in link
  Future<void> sendEmployeeInvitation({required String email}) async {
    final employeeEmail = email.trim().toLowerCase();

    if (employeeEmail.isEmpty) {
      throw Exception('البريد الإلكتروني مطلوب');
    }

    final settings = ActionCodeSettings(
      url: 'https://sijil-aa471.web.app',
      handleCodeInApp: true,
      androidPackageName: 'com.sijil.sijil',
      androidInstallApp: false,
    );

    await _auth.sendSignInLinkToEmail(
      email: employeeEmail,
      actionCodeSettings: settings,
    );
  }

  // Listen for incoming email links
  void listenForInvitationLinks() {
    _linkSubscription ??= _appLinks.uriLinkStream.listen(
      (uri) {
        final link = uri.toString();

        if (_auth.isSignInWithEmailLink(link)) {
          pendingInvitationLink.value = link;
        }
      },
      onError: (error) {
        Get.snackbar('خطأ', 'تعذر استقبال رابط الدعوة');
      },
    );
  }

  // Check whether an invitation link was received
  bool get hasPendingInvitation => pendingInvitationLink.value != null;

  Future<bool> acceptInvitation({required String email}) async {
    if (isLoading.value) return false;

    try {
      isLoading.value = true;

      final employeeEmail = email.trim().toLowerCase();

      // Get received invitation link
      final emailLink = pendingInvitationLink.value;

      if (employeeEmail.isEmpty) {
        throw Exception('يرجى إدخال البريد الإلكتروني');
      }

      if (emailLink == null) {
        throw Exception('لم يتم العثور على رابط الدعوة');
      }

      // Validate Firebase email sign-in link
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception('رابط الدعوة غير صالح');
      }

      // Sign in with email link
      final credential = await _auth.signInWithEmailLink(
        email: employeeEmail,
        emailLink: emailLink,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      // Clear used invitation link
      pendingInvitationLink.value = null;

      Get.snackbar(
        'تم التحقق بنجاح',
        'تم تأكيد البريد الإلكتروني، والحساب بانتظار التفعيل',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صالح';
          break;

        case 'invalid-action-code':
        case 'expired-action-code':
          message = 'رابط تسجيل الدخول غير صالح أو منتهي الصلاحية';
          break;

        case 'user-disabled':
          message = 'هذا الحساب معطّل';
          break;

        default:
          message = e.message ?? 'فشل التحقق من البريد الإلكتروني';
      }

      Get.snackbar('خطأ', message);
      return false;
    } catch (e) {
      Get.snackbar('خطأ', e.toString());

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _linkSubscription?.cancel();
    super.onClose();
  }
}
