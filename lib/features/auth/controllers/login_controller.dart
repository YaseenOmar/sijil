import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/home/views/home_screen.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;
  final isLoading = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // تسجيل الدخول
  Future<void> login() async {
    if (isLoading.value) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    // check fields if empty
    if (email.isEmpty || password.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى إدخال البريد الإلكتروني وكلمة المرور');
      return;
    }

    try {
      isLoading.value = true;
      await _authService.login(email, password);

      Get.snackbar('نجاح', 'تم تسجيل الدخول بنجاح');
      // لاحقاً: الانتقال للشاشة المناسبة حسب دور الموظف (ميداني، مشرف، مدير)
      Get.offAll(() => const HomeScreen());

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

    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ غير متوقع');
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
