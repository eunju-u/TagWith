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
        child: provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadTransactions(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                    _buildMonthlyTrendSection(context, provider),
                    const SizedBox(height: 40),
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
                                    sectionsSpace: 6,
                                    centerSpaceRadius: 70, // 중심 구멍 크기를 키워 더 얇아 보이게 조절
                                    sections: expenseMap.entries.map((e) {
                                      final cat = provider.allCategories.firstWhere((c) => c.name == e.key);
                                      final rank = sortedExpenses.indexWhere((entry) => entry.key == e.key);
                                      // 두께를 20 내외로 얇게 조절 (순위별로 약간씩 차이를 줌)
                                      final radius = (25 - (rank * 2)).toDouble().clamp(15, 25).toDouble();
                                      
                                      return PieChartSectionData(
                                        color: cat.color,
                                        value: e.value,
                                        title: '',
                                        radius: radius,
                                        badgeWidget: _buildDonutBadge(cat.icon, cat.color),
                                        badgePositionPercentageOffset: 1.15,
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
                      const SizedBox(height: 40),
                      _buildTagSection(context, provider),
                      const SizedBox(height: 40),
                    ],
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context, double total) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    // 지난달 지출과 비교
    final lastMonth = DateTime(DateTime.now().year, DateTime.now().month - 1, 1);
    final lastMonthTotal = provider.getTotalExpenseByMonth(lastMonth);
    final diff = total - lastMonthTotal;
    final isIncrease = diff > 0;
    final diffPercent = lastMonthTotal > 0 ? (diff.abs() / lastMonthTotal * 100).toStringAsFixed(0) : '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 배경 장식용 아이콘
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.auto_graph_rounded,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '이번 달 총 지출',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${DateTime.now().month}월 현황',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat('#,###').format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '원',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 지난달 비교 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: isIncrease ? Colors.redAccent.shade100 : Colors.greenAccent.shade100,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '지난달보다 ${NumberFormat('#,###').format(diff.abs())}원 ($diffPercent%) ${isIncrease ? '늘었어요' : '줄었어요'}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildTagSection(BuildContext context, TransactionProvider provider) {
    final theme = Theme.of(context);
    final tagMap = provider.getTagSpending(forStats: true);
    final sortedTags = tagMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final totalExpense = tagMap.values.fold(0.0, (sum, val) => sum + val);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('태그별 지출', style: theme.textTheme.titleLarge),
        const SizedBox(height: 20),
        if (tagMap.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.label_off_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                const SizedBox(width: 12),
                Text('기록된 태그가 없습니다', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            ),
          )
        else
          ...sortedTags.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.label_rounded, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            '${NumberFormat('#,###').format(e.value)}원',
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: totalExpense > 0 ? e.value / totalExpense : 0,
                          backgroundColor: theme.dividerColor.withValues(alpha: 0.5),
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary.withValues(alpha: 0.6)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildMonthlyTrendSection(BuildContext context, TransactionProvider provider) {
    final theme = Theme.of(context);
    final trendMap = provider.getMonthlyTrend(); // 이미 6개월 전까지만 가져오도록 프로바이더에 구현됨
    final months = trendMap.keys.toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('최근 수입/지출 추이', style: theme.textTheme.titleLarge),
            _buildChartLegend(theme),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          height: 240,
          padding: const EdgeInsets.fromLTRB(16, 32, 24, 16),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
          ),
          child: LineChart(
            LineChartData(
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => theme.colorScheme.surface.withValues(alpha: 0.9),
                  tooltipRoundedRadius: 12,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      final isIncome = spot.barIndex == 0;
                      return LineTooltipItem(
                        '${months[spot.x.toInt()].month}월 ${isIncome ? '수입' : '지출'}\n',
                        theme.textTheme.labelSmall!.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                        children: [
                          TextSpan(
                            text: '${NumberFormat('#,###').format(spot.y * 10000)}원',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isIncome ? Colors.blueAccent : Colors.redAccent,
                            ),
                          ),
                        ],
                      );
                    }).toList();
                  },
                ),
              ),
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= months.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          '${months[value.toInt()].month}월',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                // Income Line (Blue)
                LineChartBarData(
                  spots: List.generate(months.length, (index) {
                    final month = months[index];
                    return FlSpot(index.toDouble(), trendMap[month]!['income']! / 10000);
                  }),
                  isCurved: true,
                  color: Colors.blueAccent,
                  barWidth: 2, // 지시대로 얇게 조정
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), // 동그란 정점 제거
                  belowBarData: BarAreaData(show: false),
                ),
                // Expense Line (Red)
                LineChartBarData(
                  spots: List.generate(months.length, (index) {
                    final month = months[index];
                    return FlSpot(index.toDouble(), trendMap[month]!['expense']! / 10000);
                  }),
                  isCurved: true,
                  color: Colors.redAccent, // 지출은 빨간색으로 변경
                  barWidth: 2, // 지시대로 얇게 조정
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false), // 동그란 정점 제거
                  belowBarData: BarAreaData(show: false),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(ThemeData theme) {
    return Row(
      children: [
        _legendItem('수입', Colors.blueAccent),
        const SizedBox(width: 12),
        _legendItem('지출', Colors.redAccent),
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
