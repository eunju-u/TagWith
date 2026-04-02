import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_icons.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/circle_gradient_fab.dart';
import '../widgets/loading_overlay.dart';

class PaymentMethodManagementScreen extends StatefulWidget {
  const PaymentMethodManagementScreen({super.key});

  @override
  State<PaymentMethodManagementScreen> createState() => _PaymentMethodManagementScreenState();
}

class _PaymentMethodManagementScreenState extends State<PaymentMethodManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context);
    final paymentMethods = provider.paymentMethods;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(AppStrings.paymentMethodManagementTitle, style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: paymentMethods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_off_outlined, size: 64, color: theme.dividerColor),
                  const SizedBox(height: 16),
                  Text(AppStrings.paymentMethodEmptyMessage, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5))),
                  const SizedBox(height: 8),
                  Text(AppStrings.paymentMethodEmptySubMessage, style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.3), fontSize: 12)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: paymentMethods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final method = paymentMethods[index];
                return _buildMethodTile(context, method, provider);
              },
            ),
      floatingActionButton: CircleGradientFAB(
        onPressed: () => _showAddEditDialog(context, provider),
        icon: Icons.add_rounded,
        tooltip: '결제 수단 추가',
      ),
    );
  }


  Widget _buildMethodTile(BuildContext context, PaymentMethodModel method, TransactionProvider provider) {
    final theme = Theme.of(context);
    IconData icon;
    switch (method.type) {
      case PaymentMethodBaseType.cash: icon = Icons.payments_outlined; break;
      case PaymentMethodBaseType.checkCard: icon = Icons.credit_card_outlined; break;
      case PaymentMethodBaseType.creditCard: icon = Icons.account_balance_wallet_outlined; break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        title: Text(method.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(_getTypeLabel(method.type), style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _showAddEditDialog(context, provider, method: method),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => _showDeleteConfirm(context, provider, method),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(PaymentMethodBaseType type) {
    switch (type) {
      case PaymentMethodBaseType.cash: return AppStrings.cashLabel;
      case PaymentMethodBaseType.checkCard: return AppStrings.checkCardLabel;
      case PaymentMethodBaseType.creditCard: return AppStrings.creditCardLabel;
    }
  }

  void _showAddEditDialog(BuildContext context, TransactionProvider provider, {PaymentMethodModel? method}) {
    final nameController = TextEditingController(text: method?.name);
    PaymentMethodBaseType selectedType = method?.type ?? PaymentMethodBaseType.checkCard;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(method == null ? AppStrings.paymentMethodAddEntry : AppStrings.paymentMethodEditEntry, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppStrings.paymentMethodNameLabel,
                  hintText: AppStrings.paymentMethodNameHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(AppStrings.paymentMethodTypeLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: PaymentMethodBaseType.values
                    .map((type) {
                  final isSelected = selectedType == type;
                  return ChoiceChip(
                    label: Text(_getTypeLabel(type)),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (val) {
                      if (val) setDialogState(() => selectedType = type);
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.grey,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(AppStrings.cancel, style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  AppSnackBar.show(context, '이름을 입력해주세요.');
                  return;
                }
                
                final newMethod = PaymentMethodModel(
                  id: method?.id ?? '',
                  name: nameController.text.trim(),
                  type: selectedType,
                  isActive: method?.isActive ?? true,
                );

                Navigator.pop(context);
                AppLoadingOverlay.show(context);
                
                bool success;
                if (method == null) {
                  success = await provider.addPaymentMethod(newMethod);
                } else {
                  success = await provider.updatePaymentMethod(newMethod);
                }
                
                AppLoadingOverlay.hide();
                if (success) {
                  if (context.mounted) AppSnackBar.show(context, AppStrings.saveComplete);
                } else {
                  if (context.mounted) AppSnackBar.show(context, AppStrings.saveFailed);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, TransactionProvider provider, PaymentMethodModel method) {
    AppDialog.show(
      context: context,
      title: AppStrings.paymentMethodDeleteConfirmTitle,
      content: '"${method.name}"${AppStrings.paymentMethodDeleteConfirmContent}',
      confirmText: AppStrings.delete,
      confirmColor: Colors.redAccent,
      onConfirm: () async {
        AppLoadingOverlay.show(context);
        final success = await provider.deletePaymentMethod(method.id);
        AppLoadingOverlay.hide();
        if (success) {
          if (context.mounted) AppSnackBar.show(context, AppStrings.deleteSuccess);
        } else {
          if (context.mounted) AppSnackBar.show(context, AppStrings.deleteFailed);
        }
      },
    );
  }
}
