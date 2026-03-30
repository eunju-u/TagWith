import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/input_formatters.dart';
import '../../data/models.dart';

class OCRTransactionCard extends StatefulWidget {
  final Transaction transaction;
  final Function(Transaction) onUpdate;
  final VoidCallback onDelete;
  final bool showDelete;
  final VoidCallback onPickCategory;
  final VoidCallback onPickRelation;
  final Widget Function(String) headerBuilder;

  const OCRTransactionCard({
    required this.transaction,
    required this.onUpdate,
    required this.onDelete,
    required this.showDelete,
    required this.onPickCategory,
    required this.onPickRelation,
    required this.headerBuilder,
    super.key,
  });

  @override
  State<OCRTransactionCard> createState() => _OCRTransactionCardState();
}

class _OCRTransactionCardState extends State<OCRTransactionCard> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  late TextEditingController _memoController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    final currencyFormat = NumberFormat('#,###');
    _amountController = TextEditingController(
      text: widget.transaction.amount > 0 ? currencyFormat.format(widget.transaction.amount.toInt()) : '',
    );
    _memoController = TextEditingController(text: widget.transaction.memo ?? '');
  }

  @override
  void didUpdateWidget(covariant OCRTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaction.description != widget.transaction.description && 
        _descriptionController.text != widget.transaction.description) {
      _descriptionController.text = widget.transaction.description;
    }
    
    final currencyFormat = NumberFormat('#,###');
    final formattedAmount = widget.transaction.amount > 0 ? currencyFormat.format(widget.transaction.amount.toInt()) : '';
    if (oldWidget.transaction.amount != widget.transaction.amount && 
        _amountController.text != formattedAmount) {
      _amountController.text = formattedAmount;
    }

    if (oldWidget.transaction.memo != widget.transaction.memo && 
        _memoController.text != widget.transaction.memo) {
      _memoController.text = widget.transaction.memo ?? '';
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
      decoration: BoxDecoration(
        color: t.isDuplicate ? theme.colorScheme.error.withOpacity(0.03) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: t.isDuplicate 
            ? Border.all(color: theme.colorScheme.error.withOpacity(0.2)) 
            : Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light && !t.isDuplicate 
            ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)] 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // 수직 수평 정렬을 일치시킴
            children: [
              if (t.isDuplicate)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // 내부 패딩 축소
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 6),
                        Text(
                          AppStrings.ocrDuplicateItemLabel, 
                          style: TextStyle(
                            color: theme.colorScheme.error, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w600
                          )
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Spacer(),
              if (widget.showDelete)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close_rounded, size: 22, color: theme.colorScheme.onSurface.withOpacity(0.2)),
                    onPressed: widget.onDelete,
                  ),
                ),
            ],
          ),
          SizedBox(height: t.isDuplicate ? 8 : 0),
          widget.headerBuilder(AppStrings.descriptionLabel),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _descriptionController,
              onChanged: (val) => widget.onUpdate(t.copyWith(description: val)),
              decoration: const InputDecoration(
                hintText: AppStrings.descriptionHint,
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          widget.headerBuilder(AppStrings.amountLabel),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(',', '');
                    final amount = double.tryParse(cleanVal) ?? 0;
                    widget.onUpdate(t.copyWith(amount: amount));
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                AppStrings.currencyUnit,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withOpacity(0.5),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 12),
          widget.headerBuilder(AppStrings.dateLabel),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: t.date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (date != null) widget.onUpdate(t.copyWith(date: date));
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy. MM. dd.').format(t.date),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          widget.headerBuilder(AppStrings.memoLabel),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
            ),
            child: TextField(
              controller: _memoController,
              onChanged: (val) => widget.onUpdate(t.copyWith(memo: val.isNotEmpty ? val : null)),
              decoration: const InputDecoration(
                hintText: AppStrings.memoHint,
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
               _buildSmallChip(context, t.category.name, t.category.iconData ?? t.category.icon, onTap: widget.onPickCategory, color: t.category.color),
              _buildSmallChip(context, _getPaymentMethodLabel(t.paymentMethod), _getPaymentMethodIcon(t.paymentMethod), onTap: _showPaymentMethodPicker),
              ...t.relations.map((rel) => _buildSmallChip(context, rel.name, Icons.person, onDelete: () {
                    final updatedRelations = List<Relation>.from(t.relations)..remove(rel);
                    widget.onUpdate(t.copyWith(relations: updatedRelations));
                  })),
              _buildSmallChip(context, AppStrings.ocrRelationTagActionLabel, Icons.person_add_outlined, isAction: true, onTap: widget.onPickRelation),
            ],
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return AppStrings.cashLabel;
      case PaymentMethod.checkCard: return AppStrings.checkCardLabel;
      case PaymentMethod.creditCard: return AppStrings.creditCardLabel;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash: return Icons.payments_outlined;
      case PaymentMethod.checkCard: return Icons.credit_card_outlined;
      case PaymentMethod.creditCard: return Icons.credit_card;
    }
  }

  void _showPaymentMethodPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(AppStrings.ocrPaymentMethodPickerTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              ListTile(
                leading: const Icon(Icons.payments_outlined, color: AppColors.primary),
                title: const Text(AppStrings.cashLabel),
                onTap: () {
                  widget.onUpdate(widget.transaction.copyWith(paymentMethod: PaymentMethod.cash));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card_outlined, color: AppColors.primary),
                title: const Text(AppStrings.checkCardLabel),
                onTap: () {
                  widget.onUpdate(widget.transaction.copyWith(paymentMethod: PaymentMethod.checkCard));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.credit_card, color: AppColors.primary),
                title: const Text(AppStrings.creditCardLabel),
                onTap: () {
                  widget.onUpdate(widget.transaction.copyWith(paymentMethod: PaymentMethod.creditCard));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmallChip(BuildContext context, String label, dynamic icon, {bool isAction = false, VoidCallback? onTap, VoidCallback? onDelete, Color? color}) {
    final theme = Theme.of(context);
    final chipColor = color ?? AppColors.primary;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : chipColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: isAction ? Border.all(color: theme.dividerColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is IconData)
              Icon(icon, size: 14, color: isAction ? theme.colorScheme.onSurface.withOpacity(0.5) : chipColor)
            else if (icon is String)
              Text(icon, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isAction ? theme.colorScheme.onSurface.withOpacity(0.7) : chipColor)),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: Icon(Icons.close, size: 14, color: chipColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
