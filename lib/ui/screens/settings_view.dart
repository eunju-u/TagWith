import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/app_dialog.dart';

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text(AppStrings.logout, style: TextStyle(color: Colors.redAccent)),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: Colors.grey),
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
                    icon: Icons.brightness_auto,
                    mode: ThemeMode.system,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                  const Divider(height: 1),
                  _buildThemeTile(
                    context,
                    title: AppStrings.lightTheme,
                    icon: Icons.light_mode,
                    mode: ThemeMode.light,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                  const Divider(height: 1),
                  _buildThemeTile(
                    context,
                    title: AppStrings.darkTheme,
                    icon: Icons.dark_mode,
                    mode: ThemeMode.dark,
                    currentMode: themeProvider.themeMode,
                    onChanged: (mode) => themeProvider.setThemeMode(mode!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader(context, AppStrings.infoSection),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                title: const Text(AppStrings.versionInfo),
                trailing: Text('1.0.0', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
              ),
            ),
          ],
        ),
      );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: AppStrings.logout,
      content: AppStrings.confirmLogout,
      icon: Icons.logout_rounded,
      confirmColor: Colors.redAccent,
      confirmText: AppStrings.logout,
      onConfirm: () async {
        await authProvider.signOut();
        if (context.mounted) {
          Provider.of<TransactionProvider>(context, listen: false).clearData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.logoutSuccess)),
          );
        }
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: AppStrings.withdraw,
      content: AppStrings.confirmWithdraw,
      icon: Icons.person_remove_rounded,
      confirmColor: Colors.redAccent,
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.withdrawSubmit,
      onConfirm: () async {
        final success = await authProvider.withdraw();
        if (success && context.mounted) {
          Provider.of<TransactionProvider>(context, listen: false).clearData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.withdrawSuccess)),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.withdrawError)),
          );
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
