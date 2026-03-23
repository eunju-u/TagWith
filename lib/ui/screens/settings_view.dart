import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';
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
        title: Text('설정', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, '계정'),
          const SizedBox(height: 10),
          Card(
            child: Column(
              children: [
                if (user != null) ...[
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(user['name'] ?? '사용자'),
                    subtitle: Text(user['email'] ?? ''),
                  ),
                  const Divider(height: 1),
                ],
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.redAccent),
                    title: const Text('로그아웃', style: TextStyle(color: Colors.redAccent)),
                    onTap: () => _showLogoutDialog(context, authProvider),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.person_remove_outlined, color: Colors.grey),
                    title: const Text('회원 탈퇴', style: TextStyle(color: Colors.grey)),
                    onTap: () => _showWithdrawDialog(context, authProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
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

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: '로그아웃',
      content: '정말 로그아웃 하시겠습니까?',
      icon: Icons.logout_rounded,
      confirmColor: Colors.redAccent,
      confirmText: '로그아웃',
      onConfirm: () async {
        await authProvider.signOut();
        if (context.mounted) {
          Provider.of<TransactionProvider>(context, listen: false).clearData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('로그아웃 되었습니다.')),
          );
        }
      },
    );
  }

  void _showWithdrawDialog(BuildContext context, AuthProvider authProvider) {
    AppDialog.show(
      context: context,
      title: '회원 탈퇴',
      content: '정말 탈퇴하시겠습니까?\n탈퇴 시 모든 정보가 영구적으로 삭제되며 복구할 수 없습니다.',
      icon: Icons.person_remove_rounded,
      confirmColor: Colors.redAccent,
      cancelText: '취소',
      confirmText: '탈퇴하기',
      onConfirm: () async {
        final success = await authProvider.withdraw();
        if (success && context.mounted) {
          Provider.of<TransactionProvider>(context, listen: false).clearData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('탈퇴 처리가 완료되었습니다.')),
          );
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('회원 탈퇴 처리 중 오류가 발생했습니다.')),
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
