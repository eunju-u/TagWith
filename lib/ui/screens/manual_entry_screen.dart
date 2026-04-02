import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/input_formatters.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/relation_picker_sheet.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/loading_overlay.dart';
import '../../core/app_icons.dart';
import '../widgets/payment_method_selector.dart';

class ManualEntryScreen extends StatefulWidget {
  final Transaction? existingTransaction;
  const ManualEntryScreen({super.key, this.existingTransaction});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _memoController = TextEditingController(); // 추가
  final FocusNode _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  List<Relation> _selectedRelations = [];
  TransactionType _type = TransactionType.expense;
  String _paymentMethod = 'cash';
  String? _paymentMethodId;
  PaymentMethodBaseType? _paymentMethodBaseType;
  
  // 반복 설정 관련 상태
  bool _isRecurring = false;
  String _selectedInterval = 'monthly'; // 'monthly', 'weekly'
  int _selectedDayOfMonth = DateTime.now().day;
  int _selectedDayOfWeek = DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday; // 0이 일요일인 기준

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    
    if (widget.existingTransaction != null) {
      final t = widget.existingTransaction!;
      _amountController.text = formatCurrency(t.amount.toInt());
      _descriptionController.text = t.description;
      _selectedDate = t.date;
      _selectedCategory = t.category;
      _selectedRelations = List.from(t.relations);
      _type = t.type;
      _paymentMethod = t.paymentMethod;
      _paymentMethodId = t.paymentMethodId;
      _paymentMethodBaseType = t.paymentMethodBaseType;
      _memoController.text = t.memo ?? ''; 
    } else {
      _paymentMethod = AppStrings.cashLabel;
      final cats = provider.allCategories;
      _selectedCategory = cats.any((c) => c.name == '식비')
          ? cats.firstWhere((c) => c.name == '식비')
          : (cats.isNotEmpty ? cats.first : null);
      // Request focus once after build only when creating new entry
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _amountFocusNode.requestFocus();
      });
    }
  }

  String formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount);
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    _memoController.dispose(); // 추가
    super.dispose();
  }

  Future<void> _save() async {
    final amountStr = _amountController.text.replaceAll(',', '');
    final amount = double.tryParse(amountStr) ?? 0;
    if (amount <= 0 || _descriptionController.text.trim().isEmpty || _selectedCategory == null) {
      AppSnackBar.show(context, AppStrings.entryIncompleteError);
      return;
    }

    try {
      AppLoadingOverlay.show(context);

      final transaction = Transaction(
        id: widget.existingTransaction?.id ?? '', 
        date: _selectedDate,
        amount: amount,
        description: _descriptionController.text.trim(),
        type: _type,
        category: _selectedCategory!,
        relations: _selectedRelations,
        paymentMethod: _paymentMethod,
        paymentMethodId: _paymentMethodId,
        paymentMethodBaseType: _paymentMethodBaseType,
        memo: _memoController.text.trim().isNotEmpty ? _memoController.text.trim() : null, // 추가
      );

      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      bool success;
      if (widget.existingTransaction != null) {
        // 기존 내역 수정
        success = await provider.updateTransaction(transaction);
      } else {
        // 신규 내역 저장
        success = await provider.addTransaction(transaction);
        
        // 고정 지출 설정이 켜져있다면 반복 설정도 별도로 추가
        if (success && _isRecurring) {
          final recurring = RecurringTransaction(
            id: '',
            amount: amount,
            description: _descriptionController.text.trim(),
            category: _selectedCategory!,
            type: _type,
            paymentMethod: _paymentMethod,
            paymentMethodId: _paymentMethodId,
            paymentMethodBaseType: _paymentMethodBaseType,
            interval: _selectedInterval,
            dayOfMonth: _selectedInterval == 'monthly' ? _selectedDayOfMonth : null,
            dayOfWeek: _selectedInterval == 'weekly' ? _selectedDayOfWeek : null,
            startDate: _selectedDate,
          );
          await provider.addRecurringTransaction(recurring);
        }
      }
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          AppSnackBar.show(context, widget.existingTransaction != null ? AppStrings.updateComplete : AppStrings.saveComplete);
        } else {
          AppSnackBar.show(context, AppStrings.saveFailed);
        }
      }
    } finally {
      AppLoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: GestureDetector(
        onTap: () => _amountFocusNode.unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + 16),
              // Custom Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Type Selector
              Row(
                children: [
                  _buildTypeButton(TransactionType.expense, AppStrings.expenseLabel, theme),
                  const SizedBox(width: 12),
                  _buildTypeButton(TransactionType.income, AppStrings.incomeLabel, theme),
                ],
              ),
              const SizedBox(height: 40),
              // Amount Input
              Center(
                child: Column(
                  children: [
                    Text(
                      _type == TransactionType.expense ? AppStrings.amountExpensePrompt : AppStrings.amountIncomePrompt,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 8),
                    IntrinsicWidth(
                      child: TextField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CurrencyInputFormatter(),
                        ],
                        autofocus: false,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                        decoration: InputDecoration(
                          hintText: AppStrings.amountHint,
                          hintStyle: TextStyle(color: AppColors.primary.withOpacity(0.3)),
                          border: InputBorder.none,
                          suffixText: AppStrings.currencyUnit,
                          suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Moved Details Form: Description first
              _buildSectionHeader(AppStrings.descriptionLabel),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: AppStrings.descriptionHint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(AppStrings.paymentMethodLabel),
              PaymentMethodSelector(
                provider: provider,
                paymentMethod: _paymentMethod,
                paymentMethodId: _paymentMethodId,
                paymentMethodBaseType: _paymentMethodBaseType,
                onSelected: (name, id) {
                  _amountFocusNode.unfocus();
                  setState(() {
                    _paymentMethod = name;
                    _paymentMethodId = id;
                    // 선택 시 해당 카드의 타입을 찾아 업데이트
                    if (id != null) {
                      _paymentMethodBaseType = provider.paymentMethods.firstWhere((m) => m.id == id).type;
                    } else {
                      // 시스템 기본 수단 선택 시
                      if (name == AppStrings.cashLabel) _paymentMethodBaseType = PaymentMethodBaseType.cash;
                      else if (name == AppStrings.checkCardLabel) _paymentMethodBaseType = PaymentMethodBaseType.checkCard;
                      else if (name == AppStrings.creditCardLabel) _paymentMethodBaseType = PaymentMethodBaseType.creditCard;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(AppStrings.dateLabel),
              _buildActionCard(
                icon: AppIcons.calendar,
                label: DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(AppStrings.categoryLabel),
              _buildActionCard(
                icon: _selectedCategory?.iconData,
                emoji: _selectedCategory?.iconData == null ? _selectedCategory?.icon : null,
                label: _selectedCategory?.name ?? AppStrings.selectCategoryHint,
                color: _selectedCategory?.color,
                onTap: () => CategoryPickerSheet.show(
                  context: context,
                  provider: provider,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader(AppStrings.relationLabel),
              _buildRelationCard(provider),
              const SizedBox(height: 24),
              _buildSectionHeader(AppStrings.memoLabel),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _memoController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: AppStrings.memoHint,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Recurring Toggle & Options
              if (widget.existingTransaction == null) ...[
                _buildRecurringSection(theme),
                const SizedBox(height: 24),
              ],
              const SizedBox(height: 180),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(top: BorderSide(color: theme.dividerColor)),
        ),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              widget.existingTransaction != null ? AppStrings.completeEditButton : AppStrings.completeEntryButton, 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(TransactionType type, String label, ThemeData theme) {
    final isSelected = _type == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _amountFocusNode.unfocus();
          setState(() => _type = type);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _buildActionCard({IconData? icon, String? emoji, required String label, Color? color, required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        _amountFocusNode.unfocus();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                color: (color ?? AppColors.primary).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: emoji != null 
                  ? Text(emoji, style: const TextStyle(fontSize: 20))
                  : Icon(icon ?? Icons.category, color: color ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Icon(AppIcons.chevronRight, color: theme.colorScheme.onSurface.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationCard(TransactionProvider provider) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ..._selectedRelations.map((rel) => Chip(
            label: Text(rel.name),
            onDeleted: () => setState(() => _selectedRelations.remove(rel)),
            backgroundColor: AppColors.primary.withOpacity(0.1),
            deleteIconColor: AppColors.primary,
            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )),
          ActionChip(
            label: const Text(AppStrings.add),
            avatar: const Icon(AppIcons.add, size: 16),
            onPressed: () {
              _amountFocusNode.unfocus();
              _showRelationPicker(provider);
            },
            backgroundColor: Colors.transparent,
            side: BorderSide(color: theme.dividerColor),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ],
      ),
    );
  }



  void _showRelationPicker(TransactionProvider provider) {
    RelationPickerSheet.show(
      context: context,
      provider: provider,
      selectedRelations: _selectedRelations,
      onUpdate: (updated) => setState(() => _selectedRelations = updated),
    );
  }




  Widget _buildRecurringSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.recurringLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text('지정한 주기에 맞춰 내역이 자동 생성됩니다.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
            Switch.adaptive(
              value: _isRecurring,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),
          ],
        ),
        if (_isRecurring) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildSimpleButton(AppStrings.recurringMonthly, _selectedInterval == 'monthly', () => setState(() => _selectedInterval = 'monthly'))),
                    const SizedBox(width: 8),
                    Expanded(child: _buildSimpleButton(AppStrings.recurringWeekly, _selectedInterval == 'weekly', () => setState(() => _selectedInterval = 'weekly'))),
                  ],
                ),
                const SizedBox(height: 16),
                if (_selectedInterval == 'monthly')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(AppStrings.recurringDateLabel, style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: _selectedDayOfMonth,
                        underline: const SizedBox(),
                        items: List.generate(31, (i) => i + 1).map((day) => DropdownMenuItem(value: day, child: Text('$day일'))).toList(),
                        onChanged: (val) => setState(() => _selectedDayOfMonth = val!),
                      ),
                    ],
                  ),
                if (_selectedInterval == 'weekly')
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(AppStrings.recurringDayLabel, style: TextStyle(fontWeight: FontWeight.w600)),
                      DropdownButton<int>(
                        value: _selectedDayOfWeek,
                        underline: const SizedBox(),
                        items: [
                          DropdownMenuItem(value: 0, child: Text(AppStrings.recurringDaySun)),
                          DropdownMenuItem(value: 1, child: Text(AppStrings.recurringDayMon)),
                          DropdownMenuItem(value: 2, child: Text(AppStrings.recurringDayTue)),
                          DropdownMenuItem(value: 3, child: Text(AppStrings.recurringDayWed)),
                          DropdownMenuItem(value: 4, child: Text(AppStrings.recurringDayThu)),
                          DropdownMenuItem(value: 5, child: Text(AppStrings.recurringDayFri)),
                          DropdownMenuItem(value: 6, child: Text(AppStrings.recurringDaySat)),
                        ],
                        onChanged: (val) => setState(() => _selectedDayOfWeek = val!),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSimpleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}


