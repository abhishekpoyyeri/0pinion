import 'dart:ui';
import 'package:flutter/material.dart';

class CustomNavigationDock extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTap;

  const CustomNavigationDock({
    super.key,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Dock configuration values
    const double dockHeight = 60.0;
    final BorderRadius dockBorderRadius = BorderRadius.circular(30.0);
    const Color dockBgColor = Color(0xE61E1E1E); // #1E1E1E with transparency (90%)

    return SafeArea(
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20.0,
          right: 20.0,
          bottom: 12.0,
          top: 4.0,
        ),
        child: Container(
          height: dockHeight,
          decoration: BoxDecoration(
            borderRadius: dockBorderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: dockBorderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: dockBgColor,
                  borderRadius: dockBorderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1.0,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      icon: Icons.home,
                    ),
                    _buildNavItem(
                      index: 1,
                      icon: Icons.search,
                    ),
                    _buildNavItem(
                      index: 2,
                      icon: Icons.add_circle_outline,
                    ),
                    _buildNavItem(
                      index: 3,
                      icon: Icons.groups_outlined,
                    ),
                    _buildNavItem(
                      index: 4,
                      icon: Icons.person_outline,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
  }) {
    final bool isSelected = selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFFA0A0A0), // Match AppColors.darkSecondaryText
              size: 24.0,
            ),
          ),
        ),
      ),
    );
  }
}
