
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/home/employee/views/home_screen.dart';
import 'package:sijil/features/home/manager/views/manager_home_screen.dart';

import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    if (isClosed) return;
    isPasswordVisible.toggle();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (isClosed || isLoading.value) return;

    final cleanEmail = email.trim();

    if (cleanEmail.isEmpty || password.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      );
      return;
    }

    bool authenticated = false;
    bool loginSucceeded = false;

    String stage = 'authentication';
    String? errorTitle;
    String? errorMessage;

    try {
      isLoading.value = true;

      // -----------------------------------
      // 1. Firebase Authentication
      // -----------------------------------

      debugPrint('LOGIN: Authenticating');

      final credential = await _authService.login(
        cleanEmail,
        password,
      );

      authenticated = true;

      final user = credential.user ?? _auth.currentUser;

      if (user == null) {
        throw const _LoginRejected(
          'تعذر تسجيل الدخول',
          'تعذر الحصول على بيانات المستخدم',
        );
      }

      debugPrint('LOGIN: Auth success, UID=${user.uid}');

      // -----------------------------------
      // 2. Read user profile
      // -----------------------------------

      stage = 'user_profile';

      debugPrint(
        'LOGIN: Reading users/${user.uid}',
      );

      debugPrint(
        'LOGIN: Project ${_firestore.app.options.projectId}',
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(
        const GetOptions(source: Source.server),
      );

      debugPrint(
        'LOGIN: User profile read successfully',
      );

      if (!userDoc.exists) {
        throw const _LoginRejected(
          'غير مصرح',
          'لا يوجد حساب معتمد لهذا المستخدم',
        );
      }

      final data = userDoc.data()!;

      final status = data['status'];
      final role = data['role'];
      final organizationId = data['organizationId'];
      final areaId = data['areaId'];

      // -----------------------------------
      // 3. Validate user permissions
      // -----------------------------------

      stage = 'validation';

      if (status != 'active') {
        throw const _LoginRejected(
          'الحساب غير نشط',
          'يرجى التواصل مع المشرف لتفعيل حسابك',
        );
      }

      if (role != 'supervisor' &&
          role != 'field_worker') {
        throw const _LoginRejected(
          'غير مصرح',
          'الدور الوظيفي غير معتمد',
        );
      }

      if (organizationId is! String ||
          organizationId.trim().isEmpty) {
        throw const _LoginRejected(
          'بيانات غير مكتملة',
          'المؤسسة المرتبطة بالحساب غير محددة',
        );
      }

      if (role == 'field_worker' &&
          (areaId is! String ||
              areaId.trim().isEmpty)) {
        throw const _LoginRejected(
          'بيانات غير مكتملة',
          'منطقة عمل الموظف غير محددة',
        );
      }

      if (isClosed) return;

      // -----------------------------------
      // 4. Start user session
      // -----------------------------------


      stage = 'session';

      debugPrint('LOGIN: Starting session');
      debugPrint('LOGIN: Role = $role');
      debugPrint('LOGIN: Organization = $organizationId');
      debugPrint('LOGIN: Area = $areaId');

      try {
        final sessionController =
        Get.find<UserSessionController>();

        await sessionController.startSession(
          role as String,
        );

        debugPrint('LOGIN: Session started successfully');
      } catch (e, stackTrace) {
        debugPrint('SESSION START ERROR: $e');
        debugPrintStack(stackTrace: stackTrace);
        rethrow;
      }


      // Authentication and authorization succeeded.
      loginSucceeded = true;

      if (isClosed) return;

      // -----------------------------------
      // 5. Navigate to home screen
      // -----------------------------------

      stage = 'navigation';

      if (role == 'supervisor') {
        Get.offAll(() => ManagerHomeScreen());
      } else if (role == 'field_worker') {
        Get.offAll(() => HomeScreen());
      }

    } on _LoginRejected catch (e) {
      errorTitle = e.title;
      errorMessage = e.message;

    } on FirebaseAuthException catch (e) {
      debugPrint(
        'LOGIN AUTH ERROR: ${e.code} - ${e.message}',
      );

      errorTitle = 'تعذر تسجيل الدخول';
      errorMessage = _authErrorMessage(e);

    } on FirebaseException catch (e) {
      debugPrint('LOGIN FIREBASE ERROR');
      debugPrint('STAGE: $stage');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('PLUGIN: ${e.plugin}');

      errorTitle = 'تعذر إكمال تسجيل الدخول';

      if (e.code == 'permission-denied') {
        errorMessage = stage == 'user_profile'
            ? 'لا توجد صلاحية لقراءة وثيقة المستخدم'
            : stage == 'session'
            ? 'تعذر بدء الجلسة بسبب صلاحيات Firebase'
            : 'تم رفض عملية Firebase بسبب الصلاحيات';
      } else if (e.code == 'unavailable') {
        errorMessage = 'تعذر الاتصال بخدمة Firebase';
      } else {
        errorMessage = e.message ??
            'حدث خطأ أثناء تنفيذ عملية Firebase';
      }

    } catch (e, stackTrace) {
      debugPrint('LOGIN UNEXPECTED ERROR');
      debugPrint('STAGE: $stage');
      debugPrint('ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      errorTitle = 'حدث خطأ';
      errorMessage = 'تعذر إكمال تسجيل الدخول';
    } finally {
      // -----------------------------------
      // 6. Cleanup unsuccessful attempt
      // -----------------------------------

      if (authenticated && !loginSucceeded) {
        try {
          debugPrint(
            'LOGIN: Signing out after failed attempt',
          );

          await _authService.logout();
        } catch (e) {
          debugPrint('LOGIN LOGOUT ERROR: $e');
        }
      }

      if (!isClosed) {
        isLoading.value = false;

        if (errorMessage != null) {
          Get.snackbar(
            errorTitle ?? 'خطأ',
            errorMessage,
          );
        }
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';

      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';

      case 'too-many-requests':
        return 'محاولات كثيرة، يرجى المحاولة لاحقًا';

      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت';

      default:
        return e.message ?? 'حدث خطأ أثناء تسجيل الدخول';
    }
  }
}

class _LoginRejected implements Exception {
  final String title;
  final String message;

  const _LoginRejected(this.title, this.message);
}
