import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class ChristianGolfersApp extends StatelessWidget {
  const ChristianGolfersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Christian Golfers Cape Town',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      darkTheme: AppTheme.theme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();

        Widget app = child;

        if (AppConfig.demoMode) {
          app = Banner(
            message: 'DEMO',
            location: BannerLocation.topEnd,
            color: AppTheme.primaryBlue,
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
            child: app,
          );
        }

        return _PhoneShell(child: app);
      },
    );
  }
}

class _PhoneShell extends StatelessWidget {
  const _PhoneShell({required this.child});

  final Widget child;

  static const maxWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width <= maxWidth) return child;

    return ColoredBox(
      color: const Color(0xFF0F172A),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: AppTheme.pageBg,
              boxShadow: [
                BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 30,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: Size(
                  maxWidth,
                  MediaQuery.sizeOf(context).height,
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
