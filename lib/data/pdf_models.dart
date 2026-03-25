import 'package:uuid/uuid.dart';

enum PDFItemType { text, images }

enum PDFImageSize { small, medium, large }

class PDFContentItem {
  final String id;
  PDFItemType type;
  PDFImageSize? imageSize;
  String text;
  List<String> imagePaths;

  PDFContentItem({
    String? id,
    required this.type,
    this.text = '',
    this.imagePaths = const [],
    this.imageSize = PDFImageSize.large, // 기본값을 크게(240)로 변경
  }) : id = id ?? const Uuid().v4();

  PDFContentItem copyWith({
    String? text,
    List<String>? imagePaths,
    PDFImageSize? imageSize,
  }) {
    return PDFContentItem(
      id: id,
      type: type,
      text: text ?? this.text,
      imagePaths: imagePaths ?? this.imagePaths,
      imageSize: imageSize ?? this.imageSize,
    );
  }
}
