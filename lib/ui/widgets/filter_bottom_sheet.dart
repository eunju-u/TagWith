import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';

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
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            bottom: true,
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('필터 설정', style: theme.textTheme.titleLarge),
                      TextButton(
                        onPressed: () => provider.clearFilters(forStats: forStats),
                        child: const Text('초기화', style: TextStyle(color: AppColors.secondary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('구분', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _FilterChip(
                        label: '전체',
                        isSelected: selectedType == null,
                        onSelected: (_) => provider.setTypeFilter(null, forStats: forStats),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '수입',
                        isSelected: selectedType == TransactionType.income,
                        onSelected: (_) => provider.setTypeFilter(TransactionType.income, forStats: forStats),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '지출',
                        isSelected: selectedType == TransactionType.expense,
                        onSelected: (_) => provider.setTypeFilter(TransactionType.expense, forStats: forStats),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('1차 태그 (카테고리)', style: theme.textTheme.titleMedium),
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
                      Text('2차 태그 (관계)', style: theme.textTheme.titleMedium),
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
                      child: const Text('적용하기'),
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
    final theme = Theme.of(context);
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('새 태그 추가'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '태그 이름을 입력하세요 (예: 친구, 가족)',
            hintStyle: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ),
          ElevatedButton(
            onPressed: () {
              provider.addCustomRelation(controller.text);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('추가'),
          ),
        ],
      ),
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
