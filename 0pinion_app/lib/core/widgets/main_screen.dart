import 'package:flutter/material.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/search/screens/search_screen.dart';
import '../../features/opinion/screens/create_opinion_screen.dart';
import '../../features/community/screens/communities_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import 'custom_navigation_dock.dart';
import 'keep_alive_wrapper.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, dynamic result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          _onTabTapped(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: const [
            KeepAliveWrapper(child: HomeScreen()),
            KeepAliveWrapper(child: SearchScreen()),
            KeepAliveWrapper(child: CreateOpinionScreen()),
            KeepAliveWrapper(child: CommunitiesScreen()),
            KeepAliveWrapper(child: ProfileScreen()),
          ],
        ),
        bottomNavigationBar: CustomNavigationDock(
          selectedIndex: _currentIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }
}
