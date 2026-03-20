import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    final currencyFormat = NumberFormat('#,###');
    _amountController = TextEditingController(
      text: widget.transaction.amount > 0 ? currencyFormat.format(widget.transaction.amount.toInt()) : '',
    );
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
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: t.isDuplicate ? theme.colorScheme.error.withValues(alpha: 0.03) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: t.isDuplicate 
            ? Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)) 
            : Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light && !t.isDuplicate 
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)] 
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (t.isDuplicate)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: theme.colorScheme.error),
                        const SizedBox(width: 6),
                        Text(
                          '이미 저장된 내역입니다', 
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
                    icon: Icon(Icons.close_rounded, size: 22, color: theme.colorScheme.onSurface.withValues(alpha: 0.2)),
                    onPressed: widget.onDelete,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          widget.headerBuilder('내용'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _descriptionController,
              onChanged: (val) => widget.onUpdate(t.copyWith(description: val)),
              decoration: const InputDecoration(
                hintText: '무엇에 쓰셨나요?',
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),
          widget.headerBuilder('금액'),
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
                '원',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 12),
          widget.headerBuilder('날짜'),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
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
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallChip(context, t.category.name, t.category.icon, onTap: widget.onPickCategory),
              ...t.relations.map((rel) => _buildSmallChip(context, rel.name, Icons.person, onDelete: () {
                    final updatedRelations = List<Relation>.from(t.relations)..remove(rel);
                    widget.onUpdate(t.copyWith(relations: updatedRelations));
                  })),
              _buildSmallChip(context, '관계(태그)', Icons.person_add_outlined, isAction: true, onTap: widget.onPickRelation),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(BuildContext context, String label, IconData icon, {bool isAction = false, VoidCallback? onTap, VoidCallback? onDelete}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isAction ? Border.all(color: theme.dividerColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : AppColors.primary)),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
