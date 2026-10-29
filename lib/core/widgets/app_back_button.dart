import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Consistent in-app back navigation, with Home as a safe fallback for routes
/// opened from an invite or notification without a local history entry.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Back',
    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
    onPressed: () {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/home');
      }
    },
  );
}
