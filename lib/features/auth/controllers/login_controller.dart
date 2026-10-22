
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final passwordController = TextEditingController();

  final isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  @override
  void onClose() {
    passwordController.dispose();
    super.onClose();
  }
}
