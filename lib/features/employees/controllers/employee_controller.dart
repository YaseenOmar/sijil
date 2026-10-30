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
  final RxnString pendingOrganizationId = RxnString();
  final RxnString pendingInvitationId = RxnString();

  @override
  void onInit() {
    super.onInit();
    listenForInvitationLinks();
  }

  // Add employee and send invitation
  Future<bool> addEmployee({
    required String fullName,
    required String email,
    required String role,
    required String areaId,
    required String organizationId,
  }) async {
    if (isLoading.value) return false;

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
        uid: null,
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
      final employeeRef = _firestore
          .collection('organizations')
          .doc(organizationId)
          .collection('employees')
          .doc();

      // Save employee invitation with a known document ID
      await employeeRef.set(employee.toMap());

      employeeSaved = true;

      // Send invitation with organization and invitation IDs
      await sendEmployeeInvitation(
        email: employee.email,
        organizationId: organizationId,
        invitationId: employeeRef.id,
      );

      Get.snackbar(
        'تم إرسال الدعوة',
        'تم حفظ بيانات الموظف وطلب إرسال رابط تسجيل الدخول',
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        employeeSaved
            ? 'تم حفظ الموظف، لكن فشل إرسال البريد: $e'
            : 'فشلت إضافة الموظف: $e',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Send Firebase email sign-in link

  Future<void> sendEmployeeInvitation({
    required String email,
    required String organizationId,
    required String invitationId,
  }) async {
    final employeeEmail = email.trim().toLowerCase();

    if (employeeEmail.isEmpty) {
      throw Exception('البريد الإلكتروني مطلوب');
    }

    // Continue URL with invitation information
    final continueUrl = Uri.https('sijil-aa471.web.app', '/invite', {
      'orgId': organizationId,
      'inviteId': invitationId,
    });

    final settings = ActionCodeSettings(
      url: continueUrl.toString(),
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
        _handleInvitationUri(uri);
      },
      onError: (error) {
        Get.snackbar('خطأ', 'تعذر استقبال رابط الدعوة');
      },
    );
  }

  void _handleInvitationUri(Uri uri) {
    try {
      // Firebase links may contain nested URLs.
      Uri currentUri = uri;

      for (int i = 0; i < 5; i++) {
        final nestedLink = currentUri.queryParameters['link'];

        if (nestedLink == null) break;

        currentUri = Uri.parse(nestedLink);
      }

      // Firebase authentication link
      final emailLink = currentUri.toString();

      if (!_auth.isSignInWithEmailLink(emailLink)) {
        return;
      }

      // Extract the continuation URL
      final continueUrl = currentUri.queryParameters['continueUrl'];

      if (continueUrl == null) {
        throw Exception('بيانات الدعوة غير موجودة');
      }

      final invitationUri = Uri.parse(continueUrl);

      if (invitationUri.scheme != 'https' ||
          invitationUri.host != 'sijil-aa471.web.app' ||
          invitationUri.path != '/invite') {
        throw Exception('رابط المتابعة غير صحيح');
      }

      final orgId = invitationUri.queryParameters['orgId'];

      final inviteId = invitationUri.queryParameters['inviteId'];

      if (orgId == null ||
          orgId.isEmpty ||
          inviteId == null ||
          inviteId.isEmpty) {
        throw Exception('بيانات الدعوة غير مكتملة');
      }

      pendingInvitationLink.value = emailLink;
      pendingOrganizationId.value = orgId;
      pendingInvitationId.value = inviteId;
    } catch (e) {
      Get.snackbar('رابط غير صالح', 'تعذر قراءة بيانات الدعوة');
    }
  }

  // Check whether an invitation link was received
  // Check whether complete invitation data was received
  bool get hasPendingInvitation =>
      pendingInvitationLink.value != null &&
      pendingOrganizationId.value != null &&
      pendingInvitationId.value != null;

  Future<bool> acceptInvitation({required String email}) async {
    if (isLoading.value) return false;

    isLoading.value = true;

    try {
      final employeeEmail = email.trim().toLowerCase();

      final emailLink = pendingInvitationLink.value;

      final orgId = pendingOrganizationId.value;

      final inviteId = pendingInvitationId.value;

      // Validate received invitation data
      if (employeeEmail.isEmpty ||
          emailLink == null ||
          orgId == null ||
          inviteId == null) {
        throw Exception('بيانات الدعوة غير مكتملة');
      }

      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception('رابط تسجيل الدخول غير صالح');
      }

      // Step 1: Authenticate employee
      final credential = await _auth.signInWithEmailLink(
        email: employeeEmail,
        emailLink: emailLink,
      );

      final user = credential.user;

      if (user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      // Refresh authentication information
      await user.reload();

      final authenticatedUser = _auth.currentUser!;

      final token = await authenticatedUser.getIdTokenResult(true);

      if (token.claims?['email_verified'] != true) {
        throw Exception('البريد الإلكتروني غير موثق');
      }

      if (authenticatedUser.email?.toLowerCase() != employeeEmail) {
        throw Exception('البريد الإلكتروني غير مطابق');
      }

      // Step 2: Locate employee invitation
      final invitationRef = _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('employees')
          .doc(inviteId);

      final invitationSnapshot = await invitationRef.get();

      if (!invitationSnapshot.exists) {
        throw Exception('لم يتم العثور على الدعوة');
      }

      final invitation = invitationSnapshot.data()!;

      // Step 3: Validate invitation
      if (invitation['status'] != 'pending') {
        throw Exception('تم استخدام الدعوة مسبقاً');
      }

      if (invitation['uid'] != null) {
        throw Exception('الدعوة مرتبطة بحساب آخر');
      }

      if (invitation['email'] != employeeEmail) {
        throw Exception('البريد لا يطابق بريد الدعوة');
      }

      if (invitation['organizationId'] != orgId ||
          invitation['role'] != 'field_worker') {
        throw Exception('بيانات الدعوة غير صالحة');
      }

      // Step 4: Prepare employee account
      final userRef = _firestore.collection('users').doc(authenticatedUser.uid);

      final userSnapshot = await userRef.get();

      if (userSnapshot.exists) {
        throw Exception('يوجد حساب مرتبط بهذا المستخدم');
      }

      final employeeData = <String, dynamic>{
        'fullName': invitation['fullName'],
        'email': invitation['email'],
        'role': invitation['role'],
        'areaId': invitation['areaId'],
        'organizationId': invitation['organizationId'],
        'invitationId': inviteId,
        'status': 'active',
        'createdAt': invitation['createdAt'],
      };

      // Step 5: Atomic Firestore write
      final batch = _firestore.batch();

      batch.set(userRef, employeeData);

      batch.update(invitationRef, {
        'uid': authenticatedUser.uid,
        'status': 'active',
      });

      await batch.commit();

      // Clear invitation data after success
      pendingInvitationLink.value = null;
      pendingOrganizationId.value = null;
      pendingInvitationId.value = null;

      Get.snackbar(
        'تم تفعيل الحساب',
        'تم قبول الدعوة وإنشاء حساب الموظف بنجاح',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar('خطأ في المصادقة', e.message ?? 'تعذر تسجيل الدخول');

      return false;
    } on FirebaseException catch (e) {
      Get.snackbar('خطأ في قاعدة البيانات', e.message ?? 'تعذر تفعيل الحساب');

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
