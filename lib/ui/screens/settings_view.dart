import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../core/theme.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('설정', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, '화면 설정'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                _buildThemeTile(
                  context,
                  title: '시스템 설정',
                  icon: Icons.brightness_auto,
                  mode: ThemeMode.system,
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                const Divider(height: 1),
                _buildThemeTile(
                  context,
                  title: '라이트 모드',
                  icon: Icons.light_mode,
                  mode: ThemeMode.light,
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
                const Divider(height: 1),
                _buildThemeTile(
                  context,
                  title: '다크 모드',
                  icon: Icons.dark_mode,
                  mode: ThemeMode.dark,
                  currentMode: themeProvider.themeMode,
                  onChanged: (mode) => themeProvider.setThemeMode(mode!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _buildSectionHeader(context, '정보'),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              title: const Text('버전 정보'),
              trailing: Text('1.0.0', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThemeTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode?> onChanged,
  }) {
    return RadioListTile<ThemeMode>(
      value: mode,
      groupValue: currentMode,
      onChanged: onChanged,
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      activeColor: AppColors.primary,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }
}
