import 'package:flutter/material.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme.dart';

class RelationPickerSheet {
  static void show({
    required BuildContext context,
    required TransactionProvider provider,
    required List<Relation> selectedRelations,
    required Function(List<Relation>) onUpdate,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('관계 (태그) 선택',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () => _showAddTagDialog(context, provider, setModalState),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: provider.customRelations.map((rel) {
                  final isSelected = selectedRelations.any((r) => r.id == rel.id);
                  return FilterChip(
                    label: Text(rel.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      final updatedRelations = List<Relation>.from(selectedRelations);
                      if (selected) {
                        updatedRelations.add(rel);
                      } else {
                        updatedRelations.removeWhere((r) => r.id == rel.id);
                      }
                      onUpdate(updatedRelations);
                      setModalState(() {});
                      Navigator.pop(context); // Close as per ManualEntryScreen style
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static void _showAddTagDialog(BuildContext context, TransactionProvider provider, StateSetter setModalState) {
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
          decoration: const InputDecoration(hintText: '태그 이름 (예: 친구, 가족)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              final tagName = controller.text.trim();
              if (tagName.isNotEmpty) {
                await provider.addCustomRelation(tagName);
                setModalState(() {});
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}
