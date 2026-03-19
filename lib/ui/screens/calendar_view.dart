import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';
import '../widgets/filter_bottom_sheet.dart';

enum CalendarViewType { year, month, week }

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  CalendarViewType _viewType = CalendarViewType.month;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
  }

  String _formatFocusedDate() {
    if (_viewType == CalendarViewType.year) {
      return DateFormat('yyyy년').format(_focusedDay);
    }
    return DateFormat('yyyy년 MM월').format(_focusedDay);
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FilterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left_rounded, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: () => setState(() {
                if (_viewType == CalendarViewType.year) {
                  _focusedDay = DateTime(_focusedDay.year - 1, _focusedDay.month);
                } else {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                }
              }),
            ),
            const SizedBox(width: 8),
            Text(_formatFocusedDate(), style: theme.textTheme.headlineMedium),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.chevron_right_rounded, size: 24, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              onPressed: () => setState(() {
                if (_viewType == CalendarViewType.year) {
                  _focusedDay = DateTime(_focusedDay.year + 1, _focusedDay.month);
                } else {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                }
              }),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.8)),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: provider.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.loadTransactions(),
              child: Column(
                children: [
                  _buildViewSelector(theme),
                  _buildSummaryHeader(provider),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _viewType == CalendarViewType.year
                        ? _buildYearView(provider, theme)
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100), // 바텀 패딩을 조금 줄여 캘린더 공간 확보
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final availableHeight = constraints.maxHeight - 40;
                                final calculatedRowHeight = availableHeight / 6;
                                final rowHeight = calculatedRowHeight > 62.0 ? calculatedRowHeight : 62.0; // 최소 높이 보장

                                return TableCalendar(
                                  firstDay: DateTime.utc(2020, 1, 1),
                                  lastDay: DateTime.utc(2030, 12, 31),
                                  focusedDay: _focusedDay,
                                  calendarFormat: _calendarFormat,
                                  headerVisible: false,
                                  daysOfWeekHeight: 40,
                                  rowHeight: rowHeight,
                                  onPageChanged: (focusedDay) {
                                    setState(() => _focusedDay = focusedDay);
                                  },
                                  daysOfWeekStyle: DaysOfWeekStyle(
                                    weekdayStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 13, fontWeight: FontWeight.w600),
                                    weekendStyle: TextStyle(color: AppColors.expense.withValues(alpha: 0.6), fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  calendarStyle: CalendarStyle(
                                    todayDecoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    todayTextStyle: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                                    selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.w500, fontSize: 16),
                                    weekendTextStyle: const TextStyle(color: AppColors.expense, fontWeight: FontWeight.w500, fontSize: 16),
                                    outsideDaysVisible: false,
                                    cellMargin: const EdgeInsets.all(4),
                                  ),
                                  onDaySelected: (selectedDay, focusedDay) {
                                    setState(() {
                                      _focusedDay = focusedDay;
                                    });
                                    _showTransactionDetailPopup(context, selectedDay);
                                  },
                                  calendarBuilders: CalendarBuilders(
                                    defaultBuilder: (context, day, focusedDay) {
                                      final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
                                      return _buildDayCell(day, provider, theme, isWeekend: isWeekend);
                                    },
                                    todayBuilder: (context, day, focusedDay) => _buildDayCell(day, provider, theme, isToday: true),
                                    selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, provider, theme, isSelected: true),
                                    outsideBuilder: (context, day, focusedDay) => const SizedBox.shrink(),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildViewSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          _buildViewTypeButton('연', CalendarViewType.year, theme),
          const SizedBox(width: 8),
          _buildViewTypeButton('월', CalendarViewType.month, theme),
          const SizedBox(width: 8),
          _buildViewTypeButton('주', CalendarViewType.week, theme),
        ],
      ),
    );
  }

  Widget _buildViewTypeButton(String label, CalendarViewType type, ThemeData theme) {
    final isSelected = _viewType == type;
    return GestureDetector(
      onTap: () => setState(() {
        _viewType = type;
        if (type == CalendarViewType.week) {
          _calendarFormat = CalendarFormat.week;
        } else if (type == CalendarViewType.month) {
          _calendarFormat = CalendarFormat.month;
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader(TransactionProvider provider) {
    final theme = Theme.of(context);
    final isYear = _viewType == CalendarViewType.year;
    
    final totalIncome = isYear ? provider.getTotalIncomeByYear(_focusedDay.year) : provider.getTotalIncomeByMonth(_focusedDay);
    final cashIncome = isYear 
        ? provider.getTotalByMethod(TransactionType.income, [PaymentMethod.cash], year: _focusedDay.year)
        : provider.getTotalByMethod(TransactionType.income, [PaymentMethod.cash], month: _focusedDay);
    final cardIncome = isYear
        ? provider.getTotalByMethod(TransactionType.income, [PaymentMethod.checkCard, PaymentMethod.creditCard], year: _focusedDay.year)
        : provider.getTotalByMethod(TransactionType.income, [PaymentMethod.checkCard, PaymentMethod.creditCard], month: _focusedDay);

    final totalExpense = isYear ? provider.getTotalExpenseByYear(_focusedDay.year) : provider.getTotalExpenseByMonth(_focusedDay);
    final cashExpense = isYear
        ? provider.getTotalByMethod(TransactionType.expense, [PaymentMethod.cash], year: _focusedDay.year)
        : provider.getTotalByMethod(TransactionType.expense, [PaymentMethod.cash], month: _focusedDay);
    final cardExpense = isYear
        ? provider.getTotalByMethod(TransactionType.expense, [PaymentMethod.checkCard, PaymentMethod.creditCard], year: _focusedDay.year)
        : provider.getTotalByMethod(TransactionType.expense, [PaymentMethod.checkCard, PaymentMethod.creditCard], month: _focusedDay);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              '총 수입',
              totalIncome,
              cashIncome,
              cardIncome,
              AppColors.income,
              theme,
            ),
          ),
          Container(width: 1, height: 40, color: theme.dividerColor.withValues(alpha: 0.5)),
          Expanded(
            child: _buildSummaryItem(
              '총 지출',
              totalExpense,
              cashExpense,
              cardExpense,
              AppColors.expense,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearView(TransactionProvider provider, ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        final month = DateTime(_focusedDay.year, index + 1);
        final income = provider.getTotalIncomeByMonth(month);
        final expense = provider.getTotalExpenseByMonth(month);

        return GestureDetector(
          onTap: () => setState(() {
            _focusedDay = month;
            _viewType = CalendarViewType.month;
            _calendarFormat = CalendarFormat.month;
          }),
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: month.month == DateTime.now().month && month.year == DateTime.now().year
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : theme.dividerColor,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${index + 1}월',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: month.month == DateTime.now().month && month.year == DateTime.now().year ? AppColors.primary : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (income > 0)
                  Text(
                    '+${NumberFormat('#,###').format(income)}',
                    style: const TextStyle(color: AppColors.income, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (expense > 0)
                  Text(
                    '-${NumberFormat('#,###').format(expense)}',
                    style: const TextStyle(color: AppColors.expense, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (income == 0 && expense == 0)
                  Text(
                    '-',
                    style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.1), fontSize: 12),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, double total, double cash, double card, Color color, ThemeData theme) {
    final format = NumberFormat('#,###');
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${format.format(total)}원',
          style: theme.textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('현금', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                const SizedBox(height: 2),
                Text('카드', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
              ],
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${format.format(cash)}원', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${format.format(card)}원', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime day, TransactionProvider provider, ThemeData theme, {bool isToday = false, bool isSelected = false, bool isWeekend = false}) {
    final income = provider.getTotalIncomeByDate(day);
    final expense = provider.getTotalExpenseByDate(day);

    TextStyle dateStyle = TextStyle(
      color: isWeekend ? AppColors.expense : theme.colorScheme.onSurface,
      fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
      fontSize: 16,
    );

    if (isSelected) dateStyle = dateStyle.copyWith(color: Colors.white);
    if (isToday && !isSelected) dateStyle = dateStyle.copyWith(color: AppColors.primary);

    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 4), // 셀 상단에 약간의 여백
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            height: 40,
            width: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected || (isToday && !isSelected))
                  Container(
                    width: 40,
                    height: 40,
                    decoration: isSelected
                        ? const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)
                        : BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                  ),
                Text('${day.day}', style: dateStyle),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (income > 0)
                Text(
                  '+${NumberFormat('#,###').format(income)}',
                  style: TextStyle(
                    color: AppColors.income,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (expense > 0)
                Text(
                  '-${NumberFormat('#,###').format(expense)}',
                  style: TextStyle(
                    color: AppColors.expense,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (income == 0 && expense == 0)
                const SizedBox(height: 18), // Placeholder for consistent height
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider) {
    final transactions = provider.getTransactionsByDate(_focusedDay);
    final theme = Theme.of(context);

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 12),
            Text('내역이 없습니다', style: theme.textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemBuilder: (context, index) {
        final t = transactions[index];
        return _buildTransactionItem(t);
      },
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: t.category.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(t.category.icon, color: t.category.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.description, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '${t.category.name}${t.relations.isNotEmpty ? ' • ${t.relations.map((r) => r.name).join(', ')}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          Text(
            '${t.type == TransactionType.income ? '+' : '-'}${NumberFormat('#,###').format(t.amount)}원',
            style: theme.textTheme.titleMedium?.copyWith(
              color: t.type == TransactionType.income ? AppColors.income : AppColors.expense,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetailPopup(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(DateFormat('MM월 dd일 내역').format(date), style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 10),
            Expanded(
              child: _buildRecentTransactions(Provider.of<TransactionProvider>(context, listen: false)),
            ),
          ],
        ),
      ),
    );
  }
}
