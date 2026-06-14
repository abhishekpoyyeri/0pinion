import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_navigation_dock.dart';

/// Bottom navigation shell â€” 5 tabs: Home, Search, Create, Communities, Profile
class BottomNavShell extends StatelessWidget {
  final Widget child;

  const BottomNavShell({super.key, required this.child});

  static int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/create')) return 2;
    if (location.startsWith('/communities')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/search');
        break;
      case 2:
        context.go('/create');
        break;
      case 3:
        context.go('/communities');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: CustomNavigationDock(
        selectedIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }
}
