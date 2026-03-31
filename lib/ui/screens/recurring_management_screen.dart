import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/app_icons.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import 'recurring_add_screen.dart';

class RecurringManagementScreen extends StatelessWidget {
  const RecurringManagementScreen({super.key});

  String _getIntervalText(RecurringTransaction item) {
    if (item.interval == 'monthly') {
      return '${AppStrings.recurringMonthly} (${item.dayOfMonth}일)';
    } else if (item.interval == 'weekly') {
      final days = [
        AppStrings.recurringDaySun,
        AppStrings.recurringDayMon,
        AppStrings.recurringDayTue,
        AppStrings.recurringDayWed,
        AppStrings.recurringDayThu,
        AppStrings.recurringDayFri,
        AppStrings.recurringDaySat
      ];
      return '${AppStrings.recurringWeekly} (${days[item.dayOfWeek ?? 0]})';
    }
    return '매일';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final items = provider.recurringTransactions;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.recurringManagementTitle),
        leading: IconButton(
          icon: const Icon(AppIcons.chevronLeft),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.repeat, size: 64, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 고정 지출이 없습니다.',
                    style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildRecurringItem(context, item, provider);
              },
            ),
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RecurringAddScreen()),
          ),
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _buildRecurringItem(BuildContext context, RecurringTransaction item, TransactionProvider provider) {
    final theme = Theme.of(context);
    final currencyFormat = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.category.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: item.category.iconData != null
                ? Icon(item.category.iconData, color: item.category.color, size: 24)
                : Text(item.category.icon, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _getIntervalText(item),
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${currencyFormat.format(item.amount)}원 · ${item.category.name}',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                if (item.nextFireDate != null)
                  Text(
                    '다음 예정일: ${DateFormat('yyyy-MM-dd').format(item.nextFireDate!)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.primary.withOpacity(0.7), fontSize: 10),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch.adaptive(
                value: item.isActive,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  provider.updateRecurringTransaction(item.id, {'is_active': val});
                },
              ),
              IconButton(
                icon: const Icon(AppIcons.delete, color: Colors.grey, size: 20),
                onPressed: () async {
                  final confirm = await AppDialog.show(
                    context: context,
                    title: '고정 지출 삭제',
                    content: '해당 반복 설정을 삭제하시겠습니까?\n더 이상 내역이 자동으로 생성되지 않습니다.',
                    confirmText: AppStrings.delete,
                    confirmColor: Colors.redAccent,
                    onConfirm: () {},
                  );
                  
                  if (confirm == true) {
                    await provider.deleteRecurringTransaction(item.id);
                    if (context.mounted) {
                      AppSnackBar.show(context, AppStrings.deleteSuccess);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
