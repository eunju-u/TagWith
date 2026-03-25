import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';
import '../widgets/app_dialog.dart';

class FilterBottomSheet extends StatelessWidget {
  final bool forStats;
  const FilterBottomSheet({super.key, this.forStats = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    
    // Get unique categories for the filter list
    final allCategories = provider.allCategories;

    final selectedType = forStats ? provider.statsSelectedType : provider.calendarSelectedType;
    final selectedCategories = forStats ? provider.statsSelectedCategories : provider.calendarSelectedCategories;
    final selectedRelations = forStats ? provider.statsSelectedRelations : provider.calendarSelectedRelations;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            bottom: true,
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.filterTitle, style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => provider.clearFilters(forStats: forStats),
                        child: const Text(AppStrings.filterReset, style: TextStyle(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(AppStrings.filterSectionType, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _FilterChip(
                        label: AppStrings.filterAll,
                        isSelected: selectedType == null,
                        onSelected: (_) => provider.setTypeFilter(null, forStats: forStats),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppStrings.incomeLabel,
                        isSelected: selectedType == TransactionType.income,
                        onSelected: (_) => provider.setTypeFilter(TransactionType.income, forStats: forStats),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppStrings.expenseLabel,
                        isSelected: selectedType == TransactionType.expense,
                        onSelected: (_) => provider.setTypeFilter(TransactionType.expense, forStats: forStats),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(AppStrings.filterSectionCategory, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: allCategories.map((cat) => _FilterChip(
                          label: cat.name,
                          isSelected: selectedCategories.contains(cat.id),
                          onSelected: (_) => provider.toggleCategoryFilter(cat.id, forStats: forStats),
                        )).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppStrings.filterSectionRelation, style: theme.textTheme.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 20),
                        onPressed: () => _showAddTagDialog(context, provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: provider.customRelations.map((rel) => _FilterChip(
                          label: rel.name,
                          isSelected: selectedRelations.contains(rel.id),
                          onSelected: (_) => provider.toggleRelationFilter(rel.id, forStats: forStats),
                        )).toList(),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(AppStrings.filterApply),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, TransactionProvider provider) {
    final controller = TextEditingController();
    AppDialog.show(
      context: context,
      title: AppStrings.addTagTitle,
      icon: Icons.label_outline_rounded,
      contentWidget: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: AppStrings.addTagHint,
          hintStyle: TextStyle(fontSize: 14),
          border: UnderlineInputBorder(),
        ),
      ),
      cancelText: AppStrings.cancel,
      confirmText: AppStrings.add,
      onConfirm: () {
        if (controller.text.trim().isNotEmpty) {
          provider.addCustomRelation(controller.text.trim());
        }
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: AppColors.primary.withValues(alpha: 0.2),
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color: isSelected ? AppColors.primary : theme.dividerColor,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
