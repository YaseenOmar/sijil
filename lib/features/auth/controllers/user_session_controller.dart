import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/login_screen.dart';

class UserSessionController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  // ========================================
  // Current User Data
  // ========================================

  final RxString uid = ''.obs;
  final RxString fullName = ''.obs;
  final RxString email = ''.obs;
  final RxString role = ''.obs;
  final RxString organizationId = ''.obs;
  final RxString organizationName = ''.obs;
  final RxString areaId = ''.obs;
  final RxString areaName = ''.obs;
  final RxString status = ''.obs;

  final RxBool isProfileLoading = false.obs;
  final RxBool isProfileLoaded = false.obs;

  bool get isSupervisor => role.value == 'supervisor';

  bool get isFieldWorker => role.value == 'field_worker';

  String get roleName {
    switch (role.value) {
      case 'supervisor':
        return 'مشرف';

      case 'field_worker':
        return 'موظف ميداني';

      default:
        return 'غير محدد';
    }
  }

  // ========================================
  // Session Settings
  // ========================================

  static const Duration sessionTimeout = Duration(days: 3);

  static const String _lastActivityKey = 'last_activity';

  static const String _sessionUserKey = 'session_user';

  Timer? _timer;
  DateTime? _lastActivity;
  bool _isSigningOut = false;

  // ========================================
  // Load User, Organization and Area Data
  // ========================================

  Future<void> loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      clearUserData();
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    isProfileLoading.value = true;
    isProfileLoaded.value = false;

    String currentStep = 'initialization';
    String currentPath = '';

    try {
      // ======================================
      // 1. Read User Profile
      // ======================================

      currentStep = 'STEP 1 - User Profile';
      currentPath = 'users/${user.uid}';

      debugPrint('SESSION STEP 1: Reading user profile');
      debugPrint('SESSION PATH: $currentPath');

      debugPrint('SESSION: Checking Firebase Auth');

      debugPrint('SESSION: Auth UID = ${_auth.currentUser?.uid}');


      debugPrint('SESSION: Auth token refreshed');

      debugPrint(
        'SESSION: Firebase Project = '
        '${_firestore.app.options.projectId}',
      );

      debugPrint('SESSION: Reading users/${user.uid}');

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.server));

      debugPrint('SESSION: User read successful');

      debugPrint('SESSION STEP 1: Success');

      if (!userDoc.exists) {
        throw Exception('ملف المستخدم غير موجود');
      }

      final data = userDoc.data()!;

      final savedRole = data['role'];
      final orgId = data['organizationId'];

      // ======================================
      // 2. Validate User
      // ======================================

      currentStep = 'STEP 2 - Validate User';

      debugPrint('SESSION STEP 2: Validating user');

      if (data['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      if (savedRole != 'supervisor' && savedRole != 'field_worker') {
        throw Exception('دور المستخدم غير مسموح');
      }

      if (orgId is! String || orgId.trim().isEmpty) {
        throw Exception('المستخدم غير مرتبط بمؤسسة');
      }

      debugPrint('SESSION STEP 2: Success');
      debugPrint('SESSION ROLE: $savedRole');

      // ======================================
      // 3. Load Organization Name
      // ======================================

      currentStep = 'STEP 3 - Organization';
      currentPath = 'organizations/$orgId';

      debugPrint('SESSION STEP 3: Reading organization');
      debugPrint('SESSION PATH: $currentPath');

      final orgDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .get(const GetOptions(source: Source.server));

      debugPrint('SESSION STEP 3: Success');

      if (!orgDoc.exists) {
        throw Exception('مستند المؤسسة غير موجود');
      }

      final orgName = orgDoc.data()?['name'] as String? ?? '';

      // ======================================
      // 4. Resolve Assigned Area
      // ======================================

      currentStep = 'STEP 4 - Resolve Area';

      debugPrint('SESSION STEP 4: Resolving assigned area');

      // Employee data is stored in users/{uid}
      // after invitation acceptance.
      //
      // The invitation document in employees
      // is deleted after acceptance.
      //
      // Therefore, do not read employees here.

      String resolvedAreaId = '';
      String resolvedAreaName = '';

      final savedAreaId = data['areaId'];

      if (savedRole == 'field_worker') {
        if (savedAreaId is! String || savedAreaId.trim().isEmpty) {
          throw Exception('منطقة عمل الموظف غير محددة');
        }

        resolvedAreaId = savedAreaId.trim();
      } else {
        // Supervisor may not have a specific area.
        resolvedAreaId = savedAreaId is String ? savedAreaId.trim() : '';
      }

      debugPrint('SESSION STEP 4: Success');

      // ======================================
      // 5. Load Area Name
      // ======================================

      if (resolvedAreaId.isNotEmpty) {
        currentStep = 'STEP 5 - Area';
        currentPath = 'organizations/$orgId/areas/$resolvedAreaId';

        debugPrint('SESSION STEP 5: Reading area');
        debugPrint('SESSION PATH: $currentPath');

        final areaDoc = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('areas')
            .doc(resolvedAreaId)
            .get(const GetOptions(source: Source.server));

        debugPrint('SESSION STEP 5: Success');

        if (!areaDoc.exists) {
          throw Exception('مستند المنطقة غير موجود');
        }

        resolvedAreaName = areaDoc.data()?['name'] as String? ?? '';
      } else {
        debugPrint('SESSION STEP 5: Skipped - No assigned area');
      }

      // ======================================
      // 6. Verify Current User
      // ======================================

      currentStep = 'STEP 6 - Verify Current User';

      debugPrint('SESSION STEP 6: Verifying current user');

      if (_auth.currentUser?.uid != user.uid) {
        throw Exception('تغير المستخدم أثناء تحميل البيانات');
      }

      debugPrint('SESSION STEP 6: Success');

      // ======================================
      // 7. Save Data in GetX
      // ======================================

      currentStep = 'STEP 7 - Save Session';

      uid.value = user.uid;

      fullName.value = data['fullName'] as String? ?? '';

      email.value = data['email'] as String? ?? user.email ?? '';

      role.value = savedRole as String;

      organizationId.value = orgId;
      organizationName.value = orgName;

      areaId.value = resolvedAreaId;
      areaName.value = resolvedAreaName;

      status.value = data['status'] as String;

      isProfileLoaded.value = true;

      debugPrint('SESSION STEP 7: Success');
      debugPrint('SESSION: User profile loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('====================================');
      debugPrint('SESSION: loadUserData FAILED');
      debugPrint('FAILED STEP: $currentStep');
      debugPrint('FAILED PATH: $currentPath');
      debugPrint('ERROR: $e');

      if (e is FirebaseException) {
        debugPrint('FIREBASE PLUGIN: ${e.plugin}');
        debugPrint('FIREBASE CODE: ${e.code}');
        debugPrint('FIREBASE MESSAGE: ${e.message}');
      }

      debugPrint('====================================');

      debugPrintStack(stackTrace: stackTrace);

      clearUserData();
      rethrow;
    } finally {
      isProfileLoading.value = false;
    }
  }

  // ========================================
  // Start Session After Login
  // ========================================

  // Keep the parameter for compatibility
  // with the existing LoginController.

  Future<void> startSession(String userRole) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    final expectedUid = user.uid;

    debugPrint(
      'SESSION START: Starting for UID $expectedUid',
    );

    // Load the actual role and organization
    // from Firestore, not from userRole.
    await loadUserData();

    final currentUid = _auth.currentUser?.uid;

    if (currentUid != expectedUid) {
      debugPrint(
        'SESSION START: Auth user changed. '
            'Expected=$expectedUid, Current=$currentUid',
      );

      throw StateError(
        'تغير المستخدم أثناء بدء الجلسة',
      );
    }

    if (!isProfileLoaded.value) {
      throw StateError(
        'تعذر تحميل بيانات المستخدم',
      );
    }

    _lastActivity = DateTime.now();

    await _prefs.setString(
      _sessionUserKey,
      expectedUid,
    );

    await _prefs.setInt(
      _lastActivityKey,
      _lastActivity!.millisecondsSinceEpoch,
    );

    _startTimer();

    debugPrint(
      'SESSION START: Session created successfully',
    );
  }


  // ========================================
  // Restore Session
  // ========================================

  Future<bool> restoreSession() async {
    final user = _auth.currentUser;

    if (user == null) {
      clearSession();
      return false;
    }

    try {
      final savedUid = await _prefs.getString(_sessionUserKey);

      final savedTime = await _prefs.getInt(_lastActivityKey);

      if (savedUid != user.uid || savedTime == null) {
        await logout(navigate: false);
        return false;
      }

      _lastActivity = DateTime.fromMillisecondsSinceEpoch(savedTime);

      if (_hasExpired()) {
        await logout(navigate: false);
        return false;
      }

      // Restore all user data.
      await loadUserData();

      _startTimer();
      return true;
    } on FirebaseException {
      // Network or permission errors should be
      // handled by the splash screen.
      clearSession();
      rethrow;
    } catch (_) {
      await logout(navigate: false);
      return false;
    }
  }

  // ========================================
  // Session Expiration
  // ========================================

  bool _hasExpired() {
    if (_lastActivity == null) return true;

    return DateTime.now().difference(_lastActivity!) >= sessionTimeout;
  }

  Future<void> checkSession() async {
    if (_auth.currentUser == null || _isSigningOut) {
      return;
    }

    if (_hasExpired()) {
      await logout();
    }
  }

  // ========================================
  // Record User Activity
  // ========================================

  Future<void> recordActivity() async {
    if (_auth.currentUser == null || role.value.isEmpty || _isSigningOut) {
      return;
    }

    if (_hasExpired()) {
      await logout();
      return;
    }

    final now = DateTime.now();

    // Reduce frequent local writes.
    if (_lastActivity != null &&
        now.difference(_lastActivity!) < const Duration(minutes: 1)) {
      return;
    }

    _lastActivity = now;

    await _prefs.setInt(_lastActivityKey, now.millisecondsSinceEpoch);
  }

  // ========================================
  // Start Session Timer
  // ========================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(minutes: 1), (_) => checkSession());
  }

  // ========================================
  // Logout
  // ========================================

  Future<void> logout({bool navigate = true}) async {
    debugPrint(
      'SESSION LOGOUT CALLED: ${DateTime.now()}',
    );
    debugPrintStack(
      label: 'SESSION LOGOUT STACK TRACE',
    );
    if (_isSigningOut) return;

    _isSigningOut = true;

    try {
      _timer?.cancel();

      await _auth.signOut();

      await _prefs.remove(_lastActivityKey);
      await _prefs.remove(_sessionUserKey);

      clearSession();

      if (navigate) {
        Get.offAll(() => LoginScreen());
      }
    } finally {
      _isSigningOut = false;
    }
  }

  // ========================================
  // Clear User Data
  // ========================================

  void clearUserData() {
    uid.value = '';
    fullName.value = '';
    email.value = '';
    role.value = '';

    organizationId.value = '';
    organizationName.value = '';

    areaId.value = '';
    areaName.value = '';

    status.value = '';

    isProfileLoaded.value = false;
  }

  // ========================================
  // Clear Session
  // ========================================

  void clearSession() {
    _timer?.cancel();
    _lastActivity = null;

    clearUserData();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
