
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/home/employee/views/home_screen.dart';
import 'package:sijil/features/home/manager/views/manager_home_screen.dart';

import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  Future<void> login() async {
    if (isLoading.value) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى إدخال البريد الإلكتروني وكلمة المرور',
      );
      return;
    }

    try {
      isLoading.value = true;

      // 1. Authenticate with Firebase
      final credential =
      await _authService.login(email, password);

      final user = credential.user;

      if (user == null) {
        throw Exception('فشل تسجيل الدخول');
      }

      // 2. Get user profile from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      // 3. Check if user exists
      if (!userDoc.exists) {
        await _authService.logout();

        Get.snackbar(
          'غير مصرح',
          'لا يوجد حساب معتمد لهذا المستخدم',
        );
        return;
      }

      final userData = userDoc.data()!;

      final status = userData['status'];
      final role = userData['role'];

      // 4. Check account status
      if (status != 'active') {
        await _authService.logout();

        Get.snackbar(
          'الحساب غير نشط',
          'يرجى التواصل مع المشرف لتفعيل حسابك',
        );
        return;
      }

      // 5. Check user role
      if (role != 'supervisor' &&
          role != 'field_worker') {
        await _authService.logout();

        Get.snackbar(
          'غير مصرح',
          'الدور الوظيفي غير معتمد',
        );
        return;
      }

      // 6. Save user session and last activity
      final sessionController =
      Get.find<UserSessionController>();

      await sessionController.startSession(role as String);

      Get.snackbar(
        'نجاح',
        'تم تسجيل الدخول بنجاح',
      );

      // 7. Navigate based on user role
      if (role == 'supervisor') {
        Get.offAll(() => const ManagerHomeScreen());
      } else if (role == 'field_worker') {
        Get.offAll(() => const HomeScreen());
      }

    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;

        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
          message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة';
          break;

        case 'user-disabled':
          message = 'تم تعطيل هذا الحساب';
          break;

        case 'too-many-requests':
          message = 'محاولات كثيرة، يرجى المحاولة لاحقاً';
          break;

        case 'network-request-failed':
          message = 'تعذر الاتصال بالإنترنت';
          break;

        default:
          message = 'حدث خطأ أثناء تسجيل الدخول';
      }

      Get.snackbar('خطأ', message);

    } on FirebaseException catch (e) {
      Get.snackbar(
        'خطأ في قاعدة البيانات',
        e.code == 'permission-denied'
            ? 'لا توجد صلاحية لقراءة بيانات الحساب'
            : 'تعذر التحقق من بيانات الحساب',
      );

    } catch (e) {
      Get.snackbar(
        'خطأ',
        'حدث خطأ غير متوقع أثناء تسجيل الدخول',
      );

    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
