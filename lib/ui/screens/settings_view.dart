import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/loading_overlay.dart';
import '../../core/app_icons.dart';

import 'category_management_screen.dart';
import 'recurring_management_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(AppStrings.settingsTitle, style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            _buildSectionHeader(context, AppStrings.accountSection),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  if (user != null) ...[
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(user['name'] ?? AppStrings.defaultUser),
                      subtitle: Text(user['email'] ?? ''),
                    ),
                    const Divider(height: 1),
                  ],
                  ListTile(
                    leading: const Icon(AppIcons.logout, color: AppColors.primary),
                    title: const Text(AppStrings.logout),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.withdraw, color: Colors.grey),
                    title: const Text(AppStrings.withdraw, style: TextStyle(color: Colors.grey)),
                    onTap: () => _showWithdrawDialog(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, AppStrings.displaySection),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _buildThemeTile(
                    context,
                    title: AppStrings.systemTheme,
                    icon: AppIcons.themeAuto,
                    mode: ThemeMode.system,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                  const Divider(height: 1),
                  _buildThemeTile(
                    context,
                    title: AppStrings.lightTheme,
                    icon: AppIcons.themeLight,
                    mode: ThemeMode.light,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                  const Divider(height: 1),
                  _buildThemeTile(
                    context,
                    title: AppStrings.darkTheme,
                    icon: AppIcons.themeDark,
                    mode: ThemeMode.dark,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, '데이터 관리'),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                   ListTile(
                    leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                    title: const Text('카테고리 관리'),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const CategoryManagementScreen())
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.repeat, color: AppColors.primary),
                    title: const Text(AppStrings.recurringLabel),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => const RecurringManagementScreen())
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, AppStrings.infoSection),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(AppIcons.info, size: 20),
                    title: const Text(AppStrings.privacyPolicyLabel),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () async {
                      final url = Uri.parse(AppStrings.privacyPolicyUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                      }
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: const Text(AppStrings.versionInfo),
                    trailing: Text('1.0.0', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: AppStrings.logout,
      content: AppStrings.confirmLogout,
      icon: AppIcons.logout,
      confirmColor: Colors.redAccent,
      confirmText: AppStrings.logout,
      onConfirm: () async {
        try {
          AppLoadingOverlay.show(context);
          await authProvider.signOut();
          if (context.mounted) {
            Provider.of<TransactionProvider>(context, listen: false).clearData();
            AppSnackBar.show(context, AppStrings.logoutSuccess);
          }
        } finally {
          AppLoadingOverlay.hide();
        }
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: AppStrings.withdraw,
      content: AppStrings.confirmWithdraw,
      icon: AppIcons.withdraw,
      confirmColor: Colors.redAccent,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.withdrawSubmit,
      onConfirm: () async {
        try {
          AppLoadingOverlay.show(context);
          final success = await authProvider.withdraw();
          if (success && context.mounted) {
            Provider.of<TransactionProvider>(context, listen: false).clearData();
            AppSnackBar.show(context, AppStrings.withdrawSuccess);
          } else if (context.mounted) {
            AppSnackBar.show(context, AppStrings.withdrawError);
          }
        } finally {
          AppLoadingOverlay.hide();
        }
      },
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
