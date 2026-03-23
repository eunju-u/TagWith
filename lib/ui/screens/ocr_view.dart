import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/ocr_transaction_card.dart';
import '../widgets/relation_picker_sheet.dart';

class OCRView extends StatefulWidget {
  final List<Transaction> extractedItems;
  const OCRView({super.key, required this.extractedItems});

  @override
  State<OCRView> createState() => _OCRViewState();
}

class _OCRViewState extends State<OCRView> {
  late List<Transaction> _extractedItems;
  bool _isSaving = false; // 저장 중 상태 추가

  @override
  void initState() {
    super.initState();
    _extractedItems = List.from(widget.extractedItems);
  }

  void _removeItem(int index) {
    setState(() => _extractedItems.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scaffold를 Stack으로 감싸서 오버레이가 앱바를 포함한 전체 화면을 덮도록 함
    return Stack(
      children: [
        Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            title: const Text('분석 결과 확인', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.black),
            centerTitle: true,
          ),
          body: SafeArea(
            child: _extractedItems.isEmpty
                ? _buildEmptyState()
                : _buildReviewList(),
          ),
        ),
        if (_isSaving) _buildSavingOverlay(theme), // 저장 중일 때만 오버레이 노출
      ],
    );
  }

  Widget _buildSavingOverlay(ThemeData theme) {
    return Material( // 텍스트 스타일 유지를 위해 Material 위젯 추가
      color: theme.colorScheme.surface, // 배경을 흰색(Surface)으로 꽉 채움
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary, // 분석 중 화면과 동일한 보라색
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                Text(
                  '정보를 저장하고 있어요...',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '잠시만 기다려 주세요',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('모든 내역이 처리되었습니다.', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('홈으로 돌아가기', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('분석된 내역', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  Text('${_extractedItems.length}건', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text('내용을 확인하고 저장해 주세요.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _extractedItems.length,
            itemBuilder: (context, index) {
              return OCRTransactionCard(
                transaction: _extractedItems[index],
                onDelete: () => _removeItem(index),
                onUpdate: (updated) {
                  setState(() => _extractedItems[index] = updated);
                },
                showDelete: true,
                onPickCategory: () => _showCategoryPicker(index),
                onPickRelation: () => _showRelationPicker(index),
                headerBuilder: (title) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        _buildBottomButtons(),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context), // 저장 중에는 취소 방지
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                foregroundColor: Colors.grey[600],
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: const Text('취소'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async { // 저장 중에는 중복 클릭 방지
                setState(() => _isSaving = true); // 저장 시작

                try {
                  final provider = Provider.of<TransactionProvider>(context, listen: false);
                  for (var tx in _extractedItems) {
                    await provider.addTransaction(tx);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${_extractedItems.length}건의 내역이 저장되었습니다.'))
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('저장 중 오류가 발생했습니다: $e'))
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
              child: const Text('저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryPicker(int index) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    CategoryPickerSheet.show(
      context: context,
      provider: provider,
      onSelected: (category) {
        setState(() {
          _extractedItems[index] = _extractedItems[index].copyWith(category: category);
        });
      },
    );
  }

  void _showRelationPicker(int index) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    RelationPickerSheet.show(
      context: context,
      provider: provider,
      selectedRelations: _extractedItems[index].relations,
      onUpdate: (relations) {
        setState(() {
          _extractedItems[index] = _extractedItems[index].copyWith(relations: relations);
        });
      },
    );
  }
}
