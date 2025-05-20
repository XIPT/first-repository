import 'dart:typed_data';

class AnalysisResult {
  final String title;
  final String description;
  final DateTime createdAt;
  final Uint8List? previewImage;

  AnalysisResult({
    required this.title,
    required this.description,
    required this.createdAt,
    this.previewImage,
  });
}
