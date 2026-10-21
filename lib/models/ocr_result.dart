class OcrExtractedData {
  final String merchant;
  final double amount;
  final DateTime date;
  final String rawText;
  final String categoryId;
  final double confidence;
  final List<String> extractedLines;

  OcrExtractedData({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.rawText,
    required this.categoryId,
    this.confidence = 1.0,
    this.extractedLines = const [],
  });

  OcrExtractedData copyWith({
    String? merchant,
    double? amount,
    DateTime? date,
    String? rawText,
    String? categoryId,
    double? confidence,
    List<String>? extractedLines,
  }) {
    return OcrExtractedData(
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      rawText: rawText ?? this.rawText,
      categoryId: categoryId ?? this.categoryId,
      confidence: confidence ?? this.confidence,
      extractedLines: extractedLines ?? this.extractedLines,
    );
  }
}
