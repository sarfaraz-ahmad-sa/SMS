import 'package:flutter/material.dart';

import '../services/session_state.dart';
import '../theme/app_theme.dart';

class PermissionGate extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    Key? key,
    required this.permission,
    required this.child,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (SessionState.instance.hasPermission(permission)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

class PermissionDeniedView extends StatelessWidget {
  final String message;

  const PermissionDeniedView({
    Key? key,
    this.message = 'You do not have permission to access this module.',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.lock_outline_rounded,
              size: 56,
              color: AppColors.warning,
            ),
            const SizedBox(height: 16),
            const Text(
              'Access restricted',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
