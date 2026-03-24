import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/transaction_service.dart';

import 'ocr_view.dart';

class OCRLoadingScreen extends StatefulWidget {
  final String? imagePath;
  const OCRLoadingScreen({super.key, this.imagePath});

  @override
  State<OCRLoadingScreen> createState() => _OCRLoadingScreenState();
}

class _OCRLoadingScreenState extends State<OCRLoadingScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    _checkLimitAndProceed();
  }

  Future<void> _checkLimitAndProceed() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // 분석 시작 전 최신 사용자 정보 가져오기 (횟수 동기화)
    await authProvider.refreshUser();
    
    final user = authProvider.user;
    if (user != null) {
      final int limit = user['ocr_limit'] ?? 10;
      final int count = user['ocr_count'] ?? 0;

      if (count >= limit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('일일 영수증 분석 한도(${limit}회)를 모두 사용하셨습니다.'))
          );
          Navigator.pop(context);
        }
        return;
      }
    }

    if (widget.imagePath != null) {
      _startAnalysis(widget.imagePath!);
    } else {
      _pickImage();
    }
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isPicking = false);
      _startAnalysis(image.path);
    } else {
      // 선택을 취소한 경우 다시 홈으로
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _startAnalysis(String path) async {
    // 최소 1초는 로딩 화면을 보여주어 사용자 경험을 안정화합니다.
    final startTime = DateTime.now();
    
    final service = TransactionService();
    try {
      final result = await service.uploadReceipt(path);
      // 분석 성공 후 실제 카운트 동기화를 위해 유저 정보 새로고침
      if (result != null && mounted) {
        Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      if (duration.inMilliseconds < 1000) {
        await Future.delayed(Duration(milliseconds: 1000 - duration.inMilliseconds));
      }

      if (result != null && result['parsed_items'] != null) {
        final List<dynamic> itemsData = result['parsed_items'];
        final List<Transaction> parsedTransactions = itemsData.map((item) {
          final receipt = Receipt.fromJson(item);
          DateTime parsedDate;
          try {
            String normalizedDate = receipt.date.replaceAll('.', '-');
            parsedDate = DateTime.parse(normalizedDate);
          } catch (e) {
            print('날짜 파싱 실패: ${receipt.date}, 현재 시간으로 대체합니다.');
            parsedDate = DateTime.now();
          }
          
          return Transaction(
            id: '',
            date: parsedDate, // 파싱된 날짜를 정확히 전달
            amount: receipt.amount,
            description: receipt.description,
            type: TransactionType.expense,
            category: Category.fromName(receipt.categorySuggestion),
            relations: [],
            paymentMethod: receipt.paymentMethod,
            isDuplicate: receipt.isDuplicate,
          );
        }).toList();

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OCRView(extractedItems: parsedTransactions),
            ),
          );
        }
      } else {
        _handleError('분석할 수 없는 영수증입니다.');
      }
    } catch (e) {
      _handleError('분석 중 오류가 발생했습니다: $e');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // 확실한 흰색 배경
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            const SizedBox(height: 32),
            Text(
              '영수증을 분석하고 있어요...',
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
      ),
    );
  }
}
