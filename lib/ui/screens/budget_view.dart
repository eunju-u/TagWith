import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    
    // For now, let's use a default budget of 1,000,000 if not set
    const double budgetGoal = 1000000; 
    final currentSpending = provider.getTotalExpenseByMonth(DateTime.now());
    final remaining = budgetGoal - currentSpending;
    final progress = (currentSpending / budgetGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                '이번 달 예산 관리',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              _buildBudgetCard(theme, budgetGoal, currentSpending, progress),
              const SizedBox(height: 40),
              _buildStatusSection(theme, currentSpending, budgetGoal, remaining),
              const SizedBox(height: 40),
              _buildTipCard(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetCard(ThemeData theme, double goal, double current, double progress) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('지출 현황', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        NumberFormat('#,###').format(current),
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Text('원', style: theme.textTheme.titleMedium?.copyWith(color: AppColors.primary.withValues(alpha: 0.5))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Stack(
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.dividerColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                curve: Curves.easeOutCubic,
                height: 12,
                width: MediaQuery.of(context).size.width * 0.65 * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0원', style: theme.textTheme.labelSmall),
              Text('목표 ${NumberFormat('#,###').format(goal)}원', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, double current, double goal, double remaining) {
    final isOver = remaining < 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상세 요약', style: theme.textTheme.titleLarge),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatItem(
              theme, 
              '남은 예산', 
              '${NumberFormat('#,###').format(remaining.abs())}원', 
              isOver ? '초과됨' : '남음',
              isOver ? AppColors.expense : Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              theme, 
              '하루 권장', 
              '${NumberFormat('#,###').format(remaining > 0 ? remaining / 15 : 0)}원', 
              '내외',
              AppColors.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, String title, String value, String sub, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(sub, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '예산을 잘 지키고 계시네요! 조금만 더 힘내세요.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
