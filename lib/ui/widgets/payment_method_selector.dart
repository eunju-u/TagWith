import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';

class PaymentMethodSelector extends StatelessWidget {
  final TransactionProvider provider;
  final String paymentMethod;
  final String? paymentMethodId;
  final PaymentMethodBaseType? paymentMethodBaseType;
  final Function(String name, String? id) onSelected;

  const PaymentMethodSelector({
    super.key,
    required this.provider,
    required this.paymentMethod,
    this.paymentMethodId,
    this.paymentMethodBaseType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1단계: 대분류 (현금, 체크카드, 신용카드)
    final mainMethods = [AppStrings.cashLabel, AppStrings.checkCardLabel, AppStrings.creditCardLabel];
    
    // 현재 선택된 항목의 대분류 판별
    String? currentMainType;
    
    // 1. 카드가 명시되어 있거나, 스냅샷에서 추출된 baseType이 있는 경우
    if (paymentMethodId != null || paymentMethodBaseType != null) {
      PaymentMethodBaseType? targetBaseType;
      
      if (paymentMethodId != null) {
        final matches = provider.paymentMethods.where((m) => m.id == paymentMethodId).toList();
        if (matches.isNotEmpty) {
          targetBaseType = matches.first.type;
        }
      }
      
      // 스냅샷에서 파싱된 타입이 있다면 (또는 위에서 찾은 타입)
      targetBaseType ??= paymentMethodBaseType;

      if (targetBaseType == PaymentMethodBaseType.checkCard) currentMainType = AppStrings.checkCardLabel;
      else if (targetBaseType == PaymentMethodBaseType.creditCard) currentMainType = AppStrings.creditCardLabel;
      else if (targetBaseType == PaymentMethodBaseType.cash) currentMainType = AppStrings.cashLabel;
      
      // [폴백] 여전히 모르는 경우 텍스트 키워드로 추론
      if (currentMainType == null) {
        String m = paymentMethod.toLowerCase();
        if (m.contains('체크') || m.contains('check')) currentMainType = AppStrings.checkCardLabel;
        else if (m.contains('신용') || m.contains('credit')) currentMainType = AppStrings.creditCardLabel;
        else currentMainType = AppStrings.cashLabel;
      }
    } 
    // 2. ID가 없는 경우 (현금 또는 이전 데이터의 시스템 명칭)
    else {
      String m = paymentMethod.toLowerCase();
      if (paymentMethod == AppStrings.cashLabel || m == 'cash' || m == '현금') {
        currentMainType = AppStrings.cashLabel;
      } else if (paymentMethod == AppStrings.checkCardLabel || m == 'checkcard' || m == '체크카드') {
        currentMainType = AppStrings.checkCardLabel;
      } else if (paymentMethod == AppStrings.creditCardLabel || m == 'creditcard' || m == '신용카드') {
        currentMainType = AppStrings.creditCardLabel;
      } else {
        currentMainType = AppStrings.cashLabel;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: mainMethods.map((label) {
              final isSelected = currentMainType == label;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  showCheckmark: false,
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) {
                       if (label == AppStrings.cashLabel) {
                         onSelected(AppStrings.cashLabel, null);
                       } else {
                         // 카드류 선택 시 해당 유형의 첫번째 카드로 자동 지정되거나, 
                         // 단순히 상위 칩만 활성화 (이후 디테일에서 선택 유도)
                         onSelected(label, null);
                       }
                    }
                  },
                  selectedColor: AppColors.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : Colors.grey,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(color: isSelected ? AppColors.primary : theme.dividerColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }).toList(),
          ),
        ),
        
        // 2단계: 카드 세부 선택 (체크/신용카드 선택 시 해당 유형의 카드가 있을 때만 노출)
        if ((currentMainType == AppStrings.checkCardLabel || currentMainType == AppStrings.creditCardLabel) && 
            provider.paymentMethods.any((m) => currentMainType == AppStrings.checkCardLabel 
                ? m.type == PaymentMethodBaseType.checkCard
                : m.type == PaymentMethodBaseType.creditCard)) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${currentMainType == AppStrings.checkCardLabel ? '사용하신 체크카드' : '사용하신 신용카드'}를 선택해주세요',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: provider.paymentMethods
                        .where((m) => currentMainType == AppStrings.checkCardLabel 
                            ? m.type == PaymentMethodBaseType.checkCard
                            : m.type == PaymentMethodBaseType.creditCard)
                        .map((card) {
                      final isCardSelected = paymentMethodId == card.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Text(card.name),
                          onPressed: () => onSelected(card.name, card.id),
                          backgroundColor: isCardSelected ? AppColors.primary : Colors.transparent,
                          labelStyle: TextStyle(color: isCardSelected ? Colors.white : theme.colorScheme.onSurface),
                          side: BorderSide(color: isCardSelected ? AppColors.primary : theme.dividerColor),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
