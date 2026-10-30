
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../views/login_screen.dart';

class UserSessionController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final SharedPreferencesAsync _prefs =
  SharedPreferencesAsync();

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

  static const Duration sessionTimeout =
  Duration(days: 3);

  static const String _lastActivityKey =
      'last_activity';

  static const String _sessionUserKey =
      'session_user';

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

    try {
      // Read user profile
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!userDoc.exists) {
        throw Exception('ملف المستخدم غير موجود');
      }

      final data = userDoc.data()!;
      final savedRole = data['role'];
      final orgId = data['organizationId'];

      if (data['status'] != 'active') {
        throw Exception('حساب المستخدم غير فعال');
      }

      if (savedRole != 'supervisor' &&
          savedRole != 'field_worker') {
        throw Exception('دور المستخدم غير مسموح');
      }

      if (orgId is! String || orgId.isEmpty) {
        throw Exception('المستخدم غير مرتبط بمؤسسة');
      }

      // ======================================
      // Load Organization Name
      // ======================================

      final orgDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!orgDoc.exists) {
        throw Exception('مستند المؤسسة غير موجود');
      }

      final orgName =
          orgDoc.data()?['name'] as String? ?? '';

      // ======================================
      // Resolve Assigned Area
      // ======================================

      String resolvedAreaId = '';
      String resolvedAreaName = '';

      if (savedRole == 'field_worker') {
        // The actual worker area is stored
        // in the employee invitation record.
        final invitationId = data['invitationId'];

        if (invitationId is! String ||
            invitationId.isEmpty) {
          throw Exception(
            'سجل الموظف غير مرتبط بدعوة',
          );
        }

        final employeeDoc = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('employees')
            .doc(invitationId)
            .get(
          const GetOptions(source: Source.server),
        );

        if (!employeeDoc.exists) {
          throw Exception('سجل الموظف غير موجود');
        }

        final employee = employeeDoc.data()!;

        if (employee['uid'] != user.uid ||
            employee['status'] != 'active' ||
            employee['role'] != 'field_worker' ||
            employee['organizationId'] != orgId) {
          throw Exception(
            'بيانات الموظف غير متطابقة',
          );
        }

        final assignedArea = employee['areaId'];

        if (assignedArea is! String ||
            assignedArea.isEmpty) {
          throw Exception(
            'لم يتم تحديد منطقة الموظف',
          );
        }

        resolvedAreaId = assignedArea;
      } else {
        // Supervisor may not have a specific area.
        resolvedAreaId =
            data['areaId'] as String? ?? '';
      }

      // ======================================
      // Load Area Name
      // ======================================

      if (resolvedAreaId.isNotEmpty) {
        final areaDoc = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('areas')
            .doc(resolvedAreaId)
            .get(
          const GetOptions(source: Source.server),
        );

        if (!areaDoc.exists) {
          throw Exception('مستند المنطقة غير موجود');
        }

        resolvedAreaName =
            areaDoc.data()?['name'] as String? ?? '';
      }

      // Avoid loading a previous user's data.
      if (_auth.currentUser?.uid != user.uid) {
        throw Exception(
          'تغير المستخدم أثناء تحميل البيانات',
        );
      }

      // ======================================
      // Save Data in GetX
      // ======================================

      uid.value = user.uid;

      fullName.value =
          data['fullName'] as String? ?? '';

      email.value =
          data['email'] as String? ??
              user.email ??
              '';

      role.value = savedRole as String;
      organizationId.value = orgId;
      organizationName.value = orgName;

      areaId.value = resolvedAreaId;
      areaName.value = resolvedAreaName;

      status.value = data['status'] as String;

      isProfileLoaded.value = true;
    } catch (_) {
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

    // Always load the actual role from Firestore.
    await loadUserData();

    if (_auth.currentUser?.uid != user.uid) {
      throw Exception(
        'تغير المستخدم أثناء تسجيل الدخول',
      );
    }

    _lastActivity = DateTime.now();

    await _prefs.setString(
      _sessionUserKey,
      user.uid,
    );

    await _prefs.setInt(
      _lastActivityKey,
      _lastActivity!.millisecondsSinceEpoch,
    );

    _startTimer();
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
      final savedUid =
      await _prefs.getString(_sessionUserKey);

      final savedTime =
      await _prefs.getInt(_lastActivityKey);

      if (savedUid != user.uid ||
          savedTime == null) {
        await logout(navigate: false);
        return false;
      }

      _lastActivity =
          DateTime.fromMillisecondsSinceEpoch(
            savedTime,
          );

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

    return DateTime.now()
        .difference(_lastActivity!) >=
        sessionTimeout;
  }

  Future<void> checkSession() async {
    if (_auth.currentUser == null ||
        _isSigningOut) {
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
    if (_auth.currentUser == null ||
        role.value.isEmpty ||
        _isSigningOut) {
      return;
    }

    if (_hasExpired()) {
      await logout();
      return;
    }

    final now = DateTime.now();

    // Reduce frequent local writes.
    if (_lastActivity != null &&
        now.difference(_lastActivity!) <
            const Duration(minutes: 1)) {
      return;
    }

    _lastActivity = now;

    await _prefs.setInt(
      _lastActivityKey,
      now.millisecondsSinceEpoch,
    );
  }

  // ========================================
  // Start Session Timer
  // ========================================

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => checkSession(),
    );
  }

  // ========================================
  // Logout
  // ========================================

  Future<void> logout({
    bool navigate = true,
  }) async {
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
