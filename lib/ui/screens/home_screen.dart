import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import 'calendar_view.dart';
import 'statistics_view.dart';
import 'budget_view.dart'; // Added BudgetView
import 'ocr_loading_screen.dart';
import 'settings_view.dart';
import 'pdf_editor_screen.dart';
import 'manual_entry_screen.dart';

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
          onPressed: () => _showEntryMenu(context),
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

  void _showEntryMenu(BuildContext outerContext) { // 홈 화면의 외부 컨텍스트를 outerContext로 명명
    final theme = Theme.of(outerContext);
    showModalBottomSheet(
      context: outerContext,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      backgroundColor: theme.colorScheme.surface,
      builder: (innerContext) => SafeArea( // 바텀 시트의 내부 컨텍스트를 innerContext로 명명
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(AppStrings.entryMenuTitle, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMenuOption(
                    innerContext,
                    icon: Icons.receipt_long_rounded,
                    label: AppStrings.ocrMenuLabel,
                    color: Colors.orange,
                    onTap: () async {
                      // 바텀 시트부터 닫음
                      Navigator.pop(innerContext);
                      
                      // 사진 선택
                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                      
                      // 분석 화면 이동 (외부 컨텍스트 사용)
                      if (image != null && outerContext.mounted) {
                        Navigator.push(
                          outerContext, 
                          MaterialPageRoute(builder: (context) => OCRLoadingScreen(imagePath: image.path))
                        );
                      }
                    },
                  ),
                  _buildMenuOption(
                    innerContext,
                    icon: Icons.edit_note_rounded,
                    label: AppStrings.manualEntryLabel,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(innerContext);
                      if (outerContext.mounted) {
                        Navigator.push(outerContext, MaterialPageRoute(builder: (context) => const ManualEntryScreen()));
                      }
                    },
                  ),
                  _buildMenuOption(
                    innerContext,
                    icon: Icons.picture_as_pdf_rounded,
                    label: AppStrings.pdfExportLabel,
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.pop(innerContext);
                      if (outerContext.mounted) {
                        Navigator.push(outerContext, MaterialPageRoute(builder: (context) => const PDFEditorScreen()));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuOption(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
