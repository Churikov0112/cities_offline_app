import 'package:flutter/widgets.dart';

class LifecycleEventHandler with WidgetsBindingObserver {
  final VoidCallback? resumeCallback;
  final VoidCallback? pauseCallback;

  const LifecycleEventHandler({
    this.resumeCallback,
    this.pauseCallback,
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      resumeCallback?.call();
    }
    if (state == AppLifecycleState.paused ) {
      pauseCallback?.call();
    }
  }
}
