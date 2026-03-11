import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';
import '../../core/theme.dart';
import '../widgets/filter_bottom_sheet.dart';

class StatisticsView extends StatelessWidget {
  const StatisticsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final expenseMap = provider.getCategorySpending(TransactionType.expense, forStats: true);
    final totalExpense = expenseMap.values.fold(0.0, (sum, val) => sum + val);
    final sortedExpenses = expenseMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
                    onPressed: () => _showFilterBottomSheet(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTotalSummary(context, totalExpense),
              const SizedBox(height: 32),
              Text('카테고리별 지출', style: theme.textTheme.titleLarge),
              const SizedBox(height: 24),
              AspectRatio(
                aspectRatio: 1.5,
                child: expenseMap.isEmpty
                    ? Center(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pie_chart_outline_rounded, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
                          const SizedBox(height: 12),
                          Text('기록된 지출 내역이 없습니다', style: theme.textTheme.bodyMedium),
                        ],
                      ))
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 8,
                              centerSpaceRadius: 40,
                              sections: expenseMap.entries.map((e) {
                                final cat = provider.allCategories.firstWhere((c) => c.name == e.key);
                                final rank = sortedExpenses.indexWhere((entry) => entry.key == e.key);
                                final radius = (48 - (rank * 4)).toDouble().clamp(30, 48).toDouble();
                                
                                return PieChartSectionData(
                                  gradient: LinearGradient(
                                    colors: [
                                      cat.color,
                                      cat.color.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                  value: e.value,
                                  title: '',
                                  radius: radius,
                                  badgeWidget: _buildDonutBadge(cat.icon, cat.color),
                                  badgePositionPercentageOffset: 1.25,
                                );
                              }).toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '지출합계',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                NumberFormat('#,###').format(totalExpense),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: theme.colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
              if (expenseMap.isNotEmpty) ...[
                _buildGridLegend(context, expenseMap, totalExpense, provider),
                const SizedBox(height: 40),
                _buildPaymentMethodSection(context, provider),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context, double total) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 총 지출', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            '${NumberFormat('#,###').format(total)}원',
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLegend(BuildContext context, Map<String, double> data, double total, TransactionProvider provider) {
    final theme = Theme.of(context);
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((e) {
        final cat = provider.allCategories.firstWhere((c) => c.name == e.key);
        final percentage = (e.value / total * 100).toStringAsFixed(1);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(cat.icon, color: cat.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: theme.textTheme.titleMedium),
                        Text(
                          '${NumberFormat('#,###').format(e.value)}원',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Stack(
                      children: [
                        Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: e.value / total,
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [cat.color, cat.color.withValues(alpha: 0.6)],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 45,
                child: Text(
                  '$percentage%',
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDonutBadge(IconData icon, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Center(
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildPaymentMethodSection(BuildContext context, TransactionProvider provider) {
    final theme = Theme.of(context);
    final paymentMap = provider.getPaymentMethodSpending(forStats: true);
    final totalExpense = paymentMap.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('결제 수단별 지출', style: theme.textTheme.titleLarge),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: PaymentMethod.values.map((method) {
            final amount = paymentMap[method] ?? 0.0;
            final percentage = totalExpense > 0 ? (amount / totalExpense * 100).toStringAsFixed(1) : '0.0';
            
            IconData methodIcon;
            String methodLabel;
            switch (method) {
              case PaymentMethod.cash:
                methodIcon = Icons.payments_outlined;
                methodLabel = '현금';
                break;
              case PaymentMethod.checkCard:
                methodIcon = Icons.credit_card_outlined;
                methodLabel = '체크카드';
                break;
              case PaymentMethod.creditCard:
                methodIcon = Icons.account_balance_wallet_outlined;
                methodLabel = '신용카드';
                break;
            }

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(
                  right: method == PaymentMethod.values.last ? 0 : 8,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Icon(methodIcon, size: 24, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(height: 8),
                    Text(methodLabel, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat('#,###').format(amount)}원',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$percentage%',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(forStats: true),
    );
  }
}
