import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/transaction_provider.dart';
import '../../services/transaction_service.dart';
import 'manual_entry_screen.dart';

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
      if (result != null && result['parsed_data'] != null) {
        final receipt = Receipt.fromJson(result['parsed_data']);
        
        // 서버에서 받아온 데이터를 기반으로 Transaction 생성 (자동 입력)
        final parsed = Transaction(
          id: '',
          date: DateTime.tryParse(receipt.date) ?? DateTime.now(),
          amount: receipt.amount,
          description: receipt.description,
          type: TransactionType.expense,
          category: Category.fromName(receipt.categorySuggestion),
          relations: [],
          paymentMethod: PaymentMethod.checkCard,
        );
        
        setState(() {
          _isLoading = false;
          _extractedItems = [parsed];
        });
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          String errorMsg = '영수증을 분석할 수 없습니다.';
          if (result == null) {
            errorMsg = '서버 내부 오류(500) 또는 네트워크 연결을 확인해 주세요.';
          } else if (result['parsed_data'] == null) {
            errorMsg = '영수증 정보를 신뢰할 수 없어 데이터 추출에 실패했습니다.';
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
      appBar: AppBar(
        leading: _extractedItems.isEmpty ? null : IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => setState(() => _extractedItems = []),
        ),
        title: Text('영수증 인식', style: theme.textTheme.headlineMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text('영수증을 분석하고 있어요...', style: theme.textTheme.bodyMedium),
                ],
              ),
            )
          : _extractedItems.isEmpty
              ? _buildEmptyState()
              : _buildReviewList(),
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
            '영수증을 찍어 자동으로 입력하거나,\n직접 내용을 작성하실 수 있습니다.',
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
        // Header title removed for cleaner UI as requested
        Expanded(
          child: ListView.builder(
            itemCount: _extractedItems.length,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            itemBuilder: (context, index) {
              return _OCRTransactionCard(
                transaction: _extractedItems[index],
                onUpdate: (updated) {
                  setState(() => _extractedItems[index] = updated);
                },
                onPickCategory: () => _showCategoryPicker(index),
                onPickRelation: () => _showRelationPicker(index),
                headerBuilder: _buildSectionHeader,
              );
            },
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 130), // Increased for Animated Bottom Nav + Space
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
                      bool allSuccess = true;
                      
                      // Show loading indicator if needed, or disable button
                      for (var t in _extractedItems) {
                        final success = await provider.addTransaction(t);
                        if (!success) allSuccess = false;
                      }
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(allSuccess ? '모든 내역이 저장되었습니다.' : '일부 내역 저장에 실패했습니다.'))
                        );
                        setState(() => _extractedItems = []);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('전부 저장하기', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildSmallChip(String label, IconData icon, {bool isAction = false, VoidCallback? onTap, VoidCallback? onDelete}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isAction ? Border.all(color: theme.dividerColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : AppColors.primary)),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker(int index) {
    final t = _extractedItems[index];
    final theme = Theme.of(context);
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final categories = provider.allCategories;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('카테고리 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: categories.map((cat) => InkWell(
                onTap: () {
                  setState(() => _extractedItems[index] = t.copyWith(category: cat));
                  Navigator.pop(context);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon, color: cat.color),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: Text(
                        cat.name, 
                        style: const TextStyle(fontSize: 12), 
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _showRelationPicker(int index) {
    final provider = Provider.of<TransactionProvider>(context, listen: false);
    final t = _extractedItems[index];
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('2차 태그 (관계) 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    onPressed: () => _showAddTagDialog(context, provider, setModalState),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: provider.customRelations.map((rel) {
                  final isSelected = t.relations.any((r) => r.id == rel.id);
                  return FilterChip(
                    label: Text(rel.name),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        final updatedRelations = List<Relation>.from(t.relations);
                        if (selected) {
                          updatedRelations.add(rel);
                        } else {
                          updatedRelations.removeWhere((r) => r.id == rel.id);
                        }
                        _extractedItems[index] = t.copyWith(relations: updatedRelations);
                      });
                      setModalState(() {});
                    },
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, TransactionProvider provider, StateSetter setModalState) {
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

class _OCRTransactionCard extends StatefulWidget {
  final Transaction transaction;
  final Function(Transaction) onUpdate;
  final VoidCallback onPickCategory;
  final VoidCallback onPickRelation;
  final Widget Function(String) headerBuilder;

  const _OCRTransactionCard({
    required this.transaction,
    required this.onUpdate,
    required this.onPickCategory,
    required this.onPickRelation,
    required this.headerBuilder,
    super.key,
  });

  @override
  State<_OCRTransactionCard> createState() => _OCRTransactionCardState();
}

class _OCRTransactionCardState extends State<_OCRTransactionCard> {
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(text: widget.transaction.description);
    final currencyFormat = NumberFormat('#,###');
    _amountController = TextEditingController(
      text: widget.transaction.amount > 0 ? currencyFormat.format(widget.transaction.amount.toInt()) : '',
    );
  }

  @override
  void didUpdateWidget(covariant _OCRTransactionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transaction.description != widget.transaction.description && 
        _descriptionController.text != widget.transaction.description) {
      _descriptionController.text = widget.transaction.description;
    }
    
    final currencyFormat = NumberFormat('#,###');
    final formattedAmount = widget.transaction.amount > 0 ? currencyFormat.format(widget.transaction.amount.toInt()) : '';
    if (oldWidget.transaction.amount != widget.transaction.amount && 
        _amountController.text != formattedAmount) {
      _amountController.text = formattedAmount;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.dividerColor),
        boxShadow: theme.brightness == Brightness.light ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.headerBuilder('내용'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _descriptionController,
              onChanged: (val) => widget.onUpdate(t.copyWith(description: val)),
              decoration: const InputDecoration(
                hintText: '무엇에 쓰셨나요?',
                border: InputBorder.none,
                isDense: true,
              ),
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          widget.headerBuilder('금액'),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  onChanged: (val) {
                    final cleanVal = val.replaceAll(',', '');
                    final amount = double.tryParse(cleanVal) ?? 0;
                    widget.onUpdate(t.copyWith(amount: amount));
                  },
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '원',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSmallChip(context, t.category.name, t.category.icon, onTap: widget.onPickCategory),
              ...t.relations.map((rel) => _buildSmallChip(context, rel.name, Icons.person, onDelete: () {
                    final updatedRelations = List<Relation>.from(t.relations)..remove(rel);
                    widget.onUpdate(t.copyWith(relations: updatedRelations));
                  })),
              _buildSmallChip(context, '관계 추가', Icons.person_add_outlined, isAction: true, onTap: widget.onPickRelation),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallChip(BuildContext context, String label, IconData icon, {bool isAction = false, VoidCallback? onTap, VoidCallback? onDelete}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isAction ? Colors.transparent : AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: isAction ? Border.all(color: theme.dividerColor) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : AppColors.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isAction ? theme.colorScheme.onSurface.withValues(alpha: 0.7) : AppColors.primary)),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.close, size: 14, color: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    try {
      final double value = double.parse(newValue.text.replaceAll(',', ''));
      final formatter = NumberFormat('#,###');
      final String newText = formatter.format(value.toInt());

      return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
    } catch (e) {
      return newValue;
    }
  }
}
