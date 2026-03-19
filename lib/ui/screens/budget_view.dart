import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  void _showEditBudgetDialog(BuildContext context, double currentBudget) {
    final controller = TextEditingController(text: currentBudget.toInt().toString());
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.colorScheme.surface,
        title: Text('한 달 예산 설정', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: '예산을 입력하세요',
            suffixText: '원',
            filled: true,
            fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              final newBudget = double.tryParse(controller.text) ?? 0.0;
              Provider.of<TransactionProvider>(context, listen: false).updateMonthlyBudget(newBudget);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('저장하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    
    final double budgetGoal = provider.monthlyBudget;
    final currentSpending = provider.getTotalExpenseByMonth(DateTime.now());
    final remaining = budgetGoal - currentSpending;
    final progress = budgetGoal > 0 ? (currentSpending / budgetGoal).clamp(0.0, 1.0) : 1.0;
    
    final isOver = remaining < 0;
    final now = DateTime.now();
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final remainingDays = lastDayOfMonth.day - now.day + 1;
    final dailyAdvice = remaining > 0 ? remaining / remainingDays : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '이번 달 예산 관리',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showEditBudgetDialog(context, budgetGoal),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('목표 수정'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _buildBudgetCard(theme, budgetGoal, currentSpending, progress),
              const SizedBox(height: 40),
              _buildStatusSection(theme, currentSpending, budgetGoal, remaining, dailyAdvice, isOver),
              const SizedBox(height: 32),
              _buildTipCard(theme, progress, dailyAdvice, isOver),
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
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            offset: const Offset(0, 12),
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
                  Text('현재까지 지출', style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        NumberFormat('#,###').format(current),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900, 
                          color: progress > 0.8 ? Colors.deepOrange : AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('원', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: (progress > 0.8 ? Colors.deepOrange : AppColors.primary).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: progress > 0.8 ? Colors.deepOrange : AppColors.primary, 
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutExpo,
                    height: 16,
                    width: constraints.maxWidth * progress, // 박스 크기에 정확히 비례하도록 수정
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: progress > 0.8 
                            ? [Colors.orange, Colors.deepOrange]
                            : [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: (progress > 0.8 ? Colors.deepOrange : AppColors.primary).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0원', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.3))),
              Text(
                '목표 ${NumberFormat('#,###').format(goal)}원', 
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(ThemeData theme, double current, double goal, double remaining, double dailyAdvice, bool isOver) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('상세를 살펴볼까요?', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatItem(
              theme, 
              '남은 예산', 
              '${NumberFormat('#,###').format(remaining.abs())}원', 
              isOver ? '예산 초과' : '지출 가능',
              isOver ? Colors.redAccent : Colors.green,
            ),
            const SizedBox(width: 16),
            _buildStatItem(
              theme, 
              '하루 권장', 
              '${NumberFormat('#,###').format(dailyAdvice.toInt())}원', 
              '이하 지출 권장',
              AppColors.primary,
              onInfoTap: () => _showInfoDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: theme.colorScheme.surface,
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('하루 권장 지출액이란?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          '예산이 30만 원 남았고, 이번 달이 10일 남았다면?\n'
          '300,000 ÷ 10 = 30,000원이 하루 권장 지출액으로 표시됩니다.\n\n'
          '내일 돈을 많이 쓰면 남은 예산이 줄어들어, 다음 날의 권장 지출액은 자동으로 낮아지게 됩니다!',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String title, String value, String sub, Color color, {VoidCallback? onInfoTap}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                if (onInfoTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: GestureDetector(
                      onTap: onInfoTap,
                      child: Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value, 
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(sub, style: theme.textTheme.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme, double progress, double dailyAdvice, bool isOver) {
    String tip;
    Color tipColor = AppColors.primary;
    IconData tipIcon = Icons.lightbulb_outline_rounded;

    if (progress >= 1.0) {
      tip = '이번 달 예산을 모두 소진하셨네요! 이제부터는 필수적인 지출만 고려해서 남은 기간을 잘 마무리해 봅시다. 💪';
      tipColor = Colors.redAccent;
      tipIcon = Icons.check_circle_outline_rounded;
    } else if (isOver) {
      tip = '예산을 초과했습니다! 이번 달 남은 기간은 최대한 지출을 자제하는 긴축 재정이 필요해요. 🚨';
      tipColor = Colors.redAccent;
      tipIcon = Icons.warning_amber_rounded;
    } else if (dailyAdvice < 5000) {
      tip = '하루 5천 원도 안 남았어요! 비상 상황입니다. 당분간은 지갑을 닫고 생존 모드로 들어가야 할 것 같아요! 😱';
      tipColor = Colors.orange;
      tipIcon = Icons.error_outline_rounded;
    } else if (dailyAdvice < 15000) {
      tip = '하루 권장액이 1.5만 원 미만입니다. 당분간은 비싼 커피나 외식 대신 도시락이나 집밥을 애용해 보는 건 어떨까요? 🍱';
      tipColor = Colors.orangeAccent;
      tipIcon = Icons.restaurant_rounded;
    } else if (progress > 0.8) {
      tip = '예산의 80%를 이미 사용하셨네요. 남은 날짜가 많다면 조금 더 계획적인 소비가 필요해 보여요! 📉';
      tipColor = Colors.amber;
      tipIcon = Icons.info_outline_rounded;
    } else {
      tip = '지출 속도가 아주 훌륭합니다! 지금처럼만 계획적으로 소비하신다면 이번 달 예산을 멋지게 지켜낼 수 있어요. ✨';
      tipColor = AppColors.primary;
      tipIcon = Icons.thumb_up_alt_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tipColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: tipColor.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(tipIcon, color: tipColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              tip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tipColor.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
