import 'package:flutter/material.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// 0pinion App — Debate, Not Doomscroll.
class OpinionApp extends StatelessWidget {
  const OpinionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '0pinion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
