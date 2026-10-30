
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/features/auth/controllers/user_session_controller.dart';
import 'package:sijil/features/auth/views/login_screen.dart';
import 'package:sijil/features/home/employee/views/home_screen.dart';
import 'package:sijil/features/home/manager/views/manager_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserSessionController sessionController =
  Get.find<UserSessionController>();

  bool isChecking = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    checkUserSession();
  }


  Future<void> checkUserSession() async {
    setState(() {
      isChecking = true;
      hasError = false;
    });

    try {
      // Start session validation and minimum splash delay together
      final results = await Future.wait([
        sessionController.restoreSession(),
        Future.delayed(const Duration(seconds: 2)),
      ]);

      final isLoggedIn = results[0] as bool;

      if (!mounted) return;

      if (!isLoggedIn) {
        Get.offAll(() => LoginScreen());
        return;
      }

      if (sessionController.isSupervisor) {
        Get.offAll(() => ManagerHomeScreen());
      } else if (sessionController.isFieldWorker) {
        Get.offAll(() =>  HomeScreen());
      } else {
        await sessionController.logout(navigate: false);

        if (!mounted) return;

        Get.offAll(() => LoginScreen());
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isChecking = false;
        hasError = true;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.neutralBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 32,
            ),
            child: Column(
              children: [
                const Spacer(),

                Container(
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

                const SizedBox(height: 24),

                // Application name
                const Text(
                  'سِجل',
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(height: 12),

                // Application slogan
                const Text(
                  'بيانات موثوقة. مساعدة في وقتها.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'مساحة عمل فريقك لتسجيل الأسر ومتابعة '
                      'المساعدات والإحالات بكرامة وخصوصية.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.7,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 40),

                if (isChecking) ...[
                  const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'جاري التحقق من الجلسة...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],

                if (hasError) ...[
                  const Icon(
                    Icons.wifi_off_outlined,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'تعذر التحقق من جلسة المستخدم',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 16),

                  ElevatedButton.icon(
                    onPressed: checkUserSession,
                    icon: const Icon(Icons.refresh),
                    label: const Text('إعادة المحاولة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],

                const Spacer(),

                const Text(
                  'مخصص للموظفين المعتمدين لدى جهات العمل المشاركة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
