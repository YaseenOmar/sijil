import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:sijil/core/widgets/app_status_card.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final LoginController controller;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(LoginController());
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,

        appBar: CustomAppBar(
          title: 'أهلاً بك في سِجل',
          action: Icons.verified_user_outlined,
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                _buildLogo(),

                const SizedBox(height: 8),

                // title
                const Text(
                  'سِجل',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'بيانات موثوقة. مساعدة في وقتها.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'مساحة عمل فريقك لتسجيل الأسر ومتابعة '
                  'المساعدات والإحالات بكرامة وخصوصية.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                AppTextField(
                  label: 'البريد الإلكتروني',
                  hint: 'ahmad@alaman.org',
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  isRequired: true,
                  suffixIcon: Icons.email,
                ),

                const SizedBox(height: 20),

                Obx(
                  () => AppTextField(
                    label: 'كلمة المرور',
                    isRequired: true,
                    hint: '••••••••',
                    controller: passwordController,
                    obscureText: !controller.isPasswordVisible.value,
                    suffixIcon: controller.isPasswordVisible.value
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixIconPressed: controller.togglePasswordVisibility,
                  ),
                ),

                const SizedBox(height: 48),

                Obx(
                  () => AppButton(
                    text: 'تسجيل الدخول',
                    icon: Icons.arrow_forward,
                    isLoading: controller.isLoading.value,
                    onPressed: () {
                      controller.login(
                        email: emailController.text,
                        password: passwordController.text,
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // contact with supervisor
                AppButton(
                  text: 'تحتاج إلى مساعدة؟ تواصل مع المشرف',
                  type: AppButtonType.secondary,
                  onPressed: () {},
                ),

                const SizedBox(height: 20),

                const AppStatusCard(
                  title: 'الاتصال مطلوب لأول تسجيل دخول',
                  message:
                      'بعد تسجيل الدخول بنجاح، يمكنك استخدام جلستك المحفوظة دون اتصال. لا يمكن بدء جلسة جديدة دون إنترنت.',
                  type: AppStatusType.online,
                ),

                const SizedBox(height: 20),

                const Text(
                  'مخصص للموظفين المعتمدين لدى جهات العمل المشاركة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 64,
        height: 64,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SvgPicture.asset(
          'assets/images/vector.svg',
          fit: BoxFit.contain,
          width: 24,
          height: 26,
        ),
      ),
    );
  }
}
