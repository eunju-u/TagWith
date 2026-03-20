import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../core/input_formatters.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/relation_picker_sheet.dart';
import '../widgets/category_picker_sheet.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  List<Relation> _selectedRelations = [];
  TransactionType _type = TransactionType.expense;
  PaymentMethod _paymentMethod = PaymentMethod.checkCard;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    _selectedCategory = provider.allCategories.firstWhere((c) => c.name == '식비', orElse: () => provider.allCategories.first);
    
    // Request focus once after build
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액과 내용을 입력해 주세요.')),
      );
      return;
    }

    final transaction = Transaction(
      id: '', // Server will assign an ID
      date: _selectedDate,
      amount: amount,
      description: _descriptionController.text.trim(),
      type: _type,
      category: _selectedCategory!,
      relations: _selectedRelations,
      paymentMethod: _paymentMethod,
    );

    final success = await Provider.of<TransactionProvider>(context, listen: false).addTransaction(transaction);
    
    if (mounted) {
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 완료되었습니다!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장에 실패했습니다. 다시 시도해 주세요.')),
        );
      }
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
                    icon: const Icon(Icons.close_rounded),
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
                  _buildTypeButton(TransactionType.expense, '지출', theme),
                  const SizedBox(width: 12),
                  _buildTypeButton(TransactionType.income, '수입', theme),
                ],
              ),
              const SizedBox(height: 40),
              // Amount Input
              Center(
                child: Column(
                  children: [
                    Text(
                      _type == TransactionType.expense ? '얼마를 쓰셨나요?' : '얼마를 버셨나요?',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
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
                          hintText: '0',
                          hintStyle: TextStyle(color: AppColors.primary.withValues(alpha: 0.3)),
                          border: InputBorder.none,
                          suffixText: '원',
                          suffixStyle: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Moved Details Form: Description first
              _buildSectionHeader('내용'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: '무엇에 쓰셨나요?',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('결제 수단'),
              Row(
                children: [
                  _buildPaymentMethodButton(PaymentMethod.cash, '현금', theme),
                  const SizedBox(width: 8),
                  _buildPaymentMethodButton(PaymentMethod.checkCard, '체크카드', theme),
                  const SizedBox(width: 8),
                  _buildPaymentMethodButton(PaymentMethod.creditCard, '신용카드', theme),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('날짜'),
              _buildActionCard(
                icon: Icons.calendar_today_rounded,
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
              _buildSectionHeader('카테고리'),
              _buildActionCard(
                icon: _selectedCategory?.icon ?? Icons.category_rounded,
                label: _selectedCategory?.name ?? '선택해주세요',
                color: _selectedCategory?.color,
                onTap: () => CategoryPickerSheet.show(
                  context: context,
                  provider: provider,
                  onSelected: (cat) => setState(() => _selectedCategory = cat),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('관계 (태그)'),
              _buildRelationCard(provider),
              const SizedBox(height: 180), // Increased bottom space for better scrolling
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
              colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
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
            child: const Text('기록 완료하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.4),
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

  Widget _buildActionCard({required IconData icon, required String label, Color? color, required VoidCallback onTap}) {
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color ?? AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
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
        color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
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
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            deleteIconColor: AppColors.primary,
            labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          )),
          ActionChip(
            label: const Text('추가'),
            avatar: const Icon(Icons.add, size: 16),
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


  Widget _buildPaymentMethodButton(PaymentMethod method, String label, ThemeData theme) {
    final isSelected = _paymentMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _amountFocusNode.unfocus();
          setState(() => _paymentMethod = method);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


