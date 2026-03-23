import 'package:uuid/uuid.dart';

enum PDFItemType { text, images }

class PDFContentItem {
  final String id;
  PDFItemType type;
  String text;
  List<String> imagePaths;

  PDFContentItem({
    String? id,
    required this.type,
    this.text = '',
    this.imagePaths = const [],
  }) : id = id ?? const Uuid().v4();

  PDFContentItem copyWith({
    String? text,
    List<String>? imagePaths,
  }) {
    return PDFContentItem(
      id: id,
      type: type,
      text: text ?? this.text,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}
