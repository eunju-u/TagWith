import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/input_formatters.dart';
import '../../core/theme.dart';
import '../../core/app_icons.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/payment_method_selector.dart';

class RecurringAddScreen extends StatefulWidget {
  const RecurringAddScreen({super.key});

  @override
  State<RecurringAddScreen> createState() => _RecurringAddScreenState();
}

class _RecurringAddScreenState extends State<RecurringAddScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  
  TransactionType _type = TransactionType.expense;
  Category? _selectedCategory;
  String _paymentMethod = 'cash';
  String? _paymentMethodId;
  
  String _selectedInterval = 'monthly';
  int _selectedDayOfMonth = DateTime.now().day;
  int _selectedDayOfWeek = DateTime.now().weekday == 7 ? 0 : DateTime.now().weekday;
  DateTime _startDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final cats = provider.allCategories;
    _selectedCategory = cats.any((c) => c.name == '식비')
        ? cats.firstWhere((c) => c.name == '식비')
        : (cats.isNotEmpty ? cats.first : null);
    _paymentMethod = AppStrings.cashLabel;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      
      final recurring = RecurringTransaction(
        id: '',
        amount: amount,
        description: _descriptionController.text.trim(),
        category: _selectedCategory!,
        type: _type,
        paymentMethod: _paymentMethod,
        paymentMethodId: _paymentMethodId,
        interval: _selectedInterval,
        dayOfMonth: _selectedInterval == 'monthly' ? _selectedDayOfMonth : null,
        dayOfWeek: _selectedInterval == 'weekly' ? _selectedDayOfWeek : null,
        startDate: _startDate,
      );

      final success = await provider.addRecurringTransaction(recurring);
      
      if (mounted) {
        if (success) {
          Navigator.pop(context);
          AppSnackBar.show(context, AppStrings.saveComplete);
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
              // Header
              Row(
                children: [
                   IconButton(
                    icon: const Icon(AppIcons.close),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('고정 지출 등록', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const SizedBox(width: 40), // Balance close button
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

              // Form Sections
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

              _buildSectionHeader(AppStrings.paymentMethodLabel),
              PaymentMethodSelector(
                provider: provider,
                paymentMethod: _paymentMethod,
                paymentMethodId: _paymentMethodId,
                onSelected: (name, id) {
                  _amountFocusNode.unfocus();
                  setState(() {
                    _paymentMethod = name;
                    _paymentMethodId = id;
                  });
                },
              ),
              const SizedBox(height: 24),

              const Divider(),
              const SizedBox(height: 16),

              // Recurring Settings
              _buildSectionHeader('반복 주기'),
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
              const SizedBox(height: 180), // Space for bottom sheet
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
            child: const Text('고정 지출 등록하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
