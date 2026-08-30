import 'package:flutter/widgets.dart';

import 'app_lock_controller.dart';
import 'biometric_service.dart';

/// Exposes the app-lock services to any widget in the tree, so destructive
/// actions (permanent deletes) can prompt for authentication without threading
/// [AppLockController]/[BiometricService] through every constructor.
class AuthScope extends InheritedWidget {
  const AuthScope({
    super.key,
    required this.lockController,
    required this.biometricService,
    required super.child,
  });

  final AppLockController lockController;
  final BiometricService biometricService;

  /// Looks the services up from the nearest [AuthScope]. Returns null when the
  /// app was built without one (e.g. some widget tests).
  static AuthScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>();
  }

  static AuthScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No AuthScope found above this context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AuthScope oldWidget) =>
      lockController != oldWidget.lockController ||
      biometricService != oldWidget.biometricService;
}
