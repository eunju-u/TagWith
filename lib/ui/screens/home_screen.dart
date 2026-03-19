import 'package:flutter/material.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import 'calendar_view.dart';
import 'statistics_view.dart';
import 'budget_view.dart'; // Added BudgetView
import 'ocr_view.dart';
import 'settings_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 서버에서 가계부 내역을 불러옵니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadTransactions();
    });
  }

  final List<Widget> _views = [
    const CalendarView(),
    const StatisticsView(),
    const BudgetView(),
    const SettingsView(),
    const OCRView(), // Added back to the stack for FAB access
  ];

  // Icons for the animated bottom bar (excluding center FAB)
  final iconList = <IconData>[
    Icons.calendar_today_rounded,
    Icons.analytics_rounded,
    Icons.track_changes_rounded,
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
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () {
            setState(() => _bottomNavIndex = 4); // Switch to OCRView (index 4)
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
