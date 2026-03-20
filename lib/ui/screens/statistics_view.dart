import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';
import '../../core/theme.dart';
import '../widgets/filter_bottom_sheet.dart';

enum StatisticsMode { monthly, yearly }

class StatisticsView extends StatefulWidget {
  const StatisticsView({super.key});

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  StatisticsMode _selectedMode = StatisticsMode.monthly;
  DateTime _selectedMonthDate = DateTime.now();
  DateTime _selectedYearDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // 초기 로딩 시 현재 월 통계 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    if (_selectedMode == StatisticsMode.monthly) {
      provider.loadStatistics(year: _selectedMonthDate.year, month: _selectedMonthDate.month);
    } else {
      provider.loadStatistics(year: _selectedYearDate.year, month: null);
    }
  }

  void _changePeriod(int delta) {
    setState(() {
      if (_selectedMode == StatisticsMode.monthly) {
        _selectedMonthDate = DateTime(_selectedMonthDate.year, _selectedMonthDate.month + delta, 1);
      } else {
        _selectedYearDate = DateTime(_selectedYearDate.year + delta, 1, 1);
      }
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final stats = provider.statistics;
    
    final int? filterYear = _selectedMode == StatisticsMode.monthly ? _selectedMonthDate.year : _selectedYearDate.year;
    final int? filterMonth = _selectedMode == StatisticsMode.monthly ? _selectedMonthDate.month : null;

    // 서버 통계가 있으면 사용, 없으면 기존처럼 클라이언트 연산
    final double totalExpense = stats?.totalExpense ?? 
        provider.getCategorySpending(TransactionType.expense, forStats: true, year: filterYear, month: filterMonth).values.fold(0.0, (s, v) => s + v);
    
    final Map<String, double> categoryMap = stats != null 
        ? { for (var e in stats.categorySpending) e.name : e.amount }
        : provider.getCategorySpending(TransactionType.expense, forStats: true, year: filterYear, month: filterMonth);

    final sortedCategories = categoryMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: () async => _loadData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopControls(theme),
                const SizedBox(height: 24),
                _buildTotalSummary(context, totalExpense),
                const SizedBox(height: 24),
                if (_selectedMode == StatisticsMode.monthly) ...[
                  _buildSmartInsights(theme, stats ?? Statistics(
                    totalIncome: 0, 
                    totalExpense: 0, 
                    lastMonthExpense: 0, 
                    dailyAverageExpense: 0, 
                    mostSpentWeekday: '데이터 없음', 
                    categorySpending: [], 
                    tagSpending: [], 
                    monthlyTrend: []
                  )),
                  const SizedBox(height: 32),
                ],
                _buildMonthlyTrendSection(context, provider),
                const SizedBox(height: 40),
                Text('카테고리별 지출', style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                AspectRatio(
                  aspectRatio: 1.5,
                  child: categoryMap.isEmpty
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
                          centerSpaceRadius: 70,
                          sections: categoryMap.entries.map((e) {
                            final cat = provider.allCategories.firstWhere((c) => c.name == e.key, orElse: () => Category.fromName(e.key));
                            final rank = sortedCategories.indexWhere((entry) => entry.key == e.key);
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
                _buildGridLegend(context, categoryMap, totalExpense, provider),
                const SizedBox(height: 40),
                _buildPaymentMethodSection(context, provider, filterYear, filterMonth),
                const SizedBox(height: 40),
                _buildTagSection(context, provider, filterYear, filterMonth),
                const SizedBox(height: 40),
              ]
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls(ThemeData theme) {
    return Column(
      children: [
        // 월간/연간 토글 스위치 (슬라이딩 방식)
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              // 부드럽게 움직이는 선택 지시자
              AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutExpo,
                alignment: _selectedMode == StatisticsMode.monthly
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // 실제 텍스트 버튼들
              Row(
                children: [
                  _buildToggleButton('월간', StatisticsMode.monthly),
                  _buildToggleButton('연간', StatisticsMode.yearly),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // 기간 선택 화살표
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSmallIconButton(Icons.chevron_left_rounded, () => _changePeriod(-1)),
            const SizedBox(width: 24),
            Text(
              _selectedMode == StatisticsMode.monthly
                  ? DateFormat('yyyy년 M월').format(_selectedMonthDate)
                  : DateFormat('yyyy년').format(_selectedYearDate),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 24),
            _buildSmallIconButton(Icons.chevron_right_rounded, () => _changePeriod(1)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallIconButton(IconData icon, VoidCallback onPressed) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _buildToggleButton(String label, StatisticsMode mode) {
    final isSelected = _selectedMode == mode;
    final theme = Theme.of(context);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_selectedMode != mode) {
            setState(() => _selectedMode = mode);
            _loadData();
          }
        },
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.4),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSummary(BuildContext context, double total) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final stats = provider.statistics;
    
    final now = DateTime.now();
    final isFuture = _selectedMode == StatisticsMode.monthly && 
        (_selectedMonthDate.year > now.year || (_selectedMonthDate.year == now.year && _selectedMonthDate.month > now.month));

    final lastMonthTotal = isFuture ? 0.0 : (stats?.lastMonthExpense ?? 0.0);
    final currentTotal = isFuture ? 0.0 : total;
    final diff = isFuture ? 0.0 : (currentTotal - lastMonthTotal);
    final isIncrease = diff > 0;
    final diffPercent = (!isFuture && lastMonthTotal > 0) ? (diff.abs() / lastMonthTotal * 100).toStringAsFixed(0) : '0';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
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
                    _selectedMode == StatisticsMode.monthly ? '이번 달 총 지출' : '올해 총 지출',
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
                      _selectedMode == StatisticsMode.monthly
                          ? '${_selectedMonthDate.month}월 현황'
                          : '${_selectedYearDate.year}년 현황',
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
                    NumberFormat('#,###').format(currentTotal),
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
              if (_selectedMode == StatisticsMode.monthly)
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
                        isFuture 
                            ? '미래 지출은 아직 0원이에요 📅'
                            : '지난달보다 ${NumberFormat('#,###').format(diff.abs())}원 ($diffPercent%) ${isIncrease ? '늘었어요' : '줄었어요'}',
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

  Widget _buildMonthlyTrendSection(BuildContext context, TransactionProvider provider) {
    final theme = Theme.of(context);
    final stats = provider.statistics;

    final Map<DateTime, Map<String, double>> trendData = stats != null
        ? { 
            for (var e in stats.monthlyTrend) 
              // 날짜가 '2025-10' 처럼 연-월만 오는 경우를 대비해 '-01'을 붙여 안전하게 파싱합니다. 🗓️
              DateTime.parse(e.date.length == 7 ? '${e.date}-01' : e.date).toLocal(): 
              { 'income': e.income, 'expense': e.expense }
          }
        : (_selectedMode == StatisticsMode.monthly
            ? provider.getMonthlyTrend(rootDate: _selectedMonthDate, months: 6)
            : provider.getMonthlyTrend(rootDate: DateTime(_selectedYearDate.year, 12, 1), months: 12));

    final months = trendData.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_selectedMode == StatisticsMode.monthly ? '최근 수입/지출 추이' : '월별 수입/지출 추이', style: theme.textTheme.titleLarge),
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
              minY: 0, // Y축 최소값을 0으로 고정하여 음수 영역 방지
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
                    interval: 1, // 모든 월 표시
                    getTitlesWidget: (value, meta) {
                      if (value < 0 || value >= months.length) return const SizedBox();
                      final month = months[value.toInt()].month;
                      // 월간일 때는 '1월', 연간일 때는 공간 확보를 위해 숫자만 표시
                      final text = _selectedMode == StatisticsMode.monthly ? '$month월' : '$month';
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          text,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            fontWeight: FontWeight.bold,
                            fontSize: _selectedMode == StatisticsMode.monthly ? 10 : 8.5, // 폰트 크기 조정
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
                LineChartBarData(
                  spots: List.generate(months.length, (index) {
                    final month = months[index];
                    return FlSpot(index.toDouble(), trendData[month]!['income']! / 10000);
                  }),
                  isCurved: true,
                  preventCurveOverShooting: true, // 보간법으로 인해 곡선이 위아래로 튀는 현상 방지
                  color: Colors.blueAccent,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: List.generate(months.length, (index) {
                    final month = months[index];
                    return FlSpot(index.toDouble(), trendData[month]!['expense']! / 10000);
                  }),
                  isCurved: true,
                  preventCurveOverShooting: true, // 보간법으로 인해 곡선이 위아래로 튀는 현상 방지
                  color: Colors.redAccent,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
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

  Widget _buildGridLegend(BuildContext context, Map<String, double> data, double total, TransactionProvider provider) {
    final theme = Theme.of(context);
    final sortedEntries = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.map((e) {
        final cat = provider.allCategories.firstWhere((c) => c.name == e.key);
        final percentage = (e.value / total * 100).toStringAsFixed(0);

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

  Widget _buildPaymentMethodSection(BuildContext context, TransactionProvider provider, int? year, int? month) {
    final theme = Theme.of(context);
    final paymentMap = provider.getPaymentMethodSpending(forStats: true, year: year, month: month);
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


  Widget _buildPaymentMethodItem(String name, double amount, double total, Color color, IconData icon) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? amount / total : 0.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    NumberFormat('#,###').format(amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: theme.dividerColor.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTagSection(BuildContext context, TransactionProvider provider, int? year, int? month) {
    final theme = Theme.of(context);
    final stats = provider.statistics;

    final Map<String, double> tagMap = stats != null
        ? { for (var e in stats.tagSpending) e.name: e.amount}
        : provider.getTagSpending(forStats: true, year: year, month: month);

    final sortedTags = tagMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
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
          ...sortedTags.map((e) =>
              Container(
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

  Widget _buildDonutBadge(IconData icon, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildSmartInsights(ThemeData theme, Statistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('이번 달 소비 인사이트', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            Text('스마트 분석', style: theme.textTheme.labelSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildSmartInsightCard(
              theme,
              '하루 평균 지출',
              '${NumberFormat('#,###').format(stats.dailyAverageExpense.toInt())}원',
              Icons.calendar_today_rounded,
              Colors.blue.withValues(alpha: 0.1),
              Colors.blue,
              '지출 속도 체크',
            ),
            const SizedBox(width: 16),
            _buildSmartInsightCard(
              theme,
              '최다 지출 요일',
              stats.mostSpentWeekday,
              Icons.local_fire_department_rounded,
              Colors.orange.withValues(alpha: 0.1),
              Colors.orange,
              '소비 점검일',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmartInsightCard(ThemeData theme, String title, String value, IconData icon, Color bgColor, Color iconColor, String sub) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: theme.colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(sub, style: theme.textTheme.labelSmall?.copyWith(color: iconColor.withValues(alpha: 0.6), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
