import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_service.dart';
import 'manual_entry_screen.dart';
import '../widgets/relation_picker_sheet.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/ocr_transaction_card.dart';

class OCRView extends StatefulWidget {
  const OCRView({super.key});

  @override
  State<OCRView> createState() => _OCRViewState();
}

class _OCRViewState extends State<OCRView> {
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  List<Transaction> _extractedItems = [];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _processImage(image.path);
    }
  }

  Future<void> _processImage(String path) async {
    setState(() => _isLoading = true);
    final service = TransactionService();
    
    try {
      final result = await service.uploadReceipt(path);
      if (result != null && result['parsed_items'] != null) {
        final List<dynamic> itemsData = result['parsed_items'];
        final List<Transaction> parsedTransactions = itemsData.map((item) {
          final receipt = Receipt.fromJson(item);
          return Transaction(
            id: '',
            date: DateTime.tryParse(receipt.date) ?? DateTime.now(),
            amount: receipt.amount,
            description: receipt.description,
            type: TransactionType.expense,
            category: Category.fromName(receipt.categorySuggestion),
            relations: [],
            paymentMethod: PaymentMethod.checkCard,
            isDuplicate: receipt.isDuplicate,
          );
        }).toList();

        setState(() {
          _isLoading = false;
          _extractedItems = parsedTransactions;
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          String errorMsg = '분석할 수 없습니다.';
          if (result == null) {
            errorMsg = '서버 내부 오류(500) 또는 네트워크 연결을 확인해 주세요.';
          } else if (result['parsed_items'] == null) {
            errorMsg = '정보를 신뢰할 수 없어 데이터 추출에 실패했습니다.';
          }
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg)));
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('예기치 못한 오류가 발생했습니다: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text('분석하고 있어요...', style: theme.textTheme.bodyMedium),
                  ],
                ),
              )
            : _extractedItems.isEmpty
                ? _buildEmptyState()
                : _buildReviewList(),
      ),
    );
  }

  void _addManualEntry() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManualEntryScreen()),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '기록 방식을\n선택해주세요',
            style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
          ),
          const SizedBox(height: 12),
          Text(
            '영수증/캡쳐본을 찍어 자동으로 입력하거나,\n직접 내용을 작성하실 수 있습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 40),
          _SelectionCard(
            title: '영수증/캡처본 업로드',
            subtitle: '내역을 자동으로 분석해드려요',
            icon: Icons.receipt_long_rounded,
            gradient: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
            onTap: _pickImage,
          ),
          const SizedBox(height: 20),
          _SelectionCard(
            title: '직접 입력하기',
            subtitle: '날짜, 금액 등을 자유롭게 기록해요',
            icon: Icons.edit_note_rounded,
            gradient: [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
            onTap: _addManualEntry,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _extractedItems.length,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            itemBuilder: (context, index) {
              return OCRTransactionCard(
                transaction: _extractedItems[index],
                onUpdate: (updated) {
                  setState(() => _extractedItems[index] = updated);
                },
                onDelete: () {
                  setState(() => _extractedItems.removeAt(index));
                },
                showDelete: _extractedItems.length > 1,
                onPickCategory: () => CategoryPickerSheet.show(
                  context: context, 
                  provider: Provider.of<TransactionProvider>(context, listen: false), 
                  onSelected: (cat) => setState(() => _extractedItems[index] = _extractedItems[index].copyWith(category: cat))
                ),
                onPickRelation: () => _showRelationPicker(index),
                headerBuilder: _buildSectionHeader,
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 130),
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextButton(
                    onPressed: () => setState(() => _extractedItems = []),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    child: Text('취소', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      final provider = Provider.of<TransactionProvider>(context, listen: false);
                      bool anySaved = false;
                      bool allSuccess = true;
                      
                      if (_extractedItems.isEmpty) return;

                      // 중복 여부와 관계없이 모든 리스트를 저장하도록 수정
                      for (var t in _extractedItems) {
                        final success = await provider.addTransaction(t);
                        if (!success) allSuccess = false;
                        else anySaved = true;
                      }
                      
                      if (context.mounted) {
                        if (anySaved) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(allSuccess ? '모든 내역이 저장되었습니다.' : '일부 내역 저장에 실패했습니다.'))
                          );
                          setState(() => _extractedItems = []);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('저장된 내역이 없습니다.'))
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      '저장하기',
                      style: TextStyle(fontWeight: FontWeight.bold)
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRelationPicker(int index) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final t = _extractedItems[index];

    RelationPickerSheet.show(
      context: context,
      provider: provider,
      selectedRelations: t.relations,
      onUpdate: (updated) {
        setState(() {
          _extractedItems[index] = t.copyWith(relations: updated);
        });
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
