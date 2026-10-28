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

  final RxString role = ''.obs;

  static const Duration sessionTimeout = Duration(days: 3);

  static const String _lastActivityKey = 'last_activity';
  static const String _sessionUserKey = 'session_user';

  Timer? _timer;
  DateTime? _lastActivity;
  bool _isSigningOut = false;

  bool get isSupervisor => role.value == 'supervisor';
  bool get isFieldWorker => role.value == 'field_worker';

  // حفظ الجلسة بعد تسجيل الدخول بنجاح
  Future<void> startSession(String userRole) async {
    final user = _auth.currentUser;
    if (user == null) return;

    role.value = userRole;
    _lastActivity = DateTime.now();

    await _prefs.setString(_sessionUserKey, user.uid);
    await _prefs.setInt(
      _lastActivityKey,
      _lastActivity!.millisecondsSinceEpoch,
    );

    _startTimer();
  }

  // استعادة الجلسة عند فتح التطبيق
  Future<bool> restoreSession() async {
    final user = _auth.currentUser;

    if (user == null) {
      clearSession();
      return false;
    }

    final savedUid = await _prefs.getString(_sessionUserKey);
    final savedTime = await _prefs.getInt(_lastActivityKey);

    if (savedUid != user.uid || savedTime == null) {
      await logout(navigate: false);
      return false;
    }

    _lastActivity = DateTime.fromMillisecondsSinceEpoch(
      savedTime,
    );

    if (_hasExpired()) {
      await logout(navigate: false);
      return false;
    }

    // إعادة قراءة الدور وحالة الحساب
    final userDoc = await _firestore
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      await logout(navigate: false);
      return false;
    }

    final data = userDoc.data()!;
    final savedRole = data['role'];

    if (data['status'] != 'active' ||
        (savedRole != 'supervisor' &&
            savedRole != 'field_worker')) {
      await logout(navigate: false);
      return false;
    }

    role.value = savedRole as String;
    _startTimer();

    return true;
  }

  // التحقق من انتهاء المهلة
  bool _hasExpired() {
    if (_lastActivity == null) return true;

    return DateTime.now().difference(_lastActivity!) >=
        sessionTimeout;
  }

  Future<void> checkSession() async {
    if (_auth.currentUser == null || _isSigningOut) return;

    if (_hasExpired()) {
      await logout();
    }
  }

  // تسجيل النشاط الفعلي للمستخدم
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

    // تخفيف عدد عمليات الحفظ
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

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => checkSession(),
    );
  }

  Future<void> logout({bool navigate = true}) async {
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

  void clearSession() {
    _timer?.cancel();
    _lastActivity = null;
    role.value = '';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
