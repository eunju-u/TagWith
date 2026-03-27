import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';

import '../../ui/screens/category_edit_screen.dart';

class CategoryPickerSheet {
  static void show({
    required BuildContext context,
    required TransactionProvider provider,
    required Function(Category) onSelected,
  }) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(32, 24, 32, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
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
              const Text(AppStrings.categoryLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.count(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.75,
                  children: [
                    ...provider.allCategories.map((cat) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          onSelected(cat);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: cat.color.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: cat.iconData != null 
                                  ? Icon(cat.iconData, color: cat.color, size: 24)
                                  : Text(cat.icon, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(height: 8),
                            Flexible(
                              child: Text(
                                cat.name, 
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ), 
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )).toList(),
                    // 카테고리 추가 버튼
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _openCategoryEditScreen(context, provider),
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.dividerColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.add_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4), size: 24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void _openCategoryEditScreen(BuildContext context, TransactionProvider provider) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(
          onSave: (newCat) => provider.addCustomCategory(newCat),
        ),
      ),
    );
  }
}
