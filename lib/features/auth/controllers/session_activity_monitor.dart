
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/user_session_controller.dart';

class SessionActivityMonitor extends StatefulWidget {
  final Widget child;

  const SessionActivityMonitor({
    super.key,
    required this.child,
  });

  @override
  State<SessionActivityMonitor> createState() =>
      _SessionActivityMonitorState();
}

class _SessionActivityMonitorState
    extends State<SessionActivityMonitor>
    with WidgetsBindingObserver {

  final UserSessionController session =
  Get.find<UserSessionController>();

  bool _checkingSession = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state == AppLifecycleState.resumed) {
      _checkSessionOnResume();
    }
  }

  Future<void> _checkSessionOnResume() async {
    if (_checkingSession) return;

    _checkingSession = true;

    try {
      await session.checkSession();
    } finally {
      _checkingSession = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!_checkingSession) {
          session.recordActivity();
        }
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
