import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme.dart';
import '../../data/pdf_models.dart';

class PDFEditorScreen extends StatefulWidget {
  const PDFEditorScreen({super.key});

  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  final List<PDFContentItem> _items = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addItem(PDFItemType type) {
    setState(() {
      _items.add(PDFContentItem(type: type, text: type == PDFItemType.text ? '' : ''));
    });
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });
  }

  Future<void> _pickImage(int itemIndex) async {
    final List<XFile>? images = await _picker.pickMultiImage();
    if (images != null && images.isNotEmpty) {
      setState(() {
        final currentPaths = List<String>.from(_items[itemIndex].imagePaths);
        for (var image in images) {
          if (currentPaths.length < 3) {
            currentPaths.add(image.path);
          }
        }
        _items[itemIndex].imagePaths = currentPaths;
      });
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    
    // 한글 폰트 로드
    final fontData = await PdfGoogleFonts.notoSansKRRegular();
    final boldFontData = await PdfGoogleFonts.notoSansKRBold();

    final titleText = _titleController.text.trim();
    final fileName = titleText.isEmpty 
        ? 'receipt_report_${DateTime.now().millisecondsSinceEpoch}.pdf'
        : '$titleText.pdf';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: fontData,
          bold: boldFontData,
        ),
        build: (pw.Context context) {
          List<pw.Widget> widgets = [];
          
          // 제목이 있으면 PDF 상단에 추가
          if (titleText.isNotEmpty) {
            widgets.add(
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 24),
                child: pw.Text(
                  titleText,
                  style: pw.TextStyle(
                    font: boldFontData,
                    fontSize: 24,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            );
            widgets.add(pw.Divider(thickness: 1, color: PdfColors.grey300));
            widgets.add(pw.SizedBox(height: 10));
          }
          
          for (var item in _items) {
            if (item.type == PDFItemType.text && item.text.isNotEmpty) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 10),
                  child: pw.Text(
                    item.text,
                    style: pw.TextStyle(
                      font: fontData,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            } else if (item.type == PDFItemType.images && item.imagePaths.isNotEmpty) {
              final List<pw.Widget> images = [];
              for (var path in item.imagePaths) {
                final file = File(path);
                if (file.existsSync()) {
                  images.add(
                    pw.Container(
                      width: 160,
                      height: 160,
                      child: pw.Image(
                        pw.MemoryImage(file.readAsBytesSync()),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  );
                }
              }
              
              if (images.isNotEmpty) {
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 10),
                    child: pw.Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: images,
                    ),
                  ),
                );
              }
            }
          }
          
          return widgets;
        },
      ),
    );

    // PDF 생성 및 시스템 공유 시트 호출
    final success = await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName,
      subject: titleText.isEmpty ? '영수증 PDF 보고서' : titleText,
      body: '',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF가 성공적으로 생성 및 전달되었습니다.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('💡 사용 가이드', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 16),
            const Text('📍 순서 변경 (Long Click)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text(
              '리스트의 항목을 길게 누르면 원하는 위치로 자유롭게 이동하여 순서를 바꿀 수 있습니다.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            const Text('📍 PDF 저장 방법', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
            const SizedBox(height: 8),
            const Text(
              '상단의 "저장" 버튼을 클릭하면 생성된 PDF 파일을 카카오톡, 메일 등으로 공유하거나 기기에 저장할 수 있는 시스템 팝업이 나타납니다.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('영수증 PDF 만들기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
            onPressed: _showInstructions,
          ),
          TextButton(
            onPressed: _items.isEmpty ? null : _generatePdf,
            child: const Text(
              '저장',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
        header: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24, left: 4, right: 4),
          child: TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '제목을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[300]),
              border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
            ),
          ),
        ),
        itemCount: _items.length,
        onReorder: _onReorder,
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildItemCell(item, index, theme);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemMenu,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddItemMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('추가할 항목 선택', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(Icons.text_fields_rounded, color: AppColors.primary),
              title: const Text('텍스트 (내용 입력)'),
              onTap: () {
                _addItem(PDFItemType.text);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: AppColors.primary),
              title: const Text('이미지 (영수증 사진)'),
              onTap: () {
                _addItem(PDFItemType.images);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCell(PDFContentItem item, int index, ThemeData theme) {
    return Container(
      key: ValueKey(item.id),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                item.type == PDFItemType.text ? Icons.text_fields_rounded : Icons.image_rounded,
                size: 20,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.grey),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.type == PDFItemType.text)
            TextField(
              maxLines: null,
              decoration: const InputDecoration(
                hintText: '내용을 입력하세요...',
                border: InputBorder.none,
              ),
              onChanged: (val) => item.text = val,
            )
          else
            _buildImageHorizontalList(item, index),
        ],
      ),
    );
  }

  Widget _buildImageHorizontalList(PDFContentItem item, int itemIndex) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: item.imagePaths.length + (item.imagePaths.length < 3 ? 1 : 0),
        itemBuilder: (context, imgIndex) {
          if (imgIndex == item.imagePaths.length) {
            return GestureDetector(
              onTap: () => _pickImage(itemIndex),
              child: Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                ),
                child: const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
              ),
            );
          }

          final path = item.imagePaths[imgIndex];
          return Stack(
            children: [
              Container(
                width: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: FileImage(File(path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _items[itemIndex].imagePaths.removeAt(imgIndex);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
