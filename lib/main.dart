
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';

import 'features/auth/controllers/user_session_controller.dart';
import 'features/auth/controllers/session_activity_monitor.dart';
import 'features/auth/views/splash_screen.dart';

import 'features/employees/controllers/employee_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register controllers
  Get.put(EmployeeController(), permanent: true);
  Get.put(UserSessionController(), permanent: true);

  // Start application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,

      locale: const Locale('ar'),

      theme: AppTheme.lightTheme,

      // First screen
      home: const SplashScreen(),

      // Monitor user activity
      builder: (context, child) {
        return SessionActivityMonitor(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
