import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import '../../core/theme.dart';
import 'calendar_view.dart';
import 'statistics_view.dart';
import 'ocr_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;

  final List<Widget> _views = [
    const CalendarView(),
    const StatisticsView(),
    const OCRView(), // Directly accessible via FAB or index if needed
    const SettingsView(),
  ];

  // Icons for the animated bottom bar (excluding center FAB)
  final iconList = <IconData>[
    Icons.calendar_today_rounded,
    Icons.analytics_rounded,
    Icons.receipt_long_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _bottomNavIndex,
        children: _views,
      ),
      floatingActionButton: Container(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _bottomNavIndex = 2); // Switch to OCRView
          },
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: iconList,
        activeIndex: _bottomNavIndex,
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.softEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        backgroundColor: theme.colorScheme.surface,
        activeColor: AppColors.primary,
        inactiveColor: theme.colorScheme.onSurface.withValues(alpha: 0.4),
        onTap: (index) => setState(() => _bottomNavIndex = index),
        // Adding shadow and elevation for premium look
        elevation: 20,
      ),
    );
  }
}
