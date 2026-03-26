import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../../core/theme.dart';
import '../widgets/app_dialog.dart';

class RelationPickerSheet {
  static void show({
    required BuildContext context,
    required TransactionProvider provider,
    required List<Relation> selectedRelations,
    required Function(List<Relation>) onUpdate,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(32, 12, 32, 40 + MediaQuery.of(context).padding.bottom),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text(AppStrings.relationPickerTitle,
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
                      Navigator.pop(context);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primary : theme.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _showAddTagDialog(BuildContext context, TransactionProvider provider, StateSetter setModalState) {
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
          border: UnderlineInputBorder(),
        ),
      ),
      confirmText: AppStrings.add,
      onConfirm: () async {
        final tagName = controller.text.trim();
        if (tagName.isNotEmpty) {
          await provider.addCustomRelation(tagName);
          setModalState(() {});
        }
      },
    );
  }
}
