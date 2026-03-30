import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/app_strings.dart';
import '../../core/theme.dart';
import '../../core/app_config.dart';
import '../../core/app_log.dart';
import '../../core/app_icons.dart';
import '../../data/pdf_models.dart';
import '../widgets/app_dialog.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/loading_overlay.dart';

class PDFEditorScreen extends StatefulWidget {
  const PDFEditorScreen({super.key});

  @override
  State<PDFEditorScreen> createState() => _PDFEditorScreenState();
}

class _PDFEditorScreenState extends State<PDFEditorScreen> {
  final List<PDFContentItem> _items = [];
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  bool _showTitleInPdf = true; // PDF 내부에 제목 노출 여부

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

  Widget _buildItemSizeSelector(PDFContentItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildSizeChip(item, PDFImageSize.small, AppStrings.pdfImageSizeSmall),
            const SizedBox(width: 8),
            _buildSizeChip(item, PDFImageSize.medium, AppStrings.pdfImageSizeMedium),
            const SizedBox(width: 8),
            _buildSizeChip(item, PDFImageSize.large, AppStrings.pdfImageSizeLarge),
          ],
        ),
      ],
    );
  }

  Widget _buildSizeChip(PDFContentItem item, PDFImageSize size, String label) {
    final isSelected = item.imageSize == size;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => item.imageSize = size);
      },
      selectedColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.2)),
      ),
      showCheckmark: false,
    );
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


  Future<pw.Document?> _createPdfDocument() async {
    if (_items.isEmpty) {
      AppSnackBar.show(context, AppStrings.pdfEmptyError);
      return null;
    }

    final pdf = pw.Document();
    
    // 한글 폰트 로드
    final fontData = await PdfGoogleFonts.notoSansKRRegular();
    final boldFontData = await PdfGoogleFonts.notoSansKRBold();

    final titleText = _titleController.text.trim();

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
          
          // 제목이 있고 노출 설정이 켜져 있으면 PDF 상단에 추가
          if (_showTitleInPdf && titleText.isNotEmpty) {
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
              widgets.add(pw.SizedBox(height: 10)); // 텍스트 아이템 후 줄바꿈 간격 추가
            } else if (item.type == PDFItemType.images && item.imagePaths.isNotEmpty) {
              final List<pw.Widget> images = [];
              double imageWidth;
              switch (item.imageSize ?? PDFImageSize.large) {
                case PDFImageSize.small: imageWidth = 160; break;
                case PDFImageSize.medium: imageWidth = 200; break;
                case PDFImageSize.large: imageWidth = 260; break;
              }

              for (var path in item.imagePaths) {
                final file = File(path);
                if (file.existsSync()) {
                  images.add(
                    pw.Container(
                      width: imageWidth,
                      padding: const pw.EdgeInsets.only(right: 10, bottom: 10),
                      child: pw.Image(
                        pw.MemoryImage(file.readAsBytesSync()),
                        dpi: 400,
                      ),
                    ),
                  );
                }
              }
              
              if (images.isNotEmpty) {
                // 한 줄에 몇 개씩 배치할지 계산
                int perRow = 2; // 기본값 (Medium)
                final size = item.imageSize ?? PDFImageSize.large;
                if (size == PDFImageSize.small) {
                    perRow = 3;
                } else if (size == PDFImageSize.large) {
                    perRow = 1;
                }

                for (var i = 0; i < images.length; i += perRow) {
                  final chunk = images.sublist(i, i + perRow > images.length ? images.length : i + perRow);
                  widgets.add(
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.start,
                        children: chunk,
                      ),
                    ),
                  );
                }
                widgets.add(pw.SizedBox(height: 10)); // 아이템 간 간격 추가
              }
            }
          }
          
          return widgets;
        },
      ),
    );

    return pdf;
  }

  Future<void> _previewPdf() async {
    try {
      AppLoadingOverlay.show(context);
      
      final pdf = await _createPdfDocument();
      if (pdf == null) {
        AppLoadingOverlay.hide();
        return;
      }

      final titleText = _titleController.text.trim();
      final fileName = titleText.isEmpty 
          ? '${AppStrings.pdfDefaultFileNamePrefix}${DateTime.now().millisecondsSinceEpoch}.pdf'
          : '$titleText.pdf';

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: fileName,
      );
    } catch (e, stack) {
      AppLog.logD('PDFEditorScreen', '', 'PDF Preview Error: $e\nStack: $stack');
      if (mounted) {
        AppSnackBar.show(context, '${AppStrings.pdfErrorMessage}: $e');
      }
    } finally {
      AppLoadingOverlay.hide();
    }
  }

  Future<void> _savePdf() async {
    try {
      AppLoadingOverlay.show(context);

      final pdf = await _createPdfDocument();
      if (pdf == null) {
        AppLoadingOverlay.hide();
        return;
      }

      final titleText = _titleController.text.trim();
      final fileName = titleText.isEmpty 
          ? '${AppStrings.pdfDefaultFileNamePrefix}${DateTime.now().millisecondsSinceEpoch}.pdf'
          : '$titleText.pdf';

      // PDF 생성 및 시스템 공유 시트 호출
      final success = await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: fileName,
        subject: titleText.isEmpty ? AppStrings.pdfDefaultSubject : titleText,
        body: '',
      );

      if (success && mounted) {
        AppSnackBar.show(context, AppStrings.pdfSuccessMessage);
      }
    } catch (e, stack) {
      AppLog.logD('PDFEditorScreen', '', 'PDF Save Error: $e\nStack: $stack');
      if (mounted) {
        AppSnackBar.show(context, '${AppStrings.pdfErrorMessage}: $e');
      }
    } finally {
      AppLoadingOverlay.hide();
    }
  }

  void _showSaveOptions() {
    FocusManager.instance.primaryFocus?.unfocus(); // 키보드 숨기기
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(AppStrings.pdfSaveOptionTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(AppIcons.pdfPreview, color: AppColors.primary),
              title: const Text(AppStrings.pdfPreviewLabel),
              onTap: () {
                Navigator.pop(context);
                _previewPdf();
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.pdfSave, color: AppColors.primary),
              title: const Text(AppStrings.pdfSaveLabel),
              onTap: () {
                Navigator.pop(context);
                _savePdf();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showInstructions() {
    AppDialog.show(
      context: context,
      title: AppStrings.pdfGuideTitle,
      icon: AppIcons.pdfGuide,
      contentWidget: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildGuideItem(AppStrings.pdfGuideReorderTitle, AppStrings.pdfGuideReorderDesc),
          const SizedBox(height: 16),
          _buildGuideItem(AppStrings.pdfGuideSaveTitle, AppStrings.pdfGuideSaveDesc),
        ],
      ),
      confirmText: AppStrings.ok,
      onConfirm: () {},
    );
  }

  Widget _buildGuideItem(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.4)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.pdfCreatorTitle, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(AppIcons.info, color: Colors.grey),
            onPressed: _showInstructions,
          ),
          IconButton(
            icon: const Icon(AppIcons.pdfSave, color: AppColors.primary),
            onPressed: _showSaveOptions,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          header: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 24, left: 4, right: 4),
                child: Column(
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                      decoration: InputDecoration(
                        hintText: AppStrings.pdfTitleHint,
                        hintStyle: TextStyle(color: Colors.grey[300]),
                        border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          AppStrings.pdfShowTitleToggleLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: _showTitleInPdf ? AppColors.primary : Colors.grey,
                            fontWeight: _showTitleInPdf ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 24,
                          child: Transform.scale(
                            scale: 0.7,
                            child: CupertinoSwitch(
                              value: _showTitleInPdf,
                              activeColor: AppColors.primary,
                              onChanged: (val) => setState(() => _showTitleInPdf = val),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
          itemCount: _items.length,
          onReorder: _onReorder,
          itemBuilder: (context, index) {
            final item = _items[index];
            return _buildItemCell(item, index, theme);
          },
        ),
      ),
      floatingActionButton: SizedBox(
        height: 64,
        width: 64,
        child: FloatingActionButton(
          onPressed: _showAddItemMenu,
          backgroundColor: AppColors.primary,
          elevation: 4,
          shape: const CircleBorder(),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Icon(AppIcons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  void _showAddItemMenu() {
    FocusManager.instance.primaryFocus?.unfocus(); // 더 강력한 전역 언포커스 적용
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(AppStrings.pdfAddItemTitle, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ListTile(
              leading: const Icon(AppIcons.textFields, color: AppColors.primary),
              title: const Text(AppStrings.pdfTypeTextLabel),
              onTap: () {
                _addItem(PDFItemType.text);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(AppIcons.image, color: AppColors.primary),
              title: const Text(AppStrings.pdfTypeImageLabel),
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
            color: Colors.black.withOpacity(0.05),
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
                item.type == PDFItemType.text ? AppIcons.textFields : AppIcons.image,
                size: 20,
                color: theme.colorScheme.onSurface.withOpacity(0.4),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(AppIcons.delete, size: 20, color: Colors.grey),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (item.type == PDFItemType.text)
            TextField(
              maxLines: null,
              decoration: const InputDecoration(
                hintText: AppStrings.pdfContentHint,
                border: InputBorder.none,
              ),
              onChanged: (val) => item.text = val,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageHorizontalList(item, index),
                const SizedBox(height: 16),
                _buildItemSizeSelector(item),
              ],
            ),
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
                child: const Icon(AppIcons.addPhoto, color: Colors.grey),
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
                    child: const Icon(AppIcons.close, size: 16, color: Colors.white),
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
