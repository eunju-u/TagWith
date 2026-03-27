import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../data/models.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import 'category_edit_screen.dart';
import '../widgets/app_dialog.dart';

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final allCategories = provider.allCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: allCategories.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isGlobal = cat.id == '0' || int.parse(cat.id == '' ? '0' : cat.id) <= 10; // Simple check
          
          return Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cat.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: cat.iconData != null 
                    ? Icon(cat.iconData, color: cat.color, size: 24)
                    : Text(cat.icon, style: const TextStyle(fontSize: 24)),
              ),
              title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(isGlobal ? '시스템 기본' : '사용자 정의', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blue),
                    onPressed: () => _editCategory(context, provider, cat),
                  ),
                  if (!isGlobal) 
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      onPressed: () => _deleteCategory(context, provider, cat),
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCategory(context, provider),
        label: const Text('새 카테고리 추가'),
        icon: const Icon(Icons.add),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  void _addCategory(BuildContext context, TransactionProvider provider) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(
          onSave: (newCat) {
            provider.addCustomCategory(newCat);
          },
        ),
      ),
    );
  }

  void _editCategory(BuildContext context, TransactionProvider provider, Category category) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => CategoryEditScreen(
          category: category,
          onSave: (updated) {
            provider.updateCustomCategory(updated);
          },
        ),
      ),
    );
  }

  void _deleteCategory(BuildContext context, TransactionProvider provider, Category category) {
    AppDialog.show(
      context: context,
      title: '카테고리 삭제',
      content: '이 카테고리를 삭제하시겠습니까?\n이 카테고리로 저장된 지출 내역은 그대로 유지되지만 카테고리 정보가 변경될 수 있습니다.',
      confirmText: '삭제',
      confirmColor: Colors.red,
      onConfirm: () => provider.deleteCustomCategory(category.id),
    );
  }

}
